import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── LIBRARY ────────────────────────────────────────────────────────────────

/// Current library filter: all, reading, finished, wantToRead
final libraryFilterProvider = StateProvider<String>((ref) => 'all');

/// Current library sort mode: recent, title, author, progress
final librarySortProvider = StateProvider<String>((ref) => 'recent');

/// Library search query.
final librarySearchProvider = StateProvider<String>((ref) => '');

// ─── READER ─────────────────────────────────────────────────────────────────

/// Reader font size.
final readerFontSizeProvider = StateProvider<double>((ref) => 18.0);

/// Reader font family.
final readerFontFamilyProvider = StateProvider<String>((ref) => 'Georgia');

/// Reader line spacing multiplier.
final readerLineSpacingProvider = StateProvider<double>((ref) => 1.6);

/// true = scroll mode, false = page mode.
final readerScrollModeProvider = StateProvider<bool>((ref) => true);

/// Reader brightness override (-1 = use system).
final readerBrightnessProvider = StateProvider<double>((ref) => -1);

// ─── AMBIENT ────────────────────────────────────────────────────────────────

/// Current ambient soundscape name, null = off.
final ambientSoundscapeProvider = StateProvider<String?>((ref) => null);

/// Ambient volume 0.0 – 1.0.
final ambientVolumeProvider = StateProvider<double>((ref) => 0.5);

// ─── KNOWLEDGE ──────────────────────────────────────────────────────────────

/// Knowledge tab index: 0=Themes, 1=Vocabulary, 2=Highlights.
final knowledgeTabProvider = StateProvider<int>((ref) => 0);

// ─── ACTIVITY ───────────────────────────────────────────────────────────────

/// Activity time period: week, month, year.
final activityTimePeriodProvider = StateProvider<String>((ref) => 'week');
