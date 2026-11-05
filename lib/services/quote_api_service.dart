import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/mood_stage_theme.dart';

/// Represents an inspirational quote classified into a contemplative [MoodStage].
class InspirationalQuote {
  final String id;
  final String quote;
  final String author;
  final MoodStage stage;
  final String category;
  final String subTag;
  final Map<String, String> reflections;
  final Map<String, String> prompts;

  const InspirationalQuote({
    required this.id,
    required this.quote,
    required this.author,
    required this.stage,
    required this.category,
    required this.subTag,
    required this.reflections,
    required this.prompts,
  });

  String reflectionFor(String langCode) =>
      reflections[langCode] ??
      reflections['eng'] ??
      (reflections.isNotEmpty ? reflections.values.first : '');

  String promptFor(String langCode) =>
      prompts[langCode] ??
      prompts['eng'] ??
      'Take a slow breath here before continuing your day.';

  Map<String, dynamic> toJson() => {
        'id': id,
        'quote': quote,
        'author': author,
        'stage': stage.name,
        'category': category,
        'sub_tag': subTag,
        'reflections': reflections,
        'prompts': prompts,
      };

  factory InspirationalQuote.fromJson(Map<String, dynamic> json) {
    final rawStage = json['stage']?.toString().toLowerCase().trim();
    MoodStage stage = MoodStage.humble;
    for (final s in MoodStage.values) {
      if (s.name == rawStage) {
        stage = s;
        break;
      }
    }

    final quoteStr = json['quote']?.toString() ?? '';
    final authorStr = json['author']?.toString() ?? 'Anonymous';

    final reflectionsMap = <String, String>{};
    if (json['reflections'] is Map) {
      (json['reflections'] as Map).forEach((k, v) {
        reflectionsMap[k.toString()] = v.toString();
      });
    } else if (json['reflection'] is String) {
      reflectionsMap['eng'] = json['reflection'] as String;
    }
    if (reflectionsMap.isEmpty) {
      reflectionsMap.addAll(QuoteApiService.defaultReflectionForStage(stage));
    }

    final promptsMap = <String, String>{};
    if (json['prompts'] is Map) {
      (json['prompts'] as Map).forEach((k, v) {
        promptsMap[k.toString()] = v.toString();
      });
    } else if (json['prompt'] is String) {
      promptsMap['eng'] = json['prompt'] as String;
    }
    if (promptsMap.isEmpty) {
      promptsMap.addAll(QuoteApiService.defaultPromptForStage(stage));
    }

    final rawId = json['id']?.toString();
    final fallbackId = 'quote_${(quoteStr + authorStr).hashCode & 0x7fffffff}';

    return InspirationalQuote(
      id: rawId != null && rawId.isNotEmpty ? rawId : fallbackId,
      quote: quoteStr,
      author: authorStr,
      stage: stage,
      category: json['category']?.toString() ?? QuoteApiService.categoryForStage(stage),
      subTag: json['sub_tag']?.toString() ?? json['subTag']?.toString() ?? QuoteApiService.subTagForStage(stage),
      reflections: reflectionsMap,
      prompts: promptsMap,
    );
  }
}

/// Service that fetches inspirational quotes with zero API key from:
/// - Primary: `https://zenquotes.io/api/quotes` (JSON: `[{ "q": "...", "a": "..." }]`)
/// - Fallback: `https://dummyjson.com/quotes?limit=50` (JSON: `{ "quotes": [{ "quote": "...", "author": "..." }] }`)
///
/// Tags incoming quotes into 4 moods using keyword matching and caches them
/// in [SharedPreferences] for offline swiping.
class QuoteApiService {
  static const String zenQuotesUrl = 'https://zenquotes.io/api/quotes';
  static const String dummyJsonQuotesUrl = 'https://dummyjson.com/quotes?limit=50';
  static const String cacheKey = 'cached_inspirational_quotes';

  final SharedPreferences? _prefs;
  final http.Client? _httpClient;

  QuoteApiService({
    SharedPreferences? prefs,
    http.Client? httpClient,
  })  : _prefs = prefs,
        _httpClient = httpClient;

