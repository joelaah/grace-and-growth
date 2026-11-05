import 'package:flutter/material.dart';
import '../models/tagged_verse.dart';
import '../theme/mood_stage_theme.dart';

/// Data model representing a Scripture passage and companion reflection
/// localized for the selected contemplative mood and language.
class StageVerse {
  final String id;
  final String reference;
  final String category;
  final String subTag;
  final String readingTime;
  final Map<String, String> scriptureText;
  final Map<String, String> reflectionTitle;
  final Map<String, String> reflectionContent;
  final Map<String, String> promptText;

  const StageVerse({
    required this.id,
    required this.reference,
    required this.category,
    required this.subTag,
    required this.readingTime,
    required this.scriptureText,
    required this.reflectionTitle,
    required this.reflectionContent,
    required this.promptText,
  });

  String get verseId => id;

  String scriptureFor(String langCode) =>
      scriptureText[langCode] ?? scriptureText['eng'] ?? '';

  String reflectionTitleFor(String langCode) =>
      reflectionTitle[langCode] ?? reflectionTitle['eng'] ?? 'A Gentle Thought';

  String reflectionFor(String langCode) =>
      reflectionContent[langCode] ?? reflectionContent['eng'] ?? '';

  String promptFor(String langCode) =>
      promptText[langCode] ?? promptText['eng'] ?? '';

