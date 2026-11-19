/// Universal localized strings, translation identifiers, and canon divisions
/// for Grace & Growth multi-language outreach (English, Mizo, Hindi, Spanish).
class SanctuaryStrings {
  SanctuaryStrings._();

  static const List<String> supportedLanguages = ['eng', 'lus', 'hin', 'spa'];

  static const Map<String, String> languageEndonyms = {
    'eng': 'English',
    'lus': 'Mizo',
    'hin': 'हिंदी',
    'spa': 'Español',
  };

  static String languageName(String code) => languageEndonyms[code] ?? code;

  /// Canonical translation names for Bible research and verification.
  static String translationName(String langCode) {
    switch (langCode) {
      case 'spa':
        return 'Reina Valera 1909 (RVR09) • Public Domain';
      case 'hin':
        return 'Indian Revised Version (IRV) • Public Domain';
      case 'lus':
        return 'Lushai Holy Bible (Mizo) • Public Domain';
      case 'eng':
      default:
        return 'Berean Standard Bible (BSB) • Public Domain';
    }
  }

  static final Map<String, String> _nameToUsfm = {
    'GENESIS': 'GEN',
    'EXODUS': 'EXO',
    'LEVITICUS': 'LEV',
    'NUMBERS': 'NUM',
    'DEUTERONOMY': 'DEU',
    'JOSHUA': 'JOS',
    'JUDGES': 'JDG',
    'RUTH': 'RUT',
    '1 SAMUEL': '1SA',
    '2 SAMUEL': '2SA',
    '1 KINGS': '1KI',
    '2 KINGS': '2KI',
    '1 CHRONICLES': '1CH',
    '2 CHRONICLES': '2CH',
    'EZRA': 'EZR',
    'NEHEMIAH': 'NEH',
    'ESTHER': 'EST',
    'JOB': 'JOB',
    'PSALM': 'PSA',
    'PSALMS': 'PSA',
    'PROVERBS': 'PRO',
    'ECCLESIASTES': 'ECC',
    'SONG OF SONGS': 'SNG',
    'SONG OF SOLOMON': 'SNG',
    'ISAIAH': 'ISA',
    'JEREMIAH': 'JER',
    'LAMENTATIONS': 'LAM',
    'EZEKIEL': 'EZK',
    'DANIEL': 'DAN',
    'HOSEA': 'HOS',
    'JOEL': 'JOL',
    'AMOS': 'AMO',
    'OBADIAH': 'OBA',
    'JONAH': 'JON',
    'MICAH': 'MIC',
    'NAHUM': 'NAH',
    'HABAKKUK': 'HAB',
    'ZEPHANIAH': 'ZEP',
    'HAGGAI': 'HAG',
    'ZECHARIAH': 'ZEC',
    'MALACHI': 'MAL',
    'MATTHEW': 'MAT',
    'MARK': 'MRK',
    'LUKE': 'LUK',
    'JOHN': 'JHN',
    'ACTS': 'ACT',
    'ROMANS': 'ROM',
    '1 CORINTHIANS': '1CO',
    '2 CORINTHIANS': '2CO',
    'GALATIANS': 'GAL',
    'EPHESIANS': 'EPH',
    'PHILIPPIANS': 'PHP',
    'COLOSSIANS': 'COL',
    '1 THESSALONIANS': '1TH',
    '2 THESSALONIANS': '2TH',
    '1 TIMOTHY': '1TI',
    '2 TIMOTHY': '2TI',
    'TITUS': 'TIT',
    'PHILEMON': 'PHM',
    'HEBREWS': 'HEB',
    'JAMES': 'JAS',
    '1 PETER': '1PE',
    '2 PETER': '2PE',
    '1 JOHN': '1JN',
    '2 JOHN': '2JN',
    '3 JOHN': '3JN',
    'JUDE': 'JUD',
    'REVELATION': 'REV',
  };