  http.Client get _client => _httpClient ?? http.Client();

  Future<SharedPreferences> get _preferences async =>
      _prefs ?? await SharedPreferences.getInstance();

  /// Fetches quotes, trying primary API then fallback API, with local cache & seed fallback.
  Future<List<InspirationalQuote>> getQuotes({bool forceRefresh = false}) async {
    final prefs = await _preferences;

    // 1. Check offline cache if refresh not forced
    if (!forceRefresh) {
      final cached = _getCachedQuotes(prefs);
      if (cached.isNotEmpty) {
        return cached;
      }
    }

    // 2. Try Primary API (ZenQuotes)
    try {
      final quotes = await _fetchZenQuotes();
      if (quotes.isNotEmpty) {
        await _saveQuotesToCache(prefs, quotes);
        return quotes;
      }
    } catch (_) {
      // Primary API failed, fall through to fallback
    }

    // 3. Try Fallback API (DummyJSON)
    try {
      final quotes = await _fetchDummyJsonQuotes();
      if (quotes.isNotEmpty) {
        await _saveQuotesToCache(prefs, quotes);
        return quotes;
      }
    } catch (_) {
      // Fallback API failed
    }

    // 4. Return cached quotes if available
    final cached = _getCachedQuotes(prefs);
    if (cached.isNotEmpty) {
      return cached;
    }

    // 5. Guaranteed seed quotes fallback
    return seedQuotes;
  }