  /// In-memory mock Scripture and Devotional content curated for each [MoodStage]
  /// across 4 languages: English (eng), Mizo/Lushai (lus), Hindi (hin), Spanish (spa).
  static const Map<MoodStage, StageVerse> mockData = {
    MoodStage.gloomy: StageVerse(
      id: 'gloomy_ps34_18',
      reference: 'Psalm 34:18',
      category: 'Comfort in Heavy Seasons',
      subTag: 'Morning Pause',
      readingTime: 'Read slowly • 1 min',
      scriptureText: {
        'eng':
            'The Lord is close to the brokenhearted and saves those who are crushed in spirit.',
        'lus':
            'LALPA chu thinlung lungchhiatte hnaihah a awm a, rilrua inchhirte chu a chhandam ṭhîn.',
        'hin':
            'यहोवा टूटे मन वालों के समीप रहता है, और पिसे हुओं का उद्धार करता है।',
        'spa':
            'Cercano está Jehová a los quebrantados de corazón; y salva a los contritos de espíritu.',
      },
      reflectionTitle: {
        'eng': 'A Gentle Thought',
        'lus': 'Ngaihtuah Zui Atan',
        'hin': 'एक शांत विचार',
        'spa': 'Un Pensamiento Suave',
      },
      reflectionContent: {
        'eng':
            'Feeling heartbroken does not mean your faith is weak. God does not wait for you to put on a brave face—He draws closest when your spirit feels heavy.',
        'lus':
            'I rilru a hah avangin i rinna a chak lo tihna a ni lo. Pathian chuan hlim hmel i put phawt a nghak lo—i rilru a pik lai tak hian I kiangah a awm reng a ni.',
        'hin':
            'मन भारी होने का मतलब यह नहीं कि आपका विश्वास कमज़ोर है। ईश्वर आपके मुस्कुराने का इंतज़ार नहीं करते—जब दिल दुखी होता है, वह आपके सबसे करीब होते हैं।',
        'spa':
            'Sentirte afligido no significa que tu fe sea débil. Dios no espera que finjas fortaleza; Él se acerca más cuando tu espíritu se siente abrumado.',
      },
      promptText: {
        'eng': 'Take a slow breath here before continuing your day.',
        'lus': 'I chhunzawm hmain thawk la vang vang rawh le.',
        'hin': 'आगे बढ़ने से पहले एक गहरी और शांत साँस लें।',
        'spa': 'Toma un respiro profundo y pausado antes de continuar.',
      },
    ),
    MoodStage.growing: StageVerse(
      id: 'growing_2cor12_9',
      reference: '2 Corinthians 12:9',
      category: 'Strength in Weakness',
      subTag: 'Quiet Growth',
      readingTime: 'Read slowly • 1 min',
      scriptureText: {
        'eng':
            'My grace is sufficient for you, for my power is made perfect in weakness.',
        'lus':
            'Ka khawngaihna i tan a tawk e; ka thiltihtheihna hi chak lohnaah asin tihfamkimin a awm ni.',
        'hin':
            'मेरा अनुग्रह तेरे लिये बहुत है; क्योंकि मेरी सामर्थ्य निर्बलता में सिद्ध होती है।',
        'spa':
            'Bástate mi gracia; porque mi poder se perfecciona en la debilidad.',
      },
      reflectionTitle: {
        'eng': 'A Gentle Thought',
        'lus': 'Ngaihtuah Zui Atan',
        'hin': 'एक शांत विचार',
        'spa': 'Un Pensamiento Suave',
      },
      reflectionContent: {
        'eng':
            'Growth often feels quiet and tender like a seed beneath dark soil. You do not have to carry tomorrow’s burden today; grace is measured for this very moment.',
        'lus':
            'Thil ṭhang lai hi lei hnuaia chi nung ang maiin a reh ṭhîn. Naktuk buaina chu vawiinah phur vek kher suh; tun hun atan hian khawngaihna a tawk em em a ni.',
        'hin':
            'विकास अक्सर मिट्टी के नीचे बीज की तरह शांत और धीमा होता है। आज ही कल का बोझ उठाने की ज़रूरत नहीं; इस पल के लिए अनुग्रह ही काफी है।',
        'spa':
            'El crecimiento suele ser silencioso y tierno como una semilla bajo tierra. No tienes que cargar hoy con el peso de mañana; la gracia basta para este momento.',
      },
      promptText: {
        'eng': 'Allow yourself the grace to be unfinished today.',
        'lus': 'Vawiinah hian engkim zawh vek tum suh, inthlahdul rawh.',
        'hin': 'आज सब कुछ पूरा करने का दबाव छोड़ें, खुद पर दया रखें।',
        'spa': 'Permítete la gracia de ser una obra en proceso hoy.',
      },
    ),
    MoodStage.bright: StageVerse(
      id: 'bright_num6_24',
      reference: 'Numbers 6:24-26',
      category: 'Joy & Abundance',
      subTag: 'Sunlit Gratitude',
      readingTime: 'Read slowly • 1 min',
      scriptureText: {
        'eng':
            'The Lord bless you and keep you; the Lord make his face shine on you and be gracious to you; the Lord turn his face toward you and give you peace.',
        'lus':
            'LALPAN malsawm che sela, vawng ṭha che rawh se; LALPAN a hmel entir che sela, khawngaih che rawh se; LALPAN a hmel chhun tir che sela, thlamuanna pe che rawh se.',
        'hin':
            'यहोवा तुझे आशीष दे और तेरी रक्षा करे: यहोवा तुझ पर अपने मुख का प्रकाश चमकाए, और तुझ पर अनुग्रह करे: यहोवा अपना मुख तेरी ओर करे, और तुझे शान्ति दे।',
        'spa':
            'Jehová te bendiga, y te guarde; Jehová haga resplandecer su rostro sobre ti, y tenga de ti misericordia; Jehová alce sobre ti su rostro, y ponga en ti paz.',
      },
      reflectionTitle: {
        'eng': 'A Gentle Thought',
        'lus': 'Ngaihtuah Zui Atan',
        'hin': 'एक शांत विचार',
        'spa': 'Un Pensamiento Suave',
      },
      reflectionContent: {
        'eng':
            'When gratitude fills your heart, let it spill gently into the world around you. Hold this warmth with open hands, thanking the One who gives every good gift.',
        'lus':
            'I thinlung lawmnain a khah lai hian midangte hnenah nem takin puang chhuak rawh. Kut pharh meuhin he duhsakna hi pawm la, thilṭha zawng zawng petu chu fak rawh.',
        'hin':
            'जब दिल कृतज्ञता से भर जाए, तो इस सुकून को अपने आस-पास भी बाँटें। हर अच्छी आशीष देने वाले प्रभु का धन्यवाद करें।',
        'spa':
            'Cuando la gratitud llena tu corazón, deja que ilumine tu entorno. Recibe esta bendición con manos abiertas, agradeciendo al dador de toda buena dádiva.',
      },
      promptText: {
        'eng': 'Whisper a short thank you for one simple blessing right now.',
        'lus': 'Malsawmna pakhat tal avangin lawmthu sawi sap rawh.',
        'hin': 'इस पल किसी एक छोटी सी खुशी के लिए मन ही मन धन्यवाद कहें।',
        'spa': 'Agradece en silencio por una pequeña bendición en este instante.',
      },
    ),
    MoodStage.humble: StageVerse(
      id: 'humble_micah6_8',
      reference: 'Micah 6:8',
      category: 'Simple Devotion',
      subTag: 'Quiet Walk',
      readingTime: 'Read slowly • 1 min',
      scriptureText: {
        'eng':
            'He has shown you, O mortal, what is good. And what does the Lord require of you? To act justly and to love mercy and to walk humbly with your God.',
        'lus':
            'Aw mihring, ṭha chu a entir tawh che a ni; LALPA phût chu dik taka tih leh khawngaihna ngainat leh, i Pathian nena thuhnuairawlh taka len dun chauh a ni lo vem ni?',
        'hin':
            'हे मनुष्य, वह तुझ पर प्रगट कर चुका है कि भला क्या है; और यहोवा तुझ से इसे छोड़ और क्या चाहता है, कि तू न्याय से काम करे, और कृपा से प्रीति रखे, और अपने परमेश्वर के साथ नम्रता से चले?',
        'spa':
            'Oh hombre, él te ha declarado lo que es bueno, y qué pide Jehová de ti: solamente hacer justicia, y amar misericordia, y humillarte ante tu Dios.',
      },
      reflectionTitle: {
        'eng': 'A Gentle Thought',
        'lus': 'Ngaihtuah Zui Atan',
        'hin': 'एक शांत विचार',
        'spa': 'Un Pensamiento Suave',
      },
      reflectionContent: {
        'eng':
            'Faith is rarely about grand spectacles; it is walking quietly step by step, showing kindness without noise, and resting in the steady guidance of your Maker.',
        'lus':
            'Rinna chu thil ropui leh thawm na tak a ni ber lo; thawm nei lova ngilneihna lantir leh, Siamtu hruaina rinchhana thuhnuairawlh taka kal zel hi a ni zawk.',
        'hin':
            'विश्वास कोई बड़ा दिखावा नहीं; यह शांति से एक-एक कदम चलना है, बिना शोर के दया दिखाना और अपने ईश्वर के साथ नम्रता से जीना है।',
        'spa':
            'La fe rara vez se trata de grandes espectáculos; se trata de caminar paso a paso, practicar la misericordia sin ruido y descansar con humildad en Dios.',
      },
      promptText: {
        'eng': 'Step lightly and speak gently to the next person you meet.',
        'lus': 'I mi tawh hmasak ber hnenah nem takin ṭawngkam chhuah rawh.',
        'hin': 'अगले मिलने वाले व्यक्ति से विनम्रता और मिठास के साथ बात करें।',
        'spa': 'Da pasos suaves y habla con dulzura a la próxima persona que encuentres.',
      },
    ),
  };

