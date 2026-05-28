import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/layout/responsive.dart';
import '../../core/theme/aurora_theme.dart';
import '../../core/theme/aurora_widgets.dart';

/// Mock chapter content for demo reading experience
const _mockChapters = <Map<String, String>>[
  {
    'title': 'Chapter 1: The Boy in the Desert',
    'content': '''The boy lay quietly in the shade of the great rock, listening to the silence of the desert. Above him, the sky stretched in an endless dome of burning blue, unmarred by clouds. The sand, fine as powdered glass, shifted in lazy drifts around the base of the outcrop where he had taken shelter.

He had been walking for three days now. Three days since the caravan had left without him, since he had woken to find the campsite empty, the fire cold, and the tracks already half-buried by the restless wind. At first he had run after them, stumbling through the dunes, calling out names that the desert swallowed whole. By the second day he had stopped running.

Now he simply walked. North, he thought, though the stars had grown unreliable and the sun seemed to move in spirals. He carried a half-empty waterskin, a folding knife his grandfather had given him, and a book — a slim volume bound in cracked leather that he had never been able to read, because it was written in a language he did not know.

The rock offered the first real shade he had found since morning. He pressed his back against the cool stone and closed his eyes, letting his breathing slow. Somewhere far away, he thought he heard music — a low, humming vibration that seemed to come from the ground itself, as if the earth were singing in its sleep.

He opened the book to a random page. The characters were strange — looping, flowing things that looked more like drawings of wind than any alphabet he had studied. And yet, in the heat-shimmer of the desert afternoon, they seemed almost to move on the page, rearranging themselves into patterns that tugged at the edges of understanding.

"You can almost read it, can't you?" said a voice.

The boy looked up. A woman stood at the edge of the rock's shadow, dressed in white robes that should have been blinding in the sunlight but instead seemed to absorb it, glowing softly. Her eyes were the color of the desert at twilight — purple fading to deep blue.

"Who are you?" he asked, his voice raw from disuse.

"A traveler," she said, "like you." She sat down across from him without invitation, folding her legs beneath her with fluid grace. "That book you're holding — where did you find it?"

"It was my mother's. She said it came from far away." He turned it over in his hands. "She never told me what it said."

The woman reached out and touched the cover, and the boy felt a tremor run through the leather, as if the book had a heartbeat. "It says many things," she murmured. "But the most important thing it says is this: the desert is not empty. It is full of doors. You just have to learn to see them."

As she spoke, the humming grew louder, and the air around the rock began to shimmer — not with heat, but with something else entirely, something that bent the light into colors the boy had no names for.

"What's happening?" he whispered.

"A door is opening," said the woman. She smiled. "The question is: will you walk through it?"''',
  },
  {
    'title': 'Chapter 2: The City of Echoes',
    'content': '''He walked through.

There was no threshold, no frame — just a place where the air grew thick and then thin again, and suddenly the desert was gone. In its place stood a city.

But not a city like any the boy had known. This city was built of sound. The walls of the buildings were layers of compressed whispers, translucent as amber, and he could see shapes moving within them — the ghosts of conversations had centuries ago. The streets were paved with silence, a silence so deep and perfect that his own footsteps seemed to echo backward in time.

"Welcome to the City of Echoes," said the woman, who had appeared beside him without seeming to move. "Everything ever spoken here has been preserved. Every word, every song, every scream — they are all here, woven into the stones."

The boy reached out and touched the nearest wall. Instantly, a voice flooded through him — an old man singing a lullaby in a language that had been dead for a thousand years. The melody was achingly beautiful, full of longing for something that could never be recovered.

He pulled his hand away, trembling.

"The city affects everyone differently," the woman observed. "Some people hear their own futures. Others hear the last words of the dead. What did you hear?"

"A song," he said. "A very old song."

She nodded, as if this were the most natural answer in the world. "The songs are the oldest echoes. They last longer than speech, longer than screams. Music is the hardest thing for silence to consume."

They walked deeper into the city. The buildings grew taller, their walls denser with trapped sounds, until they became nearly opaque — dark as smoky quartz. Here and there, light leaked through in places where a particularly powerful echo had burned a hole in the silence, and through these gaps the boy caught glimpses of other places, other times.

"Is this where my mother's book comes from?" he asked.

"The book comes from many places," the woman said. "But yes — some of its pages were written here, in the time before the city fell silent."

"What happened?"

"Someone spoke the wrong word. A word so powerful it consumed every other echo, swallowed every sound, and left only itself behind, repeating endlessly in the empty streets." She paused at a crossroads where four silent avenues met. "That word is still here. Somewhere. Repeating in a whisper. If you listen very carefully, you can almost hear it."

The boy listened. And in the space between one heartbeat and the next, he heard it — a single syllable, soft as a moth's wing, that made the foundations of the city tremble.''',
  },
  {
    'title': 'Chapter 3: The Library at the World\'s Edge',
    'content': '''Beyond the City of Echoes, the landscape changed.

The ground rose in gentle waves, covered in grass so deeply green it was almost black in the shadows. Above, two moons hung in a sky the color of bruised plums — one silver, one faintly gold. Between them, a river of stars flowed like luminous milk, casting enough light to read by.

The boy realized he was still carrying the book. He opened it again, and this time — perhaps because of what the City of Echoes had done to his perception — the characters on the page seemed clearer. Not legible, exactly, but closer to meaning, like a word you know but cannot quite remember.

"We are going to the Library," the woman said. It was not a question.

"What library?"

"The Library at the World's Edge. It sits on the last cliff before the Nothing, and it contains every book that has ever been written — and every book that was ever meant to be written but wasn't. The unwritten books are the most interesting ones. They glow."

They walked for what might have been hours or days. Time moved strangely here, pooling in valleys and rushing over hilltops like wind. Eventually the ground began to rise more steeply, and the boy could see the edge of the world ahead — a clean line where the land simply stopped, and beyond it, a vast and luminous void.

The Library sat on the very lip of the cliff, a building that seemed to have grown rather than been built. Its walls were made of living wood, twisting and braiding into arches and columns. Its windows glowed with the warm light of a thousand reading lamps, and through the open doors he could see shelves stretching away into impossible distances.

"Every book," the boy murmured.

"Every book," the woman confirmed. "Including yours."

He looked at the slim volume in his hands. "My mother's book is in there?"

"Not your mother's book. Yours. The one you haven't written yet." She smiled, and in her smile he saw the desert and the city and the twin moons reflected like memories. "That's why the book brought you here. Not to read it — to finish it."

The Library doors opened wider as they approached, as if the building were breathing them in.''',
  },
];