  /// Fetches quotes from ZenQuotes API: `[{"q": "...", "a": "..."}]`
  Future<List<InspirationalQuote>> _fetchZenQuotes() async {
    final uri = Uri.parse(zenQuotesUrl);
    final response = await _client.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        final quotes = <InspirationalQuote>[];
        for (var i = 0; i < decoded.length; i++) {
          final item = decoded[i];
          if (item is Map) {
            final q = item['q']?.toString().trim() ?? '';
            final a = item['a']?.toString().trim() ?? 'Unknown';
            if (q.isNotEmpty) {
              final quoteId = 'zq_${(q + a).hashCode & 0x7fffffff}';
              quotes.add(_buildClassifiedQuote(quoteId, q, a));
            }
          }
        }
        return quotes;
      }
    }
    return <InspirationalQuote>[];
  }

  /// Fetches quotes from DummyJSON API: `{"quotes": [{"quote": "...", "author": "..."}]}`
  Future<List<InspirationalQuote>> _fetchDummyJsonQuotes() async {
    final uri = Uri.parse(dummyJsonQuotesUrl);
    final response = await _client.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['quotes'] is List) {
        final list = decoded['quotes'] as List;
        final quotes = <InspirationalQuote>[];
        for (var i = 0; i < list.length; i++) {
          final item = list[i];
          if (item is Map) {
            final q = item['quote']?.toString().trim() ?? '';
            final a = item['author']?.toString().trim() ?? 'Unknown';
            if (q.isNotEmpty) {
              final quoteId = 'dj_${item['id'] ?? ((q + a).hashCode & 0x7fffffff)}';
              quotes.add(_buildClassifiedQuote(quoteId, q, a));
            }
          }
        }
        return quotes;
      }
    }
    return <InspirationalQuote>[];
  }

  /// Classifies a quote into one of the 4 [MoodStage] values using keyword matching.
  static MoodStage classifyMood(String text) {
    final lower = text.toLowerCase();

    const gloomyWords = [
      'sad', 'sorrow', 'pain', 'dark', 'darkness', 'grief', 'cry', 'tears',
      'heavy', 'broken', 'hurt', 'weary', 'loss', 'struggle', 'lonely',
      'loneliness', 'despair', 'trouble', 'storm', 'shadow', 'fear',
      'afraid', 'burden', 'ache', 'wound', 'suffering', 'weep', 'hardship'
    ];

    const growingWords = [
      'grow', 'growth', 'learn', 'seed', 'patience', 'patient', 'endure',
      'endurance', 'persevere', 'perseverance', 'progress', 'journey',
      'strength', 'strong', 'change', 'season', 'process', 'become',
      'overcome', 'build', 'rise', 'effort', 'path', 'fail', 'failure',
      'mistake', 'discipline', 'trial', 'climb', 'strive', 'work', 'step'
    ];

    const brightWords = [
      'joy', 'joyful', 'gratitude', 'grateful', 'light', 'bright', 'shine',
      'sun', 'sunlight', 'morning', 'smile', 'laugh', 'cheer', 'rejoice',
      'peace', 'hope', 'hopeful', 'love', 'bless', 'blessing', 'delight',
      'wonder', 'beauty', 'beautiful', 'warmth', 'radiant', 'celebrate',
      'gift', 'happiness', 'happy', 'bloom', 'shine'
    ];

    const humbleWords = [
      'humble', 'humility', 'silence', 'silent', 'quiet', 'still', 'stillness',
      'gentle', 'gently', 'listen', 'serve', 'service', 'simple', 'simplicity',
      'modest', 'mercy', 'merciful', 'ground', 'truth', 'accept', 'acceptance',
      'small', 'surrender', 'obey', 'meek', 'calm', 'rest', 'peace', 'grace',
      'wise', 'wisdom', 'mind', 'heart'
    ];

    int gloomyScore = 0;
    int growingScore = 0;
    int brightScore = 0;
    int humbleScore = 0;

    for (final word in gloomyWords) {
      if (lower.contains(word)) gloomyScore++;
    }
    for (final word in growingWords) {
      if (lower.contains(word)) growingScore++;
    }
    for (final word in brightWords) {
      if (lower.contains(word)) brightScore++;
    }
    for (final word in humbleWords) {
      if (lower.contains(word)) humbleScore++;
    }

    final maxScore = [gloomyScore, growingScore, brightScore, humbleScore]
        .reduce((a, b) => a > b ? a : b);

    if (maxScore == 0) {
      // Balanced deterministic fallback across words
      final hash = text.hashCode & 0x7fffffff;
      return MoodStage.values[hash % MoodStage.values.length];
    }

    if (gloomyScore == maxScore) return MoodStage.gloomy;
    if (growingScore == maxScore) return MoodStage.growing;
    if (brightScore == maxScore) return MoodStage.bright;
    return MoodStage.humble;
  }

  InspirationalQuote _buildClassifiedQuote(String id, String quote, String author) {
    final stage = classifyMood(quote);
    final category = categoryForStage(stage);
    final subTag = subTagForStage(stage);
    final reflection = defaultReflectionForStage(stage);
    final prompt = defaultPromptForStage(stage);

    return InspirationalQuote(
      id: id,
      quote: quote,
      author: author,
      stage: stage,
      category: category,
      subTag: subTag,
      reflections: reflection,
      prompts: prompt,
    );
  }

  static String categoryForStage(MoodStage stage) {
    switch (stage) {
      case MoodStage.gloomy:
        return 'Comfort in Heavy Seasons';
      case MoodStage.growing:
        return 'Patience in the Process';
      case MoodStage.bright:
        return 'Joy & Abundance';
      case MoodStage.humble:
        return 'Simple Devotion & Wisdom';
    }
  }

  static String subTagForStage(MoodStage stage) {
    switch (stage) {
      case MoodStage.gloomy:
        return 'Morning Pause';
      case MoodStage.growing:
        return 'Quiet Growth';
      case MoodStage.bright:
        return 'Sunlit Gratitude';
      case MoodStage.humble:
        return 'Walking Lightly';
    }
  }

  static Map<String, String> defaultReflectionForStage(MoodStage stage) {
    switch (stage) {
      case MoodStage.gloomy:
        return {
          'eng':
              'Even in seasons of heavy sorrow, you are never abandoned. A quiet pause allows the wounded spirit to breathe and heal without rush.',
          'lus':
              'Rilru a pik lai pawhin malin i awm lo. Inthlahdulin thawk la la, Pathianin i nun a tidam leh ngei ang.',
          'hin':
              'मन भारी हो तो भी आप अकेले नहीं हैं। ठहरकर गहरी सांस लें; दर्द के बीच भी सुकून की राह निकलती है।',
          'spa':
              'Incluso en momentos de pesadumbre, no estás solo. Una pausa tranquila permite que el espíritu herido respire y sane sin prisa.',
        };
      case MoodStage.growing:
        return {
          'eng':
              'Patience is quiet strength in disguise. A seed does not doubt its growth while hidden beneath dark soil; trust this quiet season.',
          'lus':
              'Dawhtheihna hi chakna thuruk a ni. Chi chu lei hnuai thimah a ṭhang zel ang hian, i zinkawng hi ringhlel suh.',
          'hin':
              'धैर्य ही असली ताकत है। मिट्टी के नीचे दबा बीज भी खिलने का भरोसा रखता है; अपने सफर पर विश्वास रखें।',
          'spa':
              'La paciencia es fortaleza serena. La semilla no duda de su crecimiento mientras permanece bajo la tierra; confía en este tiempo.',
        };
      case MoodStage.bright:
        return {
          'eng':
              'When gratitude fills your heart, let it spill gently into the world around you. Hold this warmth with open hands and a thankful spirit.',
          'lus':
              'Thinlung lawmnain a khah lai hian midangte tan malsawmna ni rawh. Kut pharh meuhin he hun hlimawm hi pawm rawh.',
          'hin':
              'जब दिल कृतज्ञता से भर जाए, तो इसे दूसरों के साथ भी बाँटें। इस खुशी को खुले दिल और आभार के साथ स्वीकार करें।',
          'spa':
              'Cuando la gratitud colma tu corazón, compártela suavemente. Recibe esta bendición con manos abiertas y espíritu agradecido.',
        };
      case MoodStage.humble:
        return {
          'eng':
              'True wisdom walks with gentle steps and an open heart. Release the urge to control tomorrow, and rest peacefully in the grace of today.',
          'lus':
              'Finna dik tak chu nun nem leh inngaitlawmah a awm. Naktuk buaina dah la, vawiin khawngaihnaah hian hahdam rawh.',
          'hin':
              'सच्ची समझ विनम्रता से चलने में है। कल के नियंत्रण की चिंता छोड़ें और आज के इस पल में शांति से रहें।',
          'spa':
              'La verdadera sabiduría camina con pasos suaves y corazón abierto. Suelta el control del mañana y descansa en la gracia de hoy.',
        };
    }
  }

  static Map<String, String> defaultPromptForStage(MoodStage stage) {
    switch (stage) {
      case MoodStage.gloomy:
        return {
          'eng': 'Take a slow, gentle breath and let your shoulders drop.',
          'lus': 'Thawk la vang vang la, inthlahdul rawh le.',
          'hin': 'एक गहरी और शांत सांस लें, खुद पर कोई बोझ न रखें।',
          'spa': 'Toma una respiración pausada y relaja los hombros.',
        };
      case MoodStage.growing:
        return {
          'eng': 'Allow yourself the grace to be unfinished today.',
          'lus': 'Vawiinah hian engkim zawh vek tum suh, inthlahdul rawh.',
          'hin': 'आज सब कुछ पूरा करने का दबाव छोड़ें, खुद पर दया रखें।',
          'spa': 'Permítete la gracia de ser una obra en proceso hoy.',
        };
      case MoodStage.bright:
        return {
          'eng': 'Whisper a short thank you for one simple blessing right now.',
          'lus': 'Malsawmna pakhat tal avangin lawmthu sawi sap rawh.',
          'hin': 'इस पल किसी एक छोटी सी खुशी के लिए मन ही मन धन्यवाद कहें।',
          'spa': 'Agradece en silencio por una pequeña bendición en este instante.',
        };
      case MoodStage.humble:
        return {
          'eng': 'Step lightly and speak gently to the next person you meet.',
          'lus': 'I mi tawh hmasak ber hnenah nem takin ṭawngkam chhuah rawh.',
          'hin': 'अगले मिलने वाले व्यक्ति से विनम्रता और मिठास के साथ बात करें।',
          'spa': 'Da pasos suaves y habla con dulzura a la próxima persona que encuentres.',
        };
    }
  }

  List<InspirationalQuote> _getCachedQuotes(SharedPreferences prefs) {
    final cachedStr = prefs.getString(cacheKey);
    if (cachedStr != null && cachedStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(cachedStr);
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map((m) => InspirationalQuote.fromJson(Map<String, dynamic>.from(m)))
              .toList();
        }
      } catch (_) {
        // Cache corrupted
      }
    }
    return <InspirationalQuote>[];
  }

  Future<void> _saveQuotesToCache(
    SharedPreferences prefs,
    List<InspirationalQuote> quotes,
  ) async {
    try {
      final jsonList = quotes.map((q) => q.toJson()).toList();
      await prefs.setString(cacheKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  /// Default curated seed quotes spanning all 4 [MoodStage] themes.
  static const List<InspirationalQuote> seedQuotes = [
    // --- GLOOMY STAGE ---
    InspirationalQuote(
      id: 'seed_q_gloomy_1',
      quote: 'The cure for pain is in the pain.',
      author: 'Rumi',
      stage: MoodStage.gloomy,
      category: 'Comfort in Heavy Seasons',
      subTag: 'Morning Pause',
      reflections: {
        'eng': 'Feeling heartbroken does not mean you have failed. When you acknowledge grief rather than running from it, healing begins to unfurl quietly.',
        'lus': 'Rilru natna tawrh hi hlawhchhamna a ni lo. I lungngaihna i pawm thiam hunah tihdamna a lo inṭan ṭhîn.',
        'hin': 'दर्द को स्वीकार करना ही उपचार की शुरुआत है। जब आप अपनी पीड़ा से भागते नहीं, तब दिल धीरे-धीरे संभलने लगता है।',
        'spa': 'Sentir dolor no significa fracasar. Cuando acoges el dolor con ternura, la sanación comienza a desplegarse en silencio.',
      },
      prompts: {
        'eng': 'Take a slow breath here before continuing your day.',
        'lus': 'I chhunzawm hmain thawk la vang vang rawh le.',
        'hin': 'आगे बढ़ने से पहले एक गहरी और शांत साँस लें।',
        'spa': 'Toma un respiro profundo y pausado antes de continuar.',
      },
    ),
    InspirationalQuote(
      id: 'seed_q_gloomy_2',
      quote: "There is a crack in everything. That's how the light gets in.",
      author: 'Leonard Cohen',
      stage: MoodStage.gloomy,
      category: 'Hope in Brokenness',
      subTag: 'Quiet Rest',
      reflections: {
        'eng': 'Your fractures are not signs of permanent ruin. They are the very places where warmth and transcendent compassion find an opening.',
        'lus': 'I kehchhiatna hi i tawpna tur a ni lo. Khawngaihna leh beiseina eng lo luh theihna hmun a ni zawk.',
        'hin': 'आपकी दरारें कमजोरी नहीं हैं; यहीं से जीवन में प्रकाश और गहरी दया प्रवेश करती है।',
        'spa': 'Tus fracturas no son ruina eterna; son las fisuras por donde penetran la luz y el consuelo.',
      },
      prompts: {
        'eng': 'Rest your mind for a moment; you do not have to fix everything today.',
        'lus': 'Chawl hahdam rawh; vawiinah engkim siamṭhat kher a ngai lo.',
        'hin': 'कुछ पल शांत रहें; आज ही सब कुछ ठीक करना ज़रूरी नहीं।',
        'spa': 'Descansa la mente; no tienes que resolver todo hoy.',
      },
    ),
    InspirationalQuote(
      id: 'seed_q_gloomy_3',
      quote: 'Tears are words that need to be written.',
      author: 'Paulo Coelho',
      stage: MoodStage.gloomy,
      category: 'Quiet Release',
      subTag: 'Tender Comfort',
      reflections: {
        'eng': 'Do not apologize for honest tears. They are the soul’s quiet prayer when ordinary words feel far too heavy to speak aloud.',
        'lus': 'Mittui avangin inthlahrung suh. Ṭawngkam a awm zawh loh laia nunna ṭawngṭaina thuruk a ni.',
        'hin': 'आंसुओं से घबराएं नहीं। जब शब्द कम पड़ जाते हैं, तब आंसू आत्मा की शांत प्रार्थना बन जाते हैं।',
        'spa': 'No te avergüences de tus lágrimas. Son la oración del alma cuando las palabras resultan insuficientes.',
      },
      prompts: {
        'eng': 'Release the pressure to be strong for just this quiet minute.',
        'lus': 'Tun hun reilote chhung hi chu chak tak anga lan tum tawh suh.',
        'hin': 'इस शांत पल में खुद को मजबूत दिखाने का दबाव छोड़ दें।',
        'spa': 'Suelta la exigencia de parecer fuerte en este breve minuto.',
      },
    ),

    // --- GROWING STAGE ---
    InspirationalQuote(
      id: 'seed_q_growing_1',
      quote: 'It does not matter how slowly you go as long as you do not stop.',
      author: 'Confucius',
      stage: MoodStage.growing,
      category: 'Strength in Weakness',
      subTag: 'Quiet Growth',
      reflections: {
        'eng': 'Growth is seldom loud or triumphant. A small, faithful step taken with tired feet is more sacred than a thousand hurried strides.',
        'lus': 'Ṭhang chhoh hi a ri buan buan kher lo. Chau chung pawha ke pen khat zel hi a hlu em em a ni.',
        'hin': 'विकास कभी शोर नहीं मचाता। थके कदमों से उठाया गया एक छोटा, सच्चा कदम भी बहुत अनमोल होता है।',
        'spa': 'El crecimiento rara vez hace ruido. Un paso pequeño y perseverante vale más que mil carreras apresuradas.',
      },
      prompts: {
        'eng': 'Acknowledge the quiet progress you have already made.',
        'lus': 'I hmasawnna te reuh te te te hi theihnghilh suh.',
        'hin': 'अपनी छोटी-छोटी प्रगति की सराहना करें।',
        'spa': 'Reconoce el progreso silencioso que ya has alcanzado.',
      },
    ),
    InspirationalQuote(
      id: 'seed_q_growing_2',
      quote: 'Patience is not the ability to wait, but the ability to keep a good attitude while waiting.',
      author: 'Joyce Meyer',
      stage: MoodStage.growing,
      category: 'Renewing Quiet Strength',
      subTag: 'Gentle Unfolding',
      reflections: {
        'eng': 'Waiting is not an empty delay; it is the fertile soil where resilience and gentle endurance take root deep beneath the surface.',
        'lus': 'Nghah hi hun khawhralna a ni lo; zung a ngheh zualna leh chhelna a lo pianna hmun a ni zawk.',
        'hin': 'इंतज़ार व्यर्थ नहीं होता; यही वह समय है जब भीतर से धैर्य और मजबूती की जड़ें गहरी होती हैं।',
        'spa': 'La espera no es tiempo perdido; es la tierra fértil donde echan raíces la paciencia y el temple.',
      },
      prompts: {
        'eng': 'Breathe out impatience and welcome this present step.',
        'lus': 'Hmanhmawhna paih la, tun hun hi pawm rawh.',
        'hin': 'अधीरता को छोड़ें और इस पल को शांति से स्वीकारें।',
        'spa': 'Exhala la prisa y abraza con serenidad el paso actual.',
      },
    ),
    InspirationalQuote(
      id: 'seed_q_growing_3',
      quote: 'Out of difficulties grow miracles.',
      author: 'Jean de La Bruyère',
      stage: MoodStage.growing,
      category: 'Patience in the Process',
      subTag: 'Silent Blooming',
      reflections: {
        'eng': 'Hard seasons prune away what is unnecessary, leaving room for a deeper and more compassionate life to bloom in due time.',
        'lus': 'Hun harsa hian hringnun a thianfai a, nun thuk leh duhawm zawk lo chhuahna a siam ṭhîn.',
        'hin': 'मुश्किल दौर जीवन को तराशता है, ताकि भविष्य में और गहरी समझ और प्रेम खिल सके।',
        'spa': 'Los tiempos difíciles podan lo innecesario para abrir paso a una vida más honda y compasiva.',
      },
      prompts: {
        'eng': 'Trust that today’s quiet effort is bearing hidden fruit.',
        'lus': 'Vawiina i thawhrimna hi thlawn lo tih ring tlat rawh.',
        'hin': 'भरोसा रखें कि आज की खामोश मेहनत कल रंग लाएगी।',
        'spa': 'Confía en que el esfuerzo silencioso de hoy dará fruto mañana.',
      },
    ),

    // --- BRIGHT STAGE ---
    InspirationalQuote(
      id: 'seed_q_bright_1',
      quote: 'Joy is the simplest form of gratitude.',
      author: 'Karl Barth',
      stage: MoodStage.bright,
      category: 'Joy & Abundance',
      subTag: 'Sunlit Gratitude',
      reflections: {
        'eng': 'Delight in the unearned goodness of this morning. You do not have to overthink a blessing; simply receive it with an open, singing heart.',
        'lus': 'Tukina thilṭha i dawnah hian lawm rawh. Ngaihtuah buai lo la, lawm takin pawm mai rawh.',
        'hin': 'इस सुबह की नेमतों का आनंद लें। आशीर्वाद को बिना संकोच खुले दिल से स्वीकार करें।',
        'spa': 'Alégrate en la bondad sencilla de este día. Recibe la bendición con un corazón agradecido y ligero.',
      },
      prompts: {
        'eng': 'Whisper a short thank you for one simple blessing right now.',
        'lus': 'Malsawmna pakhat tal avangin lawmthu sawi sap rawh.',
        'hin': 'इस पल किसी एक छोटी सी खुशी के लिए मन ही मन धन्यवाद कहें।',
        'spa': 'Agradece en silencio por una pequeña bendición en este instante.',
      },
    ),
    InspirationalQuote(
      id: 'seed_q_bright_2',
      quote: 'Let your light shine so brightly that others see their way out of the dark.',
      author: 'Shannon L. Alder',
      stage: MoodStage.bright,
      category: 'Rejoicing in Simplicity',
      subTag: 'Warm Radiance',
      reflections: {
        'eng': 'A joyful heart is contagious. When warmth fills your soul, let your gentle smile be a lantern for someone stumbling through shadow.',
        'lus': 'Hlimna thinlung hi a inkaichhawn theih. I hlimna chuan midang thim zinga kalte eng pe rawh se.',
        'hin': 'एक खुश दिल दूसरों को भी राह दिखाता है। आपकी मुस्कान किसी अंधेरे में भटके व्यक्ति के लिए रोशनी बन सकती है।',
        'spa': 'Un corazón gozoso es contagioso. Deja que tu sonrisa sea una lámpara para quien camina en sombra.',
      },
      prompts: {
        'eng': 'Send a quiet prayer or kind thought to someone you care about.',
        'lus': 'I ngainat tak tuemaw tan ṭawngṭaina thuruk hlan rawh.',
        'hin': 'अपने किसी प्रियजन के लिए मन में मंगलकामना करें।',
        'spa': 'Envía un pensamiento afectuoso a alguien que aprecias.',
      },
    ),
    InspirationalQuote(
      id: 'seed_q_bright_3',
      quote: 'There are always flowers for those who want to see them.',
      author: 'Henri Matisse',
      stage: MoodStage.bright,
      category: 'Grateful Wonder',
      subTag: 'Sunlit Pause',
      reflections: {
        'eng': 'Beauty is never absent; our eyes only need to soften enough to behold it. Look up and notice the quiet wonder awaiting your glance.',
        'lus': 'Mawina hi a bo ngai lo; kan hmuh thiam a ngai mai a ni. En kual la, Siamtu kutchhuak mawina hi hmu rawh.',
        'hin': 'खूबसूरती हमेशा हमारे आस-पास होती है, बस उसे देखने के लिए दिल का शांत होना ज़रूरी है।',
        'spa': 'La belleza nunca falta; solo necesitamos suavizar la mirada para descubrirla a nuestro alrededor.',
      },
      prompts: {
        'eng': 'Look out a window or gaze at the sky for three calm breaths.',
        'lus': 'Tukverh atangin van en la, vawi thum thawk la vang vang rawh.',
        'hin': 'खिड़की से बाहर आसमान को देखें और तीन गहरी सांसें लें।',
        'spa': 'Mira por la ventana o contempla el cielo durante tres respiraciones suaves.',
      },
    ),

    // --- HUMBLE STAGE ---
    InspirationalQuote(
      id: 'seed_q_humble_1',
      quote: "Humility is not thinking less of yourself, it's thinking of yourself less.",
      author: 'C.S. Lewis',
      stage: MoodStage.humble,
      category: 'Simple Devotion',
      subTag: 'Quiet Walk',
      reflections: {
        'eng': 'True humility unburdens the soul. When you stop obsessing over your standing, you become wonderfully free to simply love and be.',
        'lus': 'Inngaihtlawmna dik tak chuan hahdamna a thlen. Mahni chauh inngaihtuah loh hian hmangaihna a lo lian ṭhîn.',
        'hin': 'सच्ची विनम्रता दिल का बोझ हल्का करती है। जब आप अपनी छवि की चिंता छोड़ते हैं, तो आप प्रेम करने के लिए स्वतंत्र हो जाते हैं।',
        'spa': 'La verdadera humildad aligera el alma. Cuando dejas de preocuparte por tu imagen, te liberas para amar con sinceridad.',
      },
      prompts: {
        'eng': 'Step lightly and speak gently to the next person you meet.',
        'lus': 'I mi tawh hmasak ber hnenah nem takin ṭawngkam chhuah rawh.',
        'hin': 'अगले मिलने वाले व्यक्ति से विनम्रता और मिठास के साथ बात करें।',
        'spa': 'Da pasos suaves y habla con dulzura a la próxima persona que encuentres.',
      },
    ),
    InspirationalQuote(
      id: 'seed_q_humble_2',
      quote: 'Silence is the sleep that nourishes wisdom.',
      author: 'Francis Bacon',
      stage: MoodStage.humble,
      category: 'Leaning Inwardly on Grace',
      subTag: 'Stillness',
      reflections: {
        'eng': 'You do not have to have an opinion on everything or win every argument. In holy stillness, wisdom takes root far deeper than words.',
        'lus': 'Engkimah ngaihdan neih vek kher a ngai lo. Reh taka awm hian finna zung a ngheh phah ṭhîn.',
        'hin': 'हर बात पर राय रखना ज़रूरी नहीं है। मौन और शांति में ही सच्ची समझ गहरी होती है।',
        'spa': 'No tienes que opinar sobre todo ni vencer en cada debate. En la quietud reposa la verdadera sabiduría.',
      },
      prompts: {
        'eng': 'Rest in complete silence for thirty seconds.',
        'lus': 'Second sawmthum chhung engmah sawi lova reh takin awm rawh.',
        'hin': 'तीस सेकंड के लिए पूरी तरह शांत रहें।',
        'spa': 'Permanece en silencio total durante treinta segundos.',
      },
    ),
    InspirationalQuote(
      id: 'seed_q_humble_3',
      quote: 'Be gentle with yourself. You are doing the best you can.',
      author: 'Anonymous',
      stage: MoodStage.humble,
      category: 'Gentle Walk',
      subTag: 'Grace for Today',
      reflections: {
        'eng': 'Humility includes extending mercy toward your own fragile heart. Lay down the heavy measuring stick and rest in the grace given for today.',
        'lus': 'Mahni inngaidam ve bawk rawh. I theih tawp i chhuah a ni tih hria la, Pathian khawngaihnaah innghat rawh.',
        'hin': 'खुद के प्रति भी दयालु रहें। आप पूरी कोशिश कर रहे हैं; आज के अनुग्रह में सुकून पाएं।',
        'spa': 'Sé compasivo contigo mismo. Haces lo mejor que puedes; descansa en la gracia de este día.',
      },
      prompts: {
        'eng': 'Place a hand on your chest and whisper: “Peace be within me.”',
        'lus': 'I awmah kut nghat la: “Ka chhungah remna awm rawh se,” tiin sawi sap rawh.',
        'hin': 'सीने पर हाथ रखें और कहें: "मेरे भीतर शांति बनी रहे।"',
        'spa': 'Pon una mano en tu pecho y susurra: “Paz haya en mí”.',
      },
    ),
  ];
}