  static StageVerse forStage(MoodStage stage) =>
      mockData[stage] ?? mockData[MoodStage.gloomy]!;

  static StageVerse? findById(String id) {
    for (final verse in mockData.values) {
      if (verse.id == id) return verse;
    }
    return null;
  }

  /// Converts a [TaggedVerse] into a [StageVerse], optionally embedding freshly resolved Bible text.
  factory StageVerse.fromTaggedVerse(
    TaggedVerse tagged, {
    String? resolvedText,
    String langCode = 'eng',
  }) {
    final texts = Map<String, String>.from(tagged.textsByLang);
    if (resolvedText != null && resolvedText.isNotEmpty) {
      texts[langCode] = resolvedText;
    }
    return StageVerse(
      id: tagged.id,
      reference: tagged.reference,
      category: tagged.category ?? 'Daily Pause',
      subTag: tagged.subTag ?? 'Reflection',
      readingTime: 'Read slowly • 1 min',
      scriptureText: texts,
      reflectionTitle: {
        'eng': 'A Gentle Thought',
        'lus': 'Ngaihtuah Zui Atan',
        'hin': 'एक शांत विचार',
        'spa': 'Un Pensamiento Suave',
      },
      reflectionContent: tagged.reflectionsByLang,
      promptText: {
        'eng': 'Take a slow breath here before continuing your day.',
        'lus': 'I chhunzawm hmain thawk la vang vang rawh le.',
        'hin': 'आगे बढ़ने से पहले एक गहरी और शांत साँस लें।',
        'spa': 'Toma un respiro profundo y pausado antes de continuar.',
      },
    );
  }
}