class ReaderScreen extends StatefulWidget {
  final String bookId;

  const ReaderScreen({super.key, required this.bookId});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  int _currentChapter = 0;
  double _fontSize = 18.0;
  double _brightness = 1.0;
  bool _isScrollMode = true;
  bool _showToolbar = true;
  bool _showSettings = false;
  final ScrollController _scrollController = ScrollController();
  double _readingProgress = 0.0;

  // Selection / highlight state
  String? _selectedText;
  Color _highlightColor = AuroraColors.auroraTeal;

  final _highlightColors = <Color>[
    AuroraColors.auroraTeal,
    AuroraColors.auroraGreen,
    AuroraColors.auroraBlue,
    AuroraColors.auroraPurple,
    AuroraColors.auroraPink,
    AuroraColors.auroraWarm,
  ];

  String get _currentTitle => _mockChapters[_currentChapter]['title']!;
  String get _currentContent => _mockChapters[_currentChapter]['content']!;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateProgress);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateProgress);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateProgress() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll > 0) {
      setState(() {
        _readingProgress = _scrollController.offset / maxScroll;
      });
    }
  }

  void _nextChapter() {
    if (_currentChapter < _mockChapters.length - 1) {
      setState(() {
        _currentChapter++;
        _readingProgress = 0;
      });
      _scrollController.jumpTo(0);
    }
  }

  void _previousChapter() {
    if (_currentChapter > 0) {
      setState(() {
        _currentChapter--;
        _readingProgress = 0;
      });
      _scrollController.jumpTo(0);
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.pageUp) {
      _previousChapter();
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.pageDown) {
      _nextChapter();
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.escape) {
      Navigator.of(context).maybePop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: AuroraColors.deepSpace.withOpacity(_brightness),
        body: SafeArea(
          child: Stack(
            children: [
              // Reading content area
              GestureDetector(
                onTap: () => setState(() => _showToolbar = !_showToolbar),
                child: Column(
                  children: [
                    // Top progress bar
                    _buildProgressBar(),

                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 80),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isMobile ? double.infinity : 720,
                            ),
                            child: SelectableText(
                              _currentContent,
                              style: TextStyle(
                                color: AuroraColors.textPrimary
                                    .withOpacity(0.9 * _brightness),
                                fontSize: _fontSize,
                                height: 1.75,
                                fontFamily: 'Georgia',
                              ),
                              onSelectionChanged: (selection, cause) {
                                if (selection.baseOffset !=
                                    selection.extentOffset) {
                                  final text = _currentContent.substring(
                                    selection.baseOffset,
                                    selection.extentOffset,
                                  );
                                  setState(() => _selectedText = text);
                                } else {
                                  setState(() => _selectedText = null);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Navigation tap zones (left/right thirds)
              if (!_isScrollMode) ...[
                // Left tap zone - previous page
                Positioned(
                  left: 0,
                  top: 60,
                  bottom: 80,
                  width: MediaQuery.of(context).size.width * 0.3,
                  child: GestureDetector(
                    onTap: _previousChapter,
                    behavior: HitTestBehavior.translucent,
                    child: Container(color: Colors.transparent),
                  ),
                ),
                // Right tap zone - next page
                Positioned(
                  right: 0,
                  top: 60,
                  bottom: 80,
                  width: MediaQuery.of(context).size.width * 0.3,
                  child: GestureDetector(
                    onTap: _nextChapter,
                    behavior: HitTestBehavior.translucent,
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ],

              // Top app bar
              if (_showToolbar) _buildTopBar(),

              // Bottom toolbar
              if (_showToolbar) _buildBottomToolbar(),

              // Settings panel
              if (_showSettings) _buildSettingsPanel(),

              // Highlight toolbar (appears when text is selected)
              if (_selectedText != null && _selectedText!.isNotEmpty)
                _buildHighlightToolbar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final totalProgress =
        (_currentChapter + _readingProgress) / _mockChapters.length;
    return Container(
      height: 3,
      width: double.infinity,
      color: AuroraColors.surface,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: totalProgress.clamp(0.0, 1.0),
        child: Container(
          decoration: const BoxDecoration(
            gradient: AuroraColors.accentGradient,
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AuroraColors.deepSpace,
              AuroraColors.deepSpace.withOpacity(0.0),
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: AuroraColors.textPrimary),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AuroraColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Chapter ${_currentChapter + 1} of ${_mockChapters.length}',
                    style: const TextStyle(
                      color: AuroraColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.bookmark_border_rounded,
                  color: AuroraColors.auroraTeal),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.format_list_bulleted_rounded,
                  color: AuroraColors.textSecondary),
              onPressed: () => _showChapterList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomToolbar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              AuroraColors.deepSpace,
              AuroraColors.deepSpace.withOpacity(0.0),
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Previous chapter
            _ToolbarButton(
              icon: Icons.chevron_left_rounded,
              label: 'Prev',
              onTap: _currentChapter > 0 ? _previousChapter : null,
            ),
            // Font size
            _ToolbarButton(
              icon: Icons.text_fields_rounded,
              label: 'Font',
              onTap: () => setState(() => _showSettings = !_showSettings),
            ),
            // Brightness
            _ToolbarButton(
              icon: Icons.brightness_6_rounded,
              label: 'Light',
              onTap: () {
                setState(() {
                  _brightness = _brightness == 1.0 ? 0.7 : 1.0;
                });
              },
            ),
            // Scroll/Page mode
            _ToolbarButton(
              icon: _isScrollMode
                  ? Icons.swap_horiz_rounded
                  : Icons.swap_vert_rounded,
              label: _isScrollMode ? 'Scroll' : 'Page',
              onTap: () => setState(() => _isScrollMode = !_isScrollMode),
            ),
            // Next chapter
            _ToolbarButton(
              icon: Icons.chevron_right_rounded,
              label: 'Next',
              onTap: _currentChapter < _mockChapters.length - 1
                  ? _nextChapter
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return Positioned(
      bottom: 70,
      left: 0,
      right: 0,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AuroraCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Font size
                  Row(
                    children: [
                      const Icon(Icons.text_fields_rounded,
                          color: AuroraColors.auroraTeal, size: 20),
                      const SizedBox(width: 12),
                      const Text('Font Size',
                          style: TextStyle(color: AuroraColors.textPrimary)),
                      const Spacer(),
                      Text(
                        '${_fontSize.toInt()}',
                        style: const TextStyle(
                          color: AuroraColors.auroraTeal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _fontSize,
                    min: 12,
                    max: 32,
                    divisions: 20,
                    onChanged: (v) => setState(() => _fontSize = v),
                  ),
                  const SizedBox(height: 12),

                  // Brightness
                  Row(
                    children: [
                      const Icon(Icons.brightness_6_rounded,
                          color: AuroraColors.auroraTeal, size: 20),
                      const SizedBox(width: 12),
                      const Text('Brightness',
                          style: TextStyle(color: AuroraColors.textPrimary)),
                      const Spacer(),
                      Text(
                        '${(_brightness * 100).toInt()}%',
                        style: const TextStyle(
                          color: AuroraColors.auroraTeal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _brightness,
                    min: 0.3,
                    max: 1.0,
                    divisions: 14,
                    onChanged: (v) => setState(() => _brightness = v),
                  ),
                  const SizedBox(height: 8),

                  // Theme presets
                  const Text('Reading Theme',
                      style: TextStyle(
                          color: AuroraColors.textPrimary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ThemePreset(
                          label: 'Dark',
                          bg: AuroraColors.deepSpace,
                          fg: AuroraColors.textPrimary,
                          isSelected: true),
                      _ThemePreset(
                          label: 'Sepia',
                          bg: const Color(0xFF3B2F1E),
                          fg: const Color(0xFFE8D5B5),
                          isSelected: false),
                      _ThemePreset(
                          label: 'Light',
                          bg: const Color(0xFFF5F5F0),
                          fg: const Color(0xFF2A2A2A),
                          isSelected: false),
                      _ThemePreset(
                          label: 'Green',
                          bg: const Color(0xFF0D2818),
                          fg: const Color(0xFFA8E6C3),
                          isSelected: false),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightToolbar() {
    return Positioned(
      bottom: 70,
      left: 24,
      right: 24,
      child: AuroraCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Color options
            ..._highlightColors.map((color) {
              final isSelected = _highlightColor == color;
              return GestureDetector(
                onTap: () => setState(() => _highlightColor = color),
                child: Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                  ),
                ),
              );
            }),
            const SizedBox(width: 12),
            Container(
              width: 1,
              height: 28,
              color: Colors.white.withOpacity(0.1),
            ),
            const SizedBox(width: 8),
            // Highlight action
            IconButton(
              icon: const Icon(Icons.highlight_rounded,
                  color: AuroraColors.auroraTeal),
              onPressed: () {
                // Create highlight
                setState(() => _selectedText = null);
              },
              tooltip: 'Highlight',
            ),
            // Note action
            IconButton(
              icon: const Icon(Icons.note_add_rounded,
                  color: AuroraColors.auroraBlue),
              onPressed: () {
                // Add note to highlight
                setState(() => _selectedText = null);
              },
              tooltip: 'Add Note',
            ),
            // Copy action
            IconButton(
              icon: const Icon(Icons.copy_rounded,
                  color: AuroraColors.textSecondary),
              onPressed: () {
                setState(() => _selectedText = null);
              },
              tooltip: 'Copy',
            ),
          ],
        ),
      ),
    );
  }

  void _showChapterList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuroraColors.surfaceElevated,
      constraints: BoxConstraints(
        maxWidth: ResponsiveHelper.isMobile(context)
            ? double.infinity
            : 500,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AuroraColors.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chapters',
                style: TextStyle(
                  color: AuroraColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(_mockChapters.length, (index) {
                final isActive = index == _currentChapter;
                return ListTile(
                  leading: Icon(
                    isActive
                        ? Icons.play_circle_fill_rounded
                        : Icons.circle_outlined,
                    color: isActive
                        ? AuroraColors.auroraTeal
                        : AuroraColors.textTertiary,
                    size: 20,
                  ),
                  title: Text(
                    _mockChapters[index]['title']!,
                    style: TextStyle(
                      color: isActive
                          ? AuroraColors.auroraTeal
                          : AuroraColors.textPrimary,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _currentChapter = index;
                      _readingProgress = 0;
                    });
                    _scrollController.jumpTo(0);
                    Navigator.of(context).pop();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ToolbarButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: enabled
                  ? AuroraColors.textPrimary
                  : AuroraColors.textTertiary,
              size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: enabled
                  ? AuroraColors.textSecondary
                  : AuroraColors.textTertiary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemePreset extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final bool isSelected;

  const _ThemePreset({
    required this.label,
    required this.bg,
    required this.fg,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AuroraColors.auroraTeal : Colors.white12,
              width: isSelected ? 2 : 0.5,
            ),
          ),
          child: Center(
            child: Text('Aa', style: TextStyle(color: fg, fontSize: 18)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color:
                isSelected ? AuroraColors.auroraTeal : AuroraColors.textTertiary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
