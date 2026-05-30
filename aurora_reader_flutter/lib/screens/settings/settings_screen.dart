import 'package:flutter/material.dart';
import '../../core/layout/responsive.dart';
import '../../core/theme/aurora_theme.dart';
import '../../core/theme/aurora_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = true;
  bool _notifications = true;
  bool _haptics = true;
  bool _autoSync = true;
  double _dailyGoal = 30;
  String _defaultFont = 'Georgia';

  final _fonts = ['Georgia', 'Palatino', 'San Francisco', 'OpenDyslexic', 'Merriweather'];

  @override
  Widget build(BuildContext context) {
    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
              const Text(
                'Settings',
                style: TextStyle(
                  color: AuroraColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Reading section
              _buildSectionHeader('READING'),
              const SizedBox(height: 8),
              AuroraCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildSettingsRow(
                      icon: Icons.text_fields_rounded,
                      label: 'Default Font',
                      trailing: DropdownButton<String>(
                        value: _defaultFont,
                        dropdownColor: AuroraColors.surfaceElevated,
                        style: const TextStyle(
                          color: AuroraColors.textPrimary,
                          fontSize: 14,
                        ),
                        underline: const SizedBox(),
                        items: _fonts
                            .map((f) => DropdownMenuItem(
                                  value: f,
                                  child: Text(f),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _defaultFont = v);
                        },
                      ),
                    ),
                    _divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.flag_rounded,
                              color: AuroraColors.auroraTeal, size: 22),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Daily Reading Goal',
                              style: TextStyle(color: AuroraColors.textPrimary),
                            ),
                          ),
                          Text(
                            '${_dailyGoal.toInt()} min',
                            style: const TextStyle(
                              color: AuroraColors.auroraTeal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Slider(
                      value: _dailyGoal,
                      min: 5,
                      max: 120,
                      divisions: 23,
                      onChanged: (v) => setState(() => _dailyGoal = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Appearance section
              _buildSectionHeader('APPEARANCE'),
              const SizedBox(height: 8),
              AuroraCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildToggleRow(
                      icon: Icons.dark_mode_rounded,
                      label: 'Dark Mode',
                      value: _darkMode,
                      onChanged: (v) => setState(() => _darkMode = v),
                    ),
                    _divider(),
                    _buildToggleRow(
                      icon: Icons.vibration_rounded,
                      label: 'Haptic Feedback',
                      value: _haptics,
                      onChanged: (v) => setState(() => _haptics = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Sync section
              _buildSectionHeader('SYNC & BACKUP'),
              const SizedBox(height: 8),
              AuroraCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildToggleRow(
                      icon: Icons.sync_rounded,
                      label: 'Auto Sync',
                      value: _autoSync,
                      onChanged: (v) => setState(() => _autoSync = v),
                    ),
                    _divider(),
                    _buildToggleRow(
                      icon: Icons.notifications_rounded,
                      label: 'Notifications',
                      value: _notifications,
                      onChanged: (v) => setState(() => _notifications = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Data section
              _buildSectionHeader('DATA'),
              const SizedBox(height: 8),
              AuroraCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildNavRow(
                      icon: Icons.file_download_rounded,
                      label: 'Export Library Data',
                      onTap: () {
                        // Navigate to export screen
                      },
                    ),
                    _divider(),
                    _buildNavRow(
                      icon: Icons.delete_outline_rounded,
                      label: 'Clear Cache',
                      subtitle: '12.4 MB',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // AI section
              _buildSectionHeader('AI COMPANION'),
              const SizedBox(height: 8),
              AuroraCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildNavRow(
                      icon: Icons.key_rounded,
                      label: 'API Key',
                      subtitle: 'Configure Anthropic API key',
                      onTap: () => _showApiKeyDialog(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // About section
              _buildSectionHeader('ABOUT'),
              const SizedBox(height: 8),
              AuroraCard(
                child: Column(
                  children: [
                    SizedBox(
                      width: 48,
                      height: 52,
                      child: CustomPaint(
                        painter: _RunicKnotPainter(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'EDDA',
                      style: TextStyle(
                        color: AuroraColors.auroraTeal,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 6,
                        fontFamily: 'Georgia',
                      ),
                    ),
                    const Text(
                      'Version 4.0.0',
                      style: TextStyle(
                        color: AuroraColors.textTertiary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Built with Flutter',
                      style: TextStyle(
                        color: AuroraColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AuroraColors.textTertiary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AuroraColors.auroraTeal, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(color: AuroraColors.textPrimary)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AuroraColors.auroraTeal,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required String label,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AuroraColors.auroraTeal, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(color: AuroraColors.textPrimary)),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildNavRow({
    required IconData icon,
    required String label,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AuroraColors.auroraTeal, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                          const TextStyle(color: AuroraColors.textPrimary)),
                  if (subtitle != null)
                    Text(subtitle,
                        style: const TextStyle(
                            color: AuroraColors.textTertiary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AuroraColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      indent: 50,
      color: const Color(0xFF252E27).withOpacity(0.6),
    );
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AuroraColors.surfaceElevated,
        title: const Text('Anthropic API Key',
            style: TextStyle(color: AuroraColors.textPrimary)),
        content: TextField(
          controller: controller,
          obscureText: true,
          style: const TextStyle(color: AuroraColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'sk-ant-...',
            hintStyle: TextStyle(color: AuroraColors.textTertiary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Save API key to secure storage
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _RunicKnotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final ember = Paint()
      ..color = AuroraColors.auroraTeal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final lichen = Paint()
      ..color = AuroraColors.auroraGreen.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // The "E" is built from interlaced strokes:
    // A vertical spine with three horizontal arms that weave over/under

    // Vertical spine of E
    final spine = Path()
      ..moveTo(w * 0.2, h * 0.05)
      ..lineTo(w * 0.2, h * 0.95);
    canvas.drawPath(spine, ember);

    // Top arm — curves slightly upward at the end
    final topArm = Path()
      ..moveTo(w * 0.2, h * 0.05)
      ..cubicTo(w * 0.5, h * 0.05, w * 0.65, h * 0.0, w * 0.85, h * 0.08)
      ..cubicTo(w * 0.92, h * 0.11, w * 0.88, h * 0.20, w * 0.78, h * 0.18);
    canvas.drawPath(topArm, ember);

    // Middle arm — the interlace crossover
    final midArm = Path()
      ..moveTo(w * 0.2, h * 0.48)
      ..cubicTo(w * 0.45, h * 0.48, w * 0.55, h * 0.42, w * 0.72, h * 0.45)
      ..cubicTo(w * 0.82, h * 0.47, w * 0.80, h * 0.55, w * 0.68, h * 0.53);
    canvas.drawPath(midArm, ember);

    // Bottom arm
    final botArm = Path()
      ..moveTo(w * 0.2, h * 0.95)
      ..cubicTo(w * 0.5, h * 0.95, w * 0.65, h * 1.0, w * 0.85, h * 0.92)
      ..cubicTo(w * 0.92, h * 0.89, w * 0.88, h * 0.80, w * 0.78, h * 0.82);
    canvas.drawPath(botArm, ember);

    // Interlace weave loops — small loops at the arm terminals
    // Top loop
    final topLoop = Path()
      ..moveTo(w * 0.78, h * 0.18)
      ..cubicTo(w * 0.68, h * 0.16, w * 0.65, h * 0.22, w * 0.72, h * 0.25)
      ..cubicTo(w * 0.80, h * 0.28, w * 0.85, h * 0.22, w * 0.78, h * 0.18);
    canvas.drawPath(topLoop, lichen);

    // Middle loop
    final midLoop = Path()
      ..moveTo(w * 0.68, h * 0.53)
      ..cubicTo(w * 0.58, h * 0.51, w * 0.55, h * 0.57, w * 0.62, h * 0.60)
      ..cubicTo(w * 0.70, h * 0.63, w * 0.75, h * 0.57, w * 0.68, h * 0.53);
    canvas.drawPath(midLoop, lichen);

    // Bottom loop
    final botLoop = Path()
      ..moveTo(w * 0.78, h * 0.82)
      ..cubicTo(w * 0.68, h * 0.84, w * 0.65, h * 0.78, w * 0.72, h * 0.75)
      ..cubicTo(w * 0.80, h * 0.72, w * 0.85, h * 0.78, w * 0.78, h * 0.82);
    canvas.drawPath(botLoop, lichen);

    // Knot terminals — small dots at spine endpoints
    final dot = Paint()..color = AuroraColors.auroraTeal;
    canvas.drawCircle(Offset(w * 0.2, h * 0.03), 2.5, dot);
    canvas.drawCircle(Offset(w * 0.2, h * 0.97), 2.5, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
