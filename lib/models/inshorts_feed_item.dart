import '../models/tagged_verse.dart';
import '../services/quote_api_service.dart';
import '../theme/mood_stage_theme.dart';

/// The type of content card in the Inshorts-style feed.
enum FeedItemType {
  verse,
  quote,
}

/// Unified data representation for a single Inshorts stage card.
class InshortsFeedItem {
  final String id;
  final FeedItemType type;
  final MoodStage stage;
  final String sourceBadge;
  final String mainText;
  final String attribution;
  final String category;
  final String subTag;
  final String reflectionTitle;
  final String reflectionContent;
  final String promptText;
  final String readingTime;
  final TaggedVerse? taggedVerse;
  final InspirationalQuote? quote;

  const InshortsFeedItem({
    required this.id,
    required this.type,
    required this.stage,
    required this.sourceBadge,
    required this.mainText,
    required this.attribution,
    required this.category,
    required this.subTag,
    required this.reflectionTitle,
    required this.reflectionContent,
    required this.promptText,
    this.readingTime = 'Read slowly • 1 min',
    this.taggedVerse,
    this.quote,
  });

  bool get isVerse => type == FeedItemType.verse;
  bool get isQuote => type == FeedItemType.quote;

  /// Creates a feed item from a [TaggedVerse].
  factory InshortsFeedItem.fromVerse(
    TaggedVerse verse, {
    String langCode = 'eng',
    String? resolvedText,
  }) {
    final title = _localizedReflectionTitle(langCode);
    final text = resolvedText ?? verse.textFor(langCode) ?? verse.textFor('eng') ?? '';
    final reflection = verse.reflectionFor(langCode);

    return InshortsFeedItem(
      id: 'verse_${verse.id}',
      type: FeedItemType.verse,
      stage: verse.primaryStage,
      sourceBadge: 'BIBLE VERSE',
      mainText: text,
      attribution: verse.reference,
      category: verse.category ?? 'Comfort in Heavy Seasons',
      subTag: verse.subTag ?? 'Morning Pause',
      reflectionTitle: title,
      reflectionContent: reflection,
      promptText: _promptForLang(verse.primaryStage, langCode),
      readingTime: 'Read slowly • 1 min',
      taggedVerse: verse,
    );
  }

  /// Creates a feed item from an [InspirationalQuote].
  factory InshortsFeedItem.fromQuote(
    InspirationalQuote quote, {
    String langCode = 'eng',
  }) {
    final title = _localizedReflectionTitle(langCode);
    final reflection = quote.reflectionFor(langCode);
    final prompt = quote.promptFor(langCode);

    return InshortsFeedItem(
      id: 'quote_${quote.id}',
      type: FeedItemType.quote,
      stage: quote.stage,
      sourceBadge: 'INSPIRATIONAL QUOTE',
      mainText: quote.quote,
      attribution: '— ${quote.author}',
      category: quote.category,
      subTag: quote.subTag,
      reflectionTitle: title,
      reflectionContent: reflection,
      promptText: prompt,
      readingTime: 'Read slowly • 1 min',
      quote: quote,
    );
  }

  static String _localizedReflectionTitle(String langCode) {
    switch (langCode) {
      case 'lus':
        return 'Ngaihtuah Zui Atan';
      case 'hin':
        return 'एक शांत विचार';
      case 'spa':
        return 'Un Pensamiento Suave';
      case 'eng':
      default:
        return 'A Gentle Thought';
    }
  }

  static String _promptForLang(MoodStage stage, String langCode) {
    switch (stage) {
      case MoodStage.gloomy:
        if (langCode == 'lus') return 'I chhunzawm hmain thawk la vang vang rawh le.';
        if (langCode == 'hin') return 'आगे बढ़ने से पहले एक गहरी और शांत साँस लें।';
        if (langCode == 'spa') return 'Toma un respiro profundo y pausado antes de continuar.';
        return 'Take a slow breath here before continuing your day.';
      case MoodStage.growing:
        if (langCode == 'lus') return 'Vawiinah hian engkim zawh vek tum suh, inthlahdul rawh.';
        if (langCode == 'hin') return 'आज सब कुछ पूरा करने का दबाव छोड़ें, खुद पर दया रखें।';
        if (langCode == 'spa') return 'Permítete la gracia de ser una obra en proceso hoy.';
        return 'Allow yourself the grace to be unfinished today.';
      case MoodStage.bright:
        if (langCode == 'lus') return 'Malsawmna pakhat tal avangin lawmthu sawi sap rawh.';
        if (langCode == 'hin') return 'इस पल किसी एक छोटी सी खुशी के लिए मन ही मन धन्यवाद कहें।';
        if (langCode == 'spa') return 'Agradece en silencio por una pequeña bendición en este instante.';
        return 'Whisper a short thank you for one simple blessing right now.';
      case MoodStage.humble:
        if (langCode == 'lus') return 'I mi tawh hmasak ber hnenah nem takin ṭawngkam chhuah rawh.';
        if (langCode == 'hin') return 'अगले मिलने वाले व्यक्ति से विनम्रता और मिठास के साथ बात करें।';
        if (langCode == 'spa') return 'Da pasos suaves y habla con dulzura a la próxima persona que encuentres.';
        return 'Step lightly and speak gently to the next person you meet.';
    }
  }
}
