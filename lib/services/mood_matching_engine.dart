import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/tagged_verse.dart';
import '../theme/mood_stage_theme.dart';
import 'bible_api_service.dart';

/// Encapsulates a resolved verse and devotional reflection ready for presentation.
class MatchedVerse {
  final TaggedVerse verse;
  final String text;
  final String reflection;
  final String langCode;
  final MoodStage stage;
  final bool wasReset;

  const MatchedVerse({
    required this.verse,
    required this.text,
    required this.reflection,
    required this.langCode,
    required this.stage,
    this.wasReset = false,
  });

  String get verseId => verse.id;
  String get reference => verse.reference;
  String get category => verse.category ?? 'Daily Pause';
  String get subTag => verse.subTag ?? 'Reflection';
}

/// Matches user mood stages to relevant Scripture and humble reflections.
///
/// 1. Queries Supabase (`verses` and `verse_translations` tables) when available.
/// 2. Falls back to bundled local JSON (`assets/seed_verses.json`) or in-memory seed verses.
/// 3. Filters by selected [MoodStage] and tracks `seen_verse_ids` in [SharedPreferences]
///    to prevent repeats within the same week.
/// 4. Automatically resets seen verses when all verses in a mood category have been read.
class MoodMatchingEngine {
  static const String seenVerseIdsKey = 'seen_verse_ids';
  static const String seenTimestampKey = 'seen_verses_timestamp';
  static const int oneWeekMillis = 7 * 24 * 60 * 60 * 1000;

  final SharedPreferences? _prefs;
  final SupabaseClient? _supabaseClient;
  final BibleApiService _bibleApiService;
  final List<TaggedVerse>? _customVerses;
  final AssetBundle? _assetBundle;

  MoodMatchingEngine({
    SharedPreferences? prefs,
    SupabaseClient? supabaseClient,
    BibleApiService? bibleApiService,
    List<TaggedVerse>? seedVerses,
    AssetBundle? assetBundle,
  })  : _prefs = prefs,
        _supabaseClient = supabaseClient,
        _bibleApiService = bibleApiService ?? BibleApiService(prefs: prefs),
        _customVerses = seedVerses,
        _assetBundle = assetBundle;

  Future<SharedPreferences> get _preferences async =>
      _prefs ?? await SharedPreferences.getInstance();

  /// Loads all tagged verses: tries Supabase first, then local JSON / in-memory fallback.
  Future<List<TaggedVerse>> loadVerses() async {
    final custom = _customVerses;
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }

    // 1. Attempt Supabase query
    try {
      final remote = await _fetchFromSupabase();
      if (remote.isNotEmpty) {
        return remote;
      }
    } catch (_) {
      // Supabase uninitialized or offline; proceed to fallback
    }

    // 2. Attempt bundled local JSON fallback
    try {
      final local = await _loadBundledJsonFallback();
      if (local.isNotEmpty) {
        return local;
      }
    } catch (_) {
      // Local asset missing or unreadable; proceed to hardcoded seed
    }

