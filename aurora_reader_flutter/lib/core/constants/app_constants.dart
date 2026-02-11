/// Application-wide constants.
class AppConstants {
  AppConstants._();

  static const appName = 'Aurora Reader';
  static const appVersion = '4.0.0';
  static const appBuild = 1;

  // ── API Endpoints ──────────────────────────────────────────────────────
  static const openLibraryBaseUrl = 'https://openlibrary.org';
  static const googleBooksBaseUrl = 'https://www.googleapis.com/books/v1';
  static const dictionaryApiBaseUrl = 'https://api.dictionaryapi.dev/api/v2';
  static const anthropicApiBaseUrl = 'https://api.anthropic.com/v1';

  // ── Defaults ───────────────────────────────────────────────────────────
  static const maxRecentSearches = 20;
  static const defaultDailyGoalMinutes = 30;
  static const defaultFontSize = 18.0;
  static const defaultLineSpacing = 1.6;
  static const defaultFontFamily = 'Georgia';

  // ── Supported Formats ─────────────────────────────────────────────────
  static const supportedFormats = [
    'epub', 'pdf', 'txt', 'fb2', 'mobi',
    'cbz', 'cbr', 'rtf', 'djvu', 'azw3', 'docx',
  ];

  // ── Soundscapes ───────────────────────────────────────────────────────
  static const soundscapes = [
    'gentleRain',
    'thunderstorm',
    'fireplaceCrackle',
    'oceanWaves',
    'forestBirds',
    'cafeAmbience',
    'enchantedForest',
    'spaceAmbient',
    'libraryQuiet',
    'snowfall',
  ];

  static const soundscapeLabels = {
    'gentleRain': 'Gentle Rain',
    'thunderstorm': 'Thunderstorm',
    'fireplaceCrackle': 'Fireplace',
    'oceanWaves': 'Ocean Waves',
    'forestBirds': 'Forest Birds',
    'cafeAmbience': 'Cafe',
    'enchantedForest': 'Enchanted Forest',
    'spaceAmbient': 'Deep Space',
    'libraryQuiet': 'Library',
    'snowfall': 'Snowfall',
  };

  // ── Achievement Types ─────────────────────────────────────────────────
  static const achievementTypes = [
    'firstBook',
    'weekStreak',
    'monthStreak',
    'tenBooks',
    'fiftyBooks',
    'hundredBooks',
    'nightOwl',
    'earlyBird',
    'speedReader',
    'annotator',
    'vocabularian',
    'explorer',
    'socialReader',
    'marathonReader',
  ];
}