  /// Determines biblical testament and canon division from standard USFM book code or full book name.
  static String getCanonDivision(String bookCode) {
    final raw = bookCode.toUpperCase().trim();
    final book = _nameToUsfm[raw] ?? raw;
    switch (book) {
      // Pentateuch / Law (Old Testament)
      case 'GEN':
      case 'EXO':
      case 'LEV':
      case 'NUM':
      case 'DEU':
        return 'Old Testament • Pentateuch (Law)';

      // Historical Books (Old Testament)
      case 'JOS':
      case 'JDG':
      case 'RUT':
      case '1SA':
      case '2SA':
      case '1KI':
      case '2KI':
      case '1CH':
      case '2CH':
      case 'EZR':
      case 'NEH':
      case 'EST':
        return 'Old Testament • Historical Books';

      // Wisdom & Poetry (Old Testament)
      case 'JOB':
      case 'PSA':
      case 'PRO':
      case 'ECC':
      case 'SNG':
        return 'Old Testament • Wisdom & Poetry';

      // Major Prophets (Old Testament)
      case 'ISA':
      case 'JER':
      case 'LAM':
      case 'EZK':
      case 'DAN':
        return 'Old Testament • Major Prophets';

      // Minor Prophets (Old Testament)
      case 'HOS':
      case 'JOL':
      case 'AMO':
      case 'OBA':
      case 'JON':
      case 'MIC':
      case 'NAH':
      case 'HAB':
      case 'ZEP':
      case 'HAG':
      case 'ZEC':
      case 'MAL':
        return 'Old Testament • Minor Prophets';

      // Gospels (New Testament)
      case 'MAT':
      case 'MRK':
      case 'LUK':
      case 'JHN':
        return 'New Testament • The Gospels';

      // Acts / History (New Testament)
      case 'ACT':
        return 'New Testament • Apostolic History';

      // Pauline Epistles (New Testament)
      case 'ROM':
      case '1CO':
      case '2CO':
      case 'GAL':
      case 'EPH':
      case 'PHP':
      case 'COL':
      case '1TH':
      case '2TH':
      case '1TI':
      case '2TI':
      case 'TIT':
      case 'PHM':
        return 'New Testament • Pauline Epistles';

      // General Epistles (New Testament)
      case 'HEB':
      case 'JAS':
      case '1PE':
      case '2PE':
      case '1JN':
      case '2JN':
      case '3JN':
      case 'JUD':
        return 'New Testament • General Epistles';

      // Prophecy / Apocalypse (New Testament)
      case 'REV':
        return 'New Testament • Apocalyptic Prophecy';

      default:
        return 'Holy Scripture • Living Word';
    }
  }

  /// App and Header Titles
  static String appTitle = 'Grace & Growth';

  static String sanctuarySubtitle(String langCode) {
    switch (langCode) {
      case 'lus':
        return 'Ni Tin Biak In';
      case 'hin':
        return 'दैनिक अभयारण्य';
      case 'spa':
        return 'Santuario Diario';
      case 'eng':
      default:
        return 'Daily Sanctuary';
    }
  }

  static String spreadingGospelSubtitle(String langCode) {
    switch (langCode) {
      case 'lus':
        return 'Chanchin Tha Hrilhfiahna';
      case 'hin':
        return 'जीवंत वचन के द्वारा सुसमाचार का प्रसार';
      case 'spa':
        return 'Difundiendo el Evangelio a través de la Palabra Viva';
      case 'eng':
      default:
        return 'Spreading the Gospel through Living Word';
    }
  }

  static String reflectionTitle(String langCode) {
    switch (langCode) {
      case 'lus':
        return 'Ngaihtuah Zui Atan';
      case 'hin':
        return 'एक शांत विचार';
      case 'spa':
        return 'Un Pensamiento Tranquilo';
      case 'eng':
      default:
        return 'A Gentle Thought';
    }
  }

  static String heartQuery(String langCode) {
    switch (langCode) {
      case 'lus':
        return 'Vawiin i rilru eng nge a an?';
      case 'hin':
        return 'आज आपका मन कैसा है?';
      case 'spa':
        return '¿Cómo está tu corazón hoy?';
      case 'eng':
      default:
        return 'How is your heart today?';
    }
  }
}
