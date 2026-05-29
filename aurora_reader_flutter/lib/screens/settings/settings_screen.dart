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
                      width: 80,
                      height: 90,
                      child: CustomPaint(
                        painter: _StaveArchLogoPainter(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'EDDA',
                      style: TextStyle(
                        color: AuroraColors.auroraTeal,
                        fontSize: 22,
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

class _StaveArchLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final ember = Paint()
      ..color = AuroraColors.auroraTeal.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final page = Paint()
      ..color = AuroraColors.textPrimary.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final archPath = Path()
      ..moveTo(cx, 0)
      ..lineTo(size.width * 0.1, size.height * 0.38)
      ..lineTo(size.width * 0.1, size.height * 0.88)
      ..moveTo(cx, 0)
      ..lineTo(size.width * 0.9, size.height * 0.38)
      ..lineTo(size.width * 0.9, size.height * 0.88);
    canvas.drawPath(archPath, ember);

    final leftPage = Path()
      ..moveTo(size.width * 0.25, size.height * 0.45)
      ..lineTo(size.width * 0.25, size.height * 0.80)
      ..quadraticBezierTo(cx, size.height * 0.74, cx, size.height * 0.82);
    canvas.drawPath(leftPage, page);

    final rightPage = Path()
      ..moveTo(size.width * 0.75, size.height * 0.45)
      ..lineTo(size.width * 0.75, size.height * 0.80)
      ..quadraticBezierTo(cx, size.height * 0.74, cx, size.height * 0.82);
    canvas.drawPath(rightPage, page);

    final spine = Paint()
      ..color = AuroraColors.textPrimary.withOpacity(0.15)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(cx, size.height * 0.43),
      Offset(cx, size.height * 0.80),
      spine,
    );

    final linePaint = Paint()
      ..color = AuroraColors.manuscriptGold.withOpacity(0.25)
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = size.height * (0.54 + i * 0.08);
      final vary = (i % 2 == 0) ? 0.0 : 3.0;
      canvas.drawLine(Offset(size.width * 0.32, y), Offset(cx - 4 - vary, y), linePaint);
      canvas.drawLine(Offset(cx + 4, y), Offset(size.width * 0.68 + vary, y), linePaint);
    }

    final spark = Paint()..color = AuroraColors.auroraTeal.withOpacity(0.6);
    canvas.drawCircle(Offset(cx, -1), 2.5, spark);

    final knot = Paint()
      ..color = AuroraColors.auroraGreen.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.88), 3, knot);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.88), 3, knot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