/// Central Scripture Card and companion "A Gentle Thought" Reflection Card.
/// Designed with a 24px corner radius, uncluttered typography, and soft ambient depth.
class VerseStageCard extends StatelessWidget {
  final StageVerse verse;
  final StagePalette palette;
  final String langCode;
  final bool isBookmarked;
  final bool isPlayingAudio;
  final VoidCallback? onBookmarkToggle;
  final VoidCallback? onAudioToggle;
  final VoidCallback? onShare;

  const VerseStageCard({
    super.key,
    required this.verse,
    required this.palette,
    required this.langCode,
    this.isBookmarked = false,
    this.isPlayingAudio = false,
    this.onBookmarkToggle,
    this.onAudioToggle,
    this.onShare,
  });

  String get verseId => verse.id;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildScriptureCard(),
        const SizedBox(height: 16),
        _buildReflectionCard(),
        const SizedBox(height: 20),
        _buildFloatingActionRow(),
      ],
    );
  }

  Widget _buildScriptureCard() {
    return Container(
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: palette.cardBorder.withValues(alpha: 0.7),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20.0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 26.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top metadata row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 5.0,
                  ),
                  decoration: BoxDecoration(
                    color: palette.bgTop.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: palette.cardBorder.withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.spa_outlined,
                        size: 14.0,
                        color: palette.accent,
                      ),
                      const SizedBox(width: 6.0),
                      Flexible(
                        child: Text(
                          verse.category,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w500,
                            color: palette.secondaryText,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              Container(
                width: 32.0,
                height: 32.0,
                decoration: BoxDecoration(
                  color: palette.bgTop.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.format_quote_rounded,
                  size: 18.0,
                  color: palette.accent.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20.0),
          // Scripture text quote
          Text(
            '“${verse.scriptureFor(langCode)}”',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 22.0,
              height: 1.48,
              fontWeight: FontWeight.w400,
              color: palette.primaryText,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 22.0),
          // Reference & indicator row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  verse.reference,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: palette.accent,
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6.0,
                    height: 6.0,
                    decoration: BoxDecoration(
                      color: palette.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6.0),
                  Text(
                    verse.subTag,
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w400,
                      color: palette.secondaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReflectionCard() {
    return Container(
      decoration: BoxDecoration(
        color: palette.cardSurface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: palette.cardBorder.withValues(alpha: 0.45),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with warm icon and reading timer
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32.0,
                height: 32.0,
                decoration: BoxDecoration(
                  color: palette.accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.volunteer_activism_outlined,
                  size: 16.0,
                  color: palette.accent,
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      verse.reflectionTitleFor(langCode),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w600,
                        color: palette.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 13.0,
                          color: palette.secondaryText.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 4.0),
                        Flexible(
                          child: Text(
                            verse.readingTime,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w400,
                              color: palette.secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          // Reflection Body
          Text(
            verse.reflectionFor(langCode),
            style: TextStyle(
              fontSize: 15.0,
              height: 1.58,
              fontWeight: FontWeight.w400,
              color: palette.primaryText.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 16.0),
          // Ambient breathing guidance prompt
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Icon(
                  Icons.arrow_right_alt_rounded,
                  size: 16.0,
                  color: palette.accent.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(width: 6.0),
              Expanded(
                child: Text(
                  verse.promptFor(langCode),
                  style: TextStyle(
                    fontSize: 13.0,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                    color: palette.secondaryText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionRow() {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: palette.cardSurface,
          borderRadius: BorderRadius.circular(30.0),
          border: Border.all(
            color: palette.cardBorder.withValues(alpha: 0.6),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButton(
              icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border_rounded,
              label: isBookmarked ? 'Saved' : 'Save',
              isActive: isBookmarked,
              onTap: onBookmarkToggle,
            ),
            _buildDivider(),
            _buildActionButton(
              icon: isPlayingAudio ? Icons.pause_circle_outline_rounded : Icons.volume_up_outlined,
              label: isPlayingAudio ? 'Pause' : 'Listen',
              isActive: isPlayingAudio,
              onTap: onAudioToggle,
            ),
            _buildDivider(),
            _buildActionButton(
              icon: Icons.share_outlined,
              label: 'Share',
              isActive: false,
              onTap: onShare,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1.0,
      height: 22.0,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      color: palette.cardBorder.withValues(alpha: 0.5),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback? onTap,
  }) {
    final activeColor = palette.accent;
    final inactiveColor = palette.secondaryText;
    final color = isActive ? activeColor : inactiveColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18.0, color: color),
              const SizedBox(height: 2.0),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