    // 3. Guaranteed in-memory fallback
    return defaultSeedVerses;
  }

  /// Queries the `verses` table with related `verse_translations` from Supabase.
  Future<List<TaggedVerse>> _fetchFromSupabase() async {
    SupabaseClient? client = _supabaseClient;
    if (client == null) {
      try {
        client = Supabase.instance.client;
      } catch (_) {
        return <TaggedVerse>[];
      }
    }

    final response = await client
        .from('verses')
        .select('*, verse_translations(*)');

    final list = response as List<dynamic>;
    final verses = <TaggedVerse>[];

    for (final raw in list) {
      if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        final translations = map['verse_translations'] as List<dynamic>?;
        final texts = <String, String>{};
        final reflections = <String, String>{};

        if (translations != null) {
          for (final t in translations) {
            if (t is Map) {
              final lang = t['lang_code']?.toString() ?? t['lang']?.toString();
              if (lang != null) {
                if (t['text'] != null) texts[lang] = t['text'].toString();
                if (t['reflection'] != null) {
                  reflections[lang] = t['reflection'].toString();
                }
              }
            }
          }
        }

        verses.add(
          TaggedVerse.fromJson(
            map,
            extraTexts: texts,
            extraReflections: reflections,
          ),
        );
      }
    }

    return verses;
  }

  /// Loads bundled seed verses from `assets/seed_verses.json`.
  Future<List<TaggedVerse>> _loadBundledJsonFallback() async {
    final bundle = _assetBundle ?? rootBundle;
    final jsonStr = await bundle.loadString('assets/seed_verses.json');
    if (jsonStr.trim().isEmpty) return <TaggedVerse>[];

    final decoded = jsonDecode(jsonStr);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((m) => TaggedVerse.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    return <TaggedVerse>[];
  }

  /// Checks and resets the weekly seen history if 7 days have elapsed.
  Future<Set<String>> getSeenVerseIds() async {
    final prefs = await _preferences;
    _checkWeeklyReset(prefs);
    return (prefs.getStringList(seenVerseIdsKey) ?? <String>[]).toSet();
  }

  void _checkWeeklyReset(SharedPreferences prefs) {
    final lastTime = prefs.getInt(seenTimestampKey);
    final now = DateTime.now().millisecondsSinceEpoch;

    if (lastTime == null) {
      prefs.setInt(seenTimestampKey, now);
    } else if (now - lastTime > oneWeekMillis) {
      prefs.remove(seenVerseIdsKey);
      prefs.setInt(seenTimestampKey, now);
    }
  }

  /// Retrieves a fresh verse and reflection for the chosen [MoodStage] and language.
  ///
  /// - Skips already seen verses in this mood.
  /// - Resets seen verses for this mood if all have been read.
  /// - Enriches verse text from the static Bible API when not cached.
  Future<MatchedVerse> getVerseForMood({
    required MoodStage stage,
    String langCode = 'eng',
  }) async {
    final allVerses = await loadVerses();
    final stageVerses = allVerses.where((v) => v.primaryStage == stage).toList();

    if (stageVerses.isEmpty) {
      throw StateError('No verses configured for stage: ${stage.name}');
    }

    final prefs = await _preferences;
    _checkWeeklyReset(prefs);

    final seenList = prefs.getStringList(seenVerseIdsKey) ?? <String>[];
    final seenIds = seenList.toSet();

    // 1. Filter out seen verses
    var unseen = stageVerses.where((v) => !seenIds.contains(v.id)).toList();
    var wasReset = false;

    // 2. If all verses in this mood have been seen, reset them for this mood
    if (unseen.isEmpty) {
      final stageIds = stageVerses.map((v) => v.id).toSet();
      seenIds.removeAll(stageIds);
      await prefs.setStringList(seenVerseIdsKey, seenIds.toList());
      unseen = List<TaggedVerse>.from(stageVerses);
      wasReset = true;
    }

    // 3. Select next fresh verse
    final chosenVerse = unseen.first;

    // 4. Mark as seen
    seenIds.add(chosenVerse.id);
    await prefs.setStringList(seenVerseIdsKey, seenIds.toList());

    // 5. Resolve text and reflection in selected language
    String? text = chosenVerse.textFor(langCode);
    if (text == null || text.trim().isEmpty) {
      text = await _bibleApiService.getVerseText(
        universalId: chosenVerse.id,
        langOrTranslation: langCode,
      );
    }
    text ??= chosenVerse.textFor('eng') ?? chosenVerse.reference;

    final reflection = chosenVerse.reflectionFor(langCode);

    return MatchedVerse(
      verse: chosenVerse,
      text: text,
      reflection: reflection,
      langCode: langCode,
      stage: stage,
      wasReset: wasReset,
    );
  }

  /// Explicitly clears seen verse tracking.
  Future<void> clearSeenVerses() async {
    final prefs = await _preferences;
    await prefs.remove(seenVerseIdsKey);
    await prefs.remove(seenTimestampKey);
  }

  /// Default in-memory seed verses providing rich multilingual reflections
  /// across all 4 mood stages (`gloomy`, `growing`, `bright`, `humble`).
  static const List<TaggedVerse> defaultSeedVerses = [
    // --- GLOOMY STAGE ---
    TaggedVerse(
      id: 'PSA.34.18',
      book: 'PSA',
      chapter: 34,
      verse: 18,
      primaryStage: MoodStage.gloomy,
      moodTags: ['gloomy', 'brokenhearted', 'comfort', 'grief'],
      category: 'Comfort in Heavy Seasons',
      subTag: 'Morning Pause',
      textsByLang: {
        'eng': 'The Lord is close to the brokenhearted and saves those who are crushed in spirit.',
        'lus': 'LALPA chu thinlung lungchhiatte hnaihah a awm a, rilrua inchhirte chu a chhandam ṭhîn.',
        'hin': 'यहोवा टूटे मन वालों के समीप रहता है, और पिसे हुओं का उद्धार करता है।',
        'spa': 'Cercano está Jehová a los quebrantados de corazón; y salva a los contritos de espíritu.',
      },
      reflectionsByLang: {
        'eng': 'Feeling heartbroken does not mean your faith is weak. God does not wait for you to put on a brave face—He draws closest when your spirit feels heavy.',
        'lus': 'I rilru a hah avangin i rinna a chak lo tihna a ni lo. Pathian chuan hlim hmel i put phawt a nghak lo—i rilru a pik lai tak hian I kiangah a awm reng a ni.',
        'hin': 'मन भारी होने का मतलब यह नहीं कि आपका विश्वास कमज़ोर है। ईश्वर आपके मुस्कुराने का इंतज़ार नहीं करते—जब दिल दुखी होता है, वह आपके सबसे करीब होते हैं।',
        'spa': 'Sentirte afligido no significa que tu fe sea débil. Dios no espera que finjas fortaleza; Él se acerca más cuando tu espíritu se siente abrumado.',
      },
    ),
    TaggedVerse(
      id: 'PSA.42.11',
      book: 'PSA',
      chapter: 42,
      verse: 11,
      primaryStage: MoodStage.gloomy,
      moodTags: ['gloomy', 'downcast', 'hope', 'soul'],
      category: 'When Soul is Downcast',
      subTag: 'Quiet Rest',
      textsByLang: {
        'eng': 'Why, my soul, are you downcast? Why so disturbed within me? Put your hope in God, for I will yet praise him, my Savior and my God.',
        'lus': 'Ka nunna engah nge i kun reng? Engah nge ka chhungah hian i buai? Pathian chu beisei rawh.',
        'hin': 'हे मेरे प्राण, तू क्यों गिरा जाता है? और अंदर ही अंदर क्यों व्याकुल है? परमेश्वर पर भरोसा रख।',
        'spa': '¿Por qué te abates, oh alma mía, y por qué te turbas dentro de mí? Espera en Dios; porque aún he de alabarle.',
      },
      reflectionsByLang: {
        'eng': 'It is honest and holy to ask your soul why it aches. Hope does not deny sorrow; it simply gives sorrow a hand to hold in the dark.',
        'lus': 'I nunna hnenah a chhan zawh hi thil sual a ni lo. Beiseina chuan lungngaihna a hlamchhiah lo, thim zingah a vuan tlat zawk a ni.',
        'hin': 'अपने दर्द को महसूस करना कमजोरी नहीं है। उम्मीद अंधेरे में भी ईश्वर के हाथ को थामे रखने का नाम है।',
        'spa': 'Es honesto y sagrado reconocer la tristeza de tu alma. La esperanza no niega el dolor; le da una mano segura en la oscuridad.',
      },
    ),

    // --- GROWING STAGE ---
    TaggedVerse(
      id: '2CO.12.9',
      book: '2CO',
      chapter: 12,
      verse: 9,
      primaryStage: MoodStage.growing,
      moodTags: ['growing', 'grace', 'weakness', 'patience'],
      category: 'Strength in Weakness',
      subTag: 'Quiet Growth',
      textsByLang: {
        'eng': 'My grace is sufficient for you, for my power is made perfect in weakness.',
        'lus': 'Ka khawngaihna i tan a tawk e; ka thiltihtheihna hi chak lohnaah asin tihfamkimin a awm ni.',
        'hin': 'मेरा अनुग्रह तेरे लिये बहुत है; क्योंकि मेरी सामर्थ्य निर्बलता में सिद्ध होती है।',
        'spa': 'Bástate mi gracia; porque mi poder se perfecciona en la debilidad.',
      },
      reflectionsByLang: {
        'eng': 'Growth often feels quiet and tender like a seed beneath dark soil. You do not have to carry tomorrow’s burden today; grace is measured for this very moment.',
        'lus': 'Thil ṭhang lai hi lei hnuaia chi nung ang maiin a reh ṭhîn. Naktuk buaina chu vawiinah phur vek kher suh; tun hun atan hian khawngaihna a tawk em em a ni.',
        'hin': 'विकास अक्सर मिट्टी के नीचे बीज की तरह शांत और धीमा होता है। आज ही कल का बोझ उठाने की ज़रूरत नहीं; इस पल के लिए अनुग्रह ही काफी है।',
        'spa': 'El crecimiento suele ser silencioso y tierno como una semilla bajo tierra. No tienes que cargar hoy con el peso de mañana; la gracia basta para este momento.',
      },
    ),
    TaggedVerse(
      id: 'ISA.40.29',
      book: 'ISA',
      chapter: 40,
      verse: 29,
      primaryStage: MoodStage.growing,
      moodTags: ['growing', 'strength', 'weary', 'perseverance'],
      category: 'Renewing Quiet Strength',
      subTag: 'Gentle Unfolding',
      textsByLang: {
        'eng': 'He gives strength to the weary and increases the power of the weak.',
        'lus': 'Chauhte chu thahrui a pe ṭhîn a, chakna reng reng nei lote chu chakna a vawrh punsak ṭhîn.',
        'hin': 'वह थके हुए को बल देता है और शक्तिहीन को बहुत सामर्थ्य देता है।',
        'spa': 'Él da esfuerzo al cansado, y multiplica las fuerzas al que no tiene ningunas.',
      },
      reflectionsByLang: {
        'eng': 'You do not have to bloom overnight. Rest is not lost time; it is the silent season where roots grow deep enough to sustain tomorrow.',
        'lus': 'Zankhat thilah i ṭhan nghal thut kher a ngai lo. Chawlh hahdam hi hun khawhralna a ni lo, zung a ngheh zualna hun a ni zawk.',
        'hin': 'रातों-रात खिलना ज़रूरी नहीं है। आराम करना समय की बर्बादी नहीं, बल्कि जड़ों को गहरा और मजबूत करने का समय है।',
        'spa': 'No tienes que florecer de la noche a la mañana. El descanso prepara raíces profundas para sostener el mañana.',
      },
    ),

    // --- BRIGHT STAGE ---
    TaggedVerse(
      id: 'NUM.6.24',
      book: 'NUM',
      chapter: 6,
      verse: 24,
      primaryStage: MoodStage.bright,
      moodTags: ['bright', 'blessing', 'peace', 'gratitude'],
      category: 'Joy & Abundance',
      subTag: 'Sunlit Gratitude',
      textsByLang: {
        'eng': 'The Lord bless you and keep you; the Lord make his face shine on you and be gracious to you; the Lord turn his face toward you and give you peace.',
        'lus': 'LALPAN malsawm che sela, vawng ṭha che rawh se; LALPAN a hmel entir che sela, khawngaih che rawh se; LALPAN a hmel chhun tir che sela, thlamuanna pe che rawh se.',
        'hin': 'यहोवा तुझे आशीष दे और तेरी रक्षा करे: यहोवा तुझ पर अपने मुख का प्रकाश चमकाए, और तुझ पर अनुग्रह करे: यहोवा अपना मुख तेरी ओर करे, और तुझे शान्ति दे।',
        'spa': 'Jehová te bendiga, y te guarde; Jehová haga resplandecer su rostro sobre ti, y tenga de ti misericordia; Jehová alce sobre ti su rostro, y ponga en ti paz.',
      },
      reflectionsByLang: {
        'eng': 'When gratitude fills your heart, let it spill gently into the world around you. Hold this warmth with open hands, thanking the One who gives every good gift.',
        'lus': 'I thinlung lawmnain a khah lai hian midangte hnenah nem takin puang chhuak rawh. Kut pharh meuhin he duhsakna hi pawm la, thilṭha zawng zawng petu chu fak rawh.',
        'hin': 'जब दिल कृतज्ञता से भर जाए, तो इस सुकून को अपने आस-पास भी बाँटें। हर अच्छी आशीष देने वाले प्रभु का धन्यवाद करें।',
        'spa': 'Cuando la gratitud llena tu corazón, deja que ilumine tu entorno. Recibe esta bendición con manos abiertas, agradeciendo al dador de toda buena dádiva.',
      },
    ),
    TaggedVerse(
      id: 'PHP.4.4',
      book: 'PHP',
      chapter: 4,
      verse: 4,
      primaryStage: MoodStage.bright,
      moodTags: ['bright', 'rejoice', 'gladness', 'celebration'],
      category: 'Rejoicing in Simplicity',
      subTag: 'Warm Radiance',
      textsByLang: {
        'eng': 'Rejoice in the Lord always. I will say it again: Rejoice!',
        'lus': 'Lalpaah chuan lawm fo rawh u; ka ti nawn leh ang, Lawm rawh u.',
        'hin': 'प्रभु में सदा आनन्दित रहो; मैं फिर कहता हूँ, आनन्दित रहो।',
        'spa': '¡Regocijaos en el Señor siempre! Otra vez digo: ¡Regocijaos!',
      },
      reflectionsByLang: {
        'eng': 'Joy in the Lord is not contingent on circumstances; it is an anchored delight in knowing you are seen, held, and endlessly loved.',
        'lus': 'Lalpaa lawmna chu eng dinhmunah pawh a awm thei; Pathian hmangaihna leh enkawlna hriat chianna atanga lo chhuak a ni.',
        'hin': 'सच्चा आनंद परिस्थितियों पर निर्भर नहीं करता; यह इस बात का सुकून है कि ईश्वर आपसे असीम प्रेम करते हैं।',
        'spa': 'El gozo en el Señor no depende de las circunstancias; es el deleite seguro de saberte sostenido y profundamente amado.',
      },
    ),

    // --- HUMBLE STAGE ---
    TaggedVerse(
      id: 'MIC.6.8',
      book: 'MIC',
      chapter: 6,
      verse: 8,
      primaryStage: MoodStage.humble,
      moodTags: ['humble', 'justice', 'mercy', 'walk'],
      category: 'Simple Devotion',
      subTag: 'Quiet Walk',
      textsByLang: {
        'eng': 'He has shown you, O mortal, what is good. And what does the Lord require of you? To act justly and to love mercy and to walk humbly with your God.',
        'lus': 'Aw mihring, ṭha chu a entir tawh che a ni; LALPA phût chu dik taka tih leh khawngaihna ngainat leh, i Pathian nena thuhnuairawlh taka len dun chauh a ni lo vem ni?',
        'hin': 'हे मनुष्य, वह तुझ पर प्रगट कर चुका है कि भला क्या है; और यहोवा तुझ से इसे छोड़ और क्या चाहता है, कि तू न्याय से काम करे, और कृपा से प्रीति रखे, और अपने परमेश्वर के साथ नम्रता से चले?',
        'spa': 'Oh hombre, él te ha declarado lo que es bueno, y qué pide Jehová de ti: solamente hacer justicia, y amar misericordia, y humillarte ante tu Dios.',
      },
      reflectionsByLang: {
        'eng': 'Faith is rarely about grand spectacles; it is walking quietly step by step, showing kindness without noise, and resting in the steady guidance of your Maker.',
        'lus': 'Rinna chu thil ropui leh thawm na tak a ni ber lo; thawm nei lova ngilneihna lantir leh, Siamtu hruaina rinchhana thuhnuairawlh taka kal zel hi a ni zawk.',
        'hin': 'विश्वास कोई बड़ा दिखावा नहीं; यह शांति से एक-एक कदम चलना है, बिना शोर के दया दिखाना और अपने ईश्वर के साथ नम्रता से जीना है।',
        'spa': 'La fe rara vez se trata de grandes espectáculos; se trata de caminar paso a paso, practicar la misericordia sin ruido y descansar con humildad en Dios.',
      },
    ),
    TaggedVerse(
      id: 'PRO.3.5',
      book: 'PRO',
      chapter: 3,
      verse: 5,
      primaryStage: MoodStage.humble,
      moodTags: ['humble', 'trust', 'heart', 'guidance'],
      category: 'Leaning Inwardly on Grace',
      subTag: 'Surrender',
      textsByLang: {
        'eng': 'Trust in the Lord with all your heart and lean not on your own understanding.',
        'lus': 'I thinlung zawng zawngin LALPA ring la, nangma hriatnaah innghat suh.',
        'hin': 'तू अपनी समझ का सहारा न लेना, वरन सम्पूर्ण मन से यहोवा पर भरोसा रखना।',
        'spa': 'Fíate de Jehová de todo tu corazón, y no te apoyes en tu propia prudencia.',
      },
      reflectionsByLang: {
        'eng': 'Humility is the sweet relief of admitting you do not have to figure out everything today. Lay down the steering wheel into hands far wiser than your own.',
        'lus': 'Inngaihtlawmna chu engkim i hriat thiam vek kher a ngai lo tih pawm thiamna hi a ni. Nangmah aia fing zawk kutah engkim hlan rawh.',
        'hin': 'विनम्रता इस बात को स्वीकार करने का सुकून है कि आज आपको सब कुछ जानने की ज़रूरत नहीं है। नियंत्रण ईश्वर के हाथों में सौंप दें।',
        'spa': 'La humildad es el dulce alivio de aceptar que hoy no tienes que resolverlo todo. Deja el control en manos infinitamente más sabias.',
      },
    ),
  ];
}
