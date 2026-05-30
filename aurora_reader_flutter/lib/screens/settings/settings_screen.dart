import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/layout/responsive.dart';
import '../../core/theme/aurora_theme.dart';
import '../../core/theme/aurora_widgets.dart';
import '../../services/ai/llm_provider.dart';
import '../../services/auth/auth_service.dart';
import '../../providers/service_providers.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
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

              // Account section
              _buildSectionHeader('ACCOUNT'),
              const SizedBox(height: 8),
              _buildAccountCard(),
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
              _buildAiCompanionCard(),
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

  Widget _buildAccountCard() {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return AuroraCard(
        padding: EdgeInsets.zero,
        child: _buildNavRow(
          icon: Icons.login_rounded,
          label: 'Sign In',
          subtitle: 'Sign in to sync your library across devices',
          onTap: () => context.go('/login'),
        ),
      );
    }

    return AuroraCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AuroraColors.accentGradient,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    (user.displayName ?? user.email)
                        .substring(0, 1)
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFFF0E8D8),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (user.displayName != null &&
                          user.displayName!.isNotEmpty)
                        Text(
                          user.displayName!,
                          style: const TextStyle(
                            color: AuroraColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      Text(
                        user.email,
                        style: const TextStyle(
                          color: AuroraColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _divider(),
          _buildNavRow(
            icon: Icons.edit_rounded,
            label: 'Edit Display Name',
            onTap: () => _showEditNameDialog(user),
          ),
          _divider(),
          InkWell(
            onTap: _confirmSignOut,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.logout_rounded,
                      color: AuroraColors.auroraWarm, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    'Sign Out',
                    style: TextStyle(color: AuroraColors.auroraWarm),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog(AuthUser user) {
    final controller =
        TextEditingController(text: user.displayName ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AuroraColors.surfaceElevated,
        title: const Text('Display Name',
            style: TextStyle(color: AuroraColors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AuroraColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Enter your name',
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
              ref
                  .read(authServiceProvider)
                  .updateDisplayName(controller.text);
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AuroraColors.surfaceElevated,
        title: const Text('Sign Out',
            style: TextStyle(color: AuroraColors.textPrimary)),
        content: const Text(
          'Your local data will be preserved. You can sign back in anytime.',
          style: TextStyle(color: AuroraColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authServiceProvider).signOut();
              if (mounted) context.go('/login');
            },
            child: Text('Sign Out',
                style: TextStyle(color: AuroraColors.auroraWarm)),
          ),
        ],
      ),
    );
  }

  Widget _buildAiCompanionCard() {
    final config = ref.watch(llmConfigProvider);
    final notifier = ref.read(llmConfigProvider.notifier);

    return AuroraCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildSettingsRow(
            icon: Icons.smart_toy_rounded,
            label: 'Provider',
            trailing: DropdownButton<LlmProviderType>(
              value: config.provider,
              dropdownColor: AuroraColors.surfaceElevated,
              style: const TextStyle(
                color: AuroraColors.textPrimary,
                fontSize: 14,
              ),
              underline: const SizedBox(),
              items: LlmProviderType.values
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.displayName),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) notifier.setProvider(v);
              },
            ),
          ),
          _divider(),
          _buildSettingsRow(
            icon: Icons.psychology_rounded,
            label: 'Model',
            trailing: DropdownButton<String>(
              value: config.provider.availableModels.contains(config.activeModel)
                  ? config.activeModel
                  : config.provider.defaultModel,
              dropdownColor: AuroraColors.surfaceElevated,
              style: const TextStyle(
                color: AuroraColors.textPrimary,
                fontSize: 14,
              ),
              underline: const SizedBox(),
              items: config.provider.availableModels
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) notifier.setModel(v);
              },
            ),
          ),
          _divider(),
          _buildNavRow(
            icon: Icons.key_rounded,
            label: 'API Key',
            subtitle: config.isConfigured
                ? '${config.provider.displayName} key saved'
                : 'Not configured',
            onTap: () => _showApiKeyDialog(config, notifier),
          ),
          _divider(),
          _buildNavRow(
            icon: Icons.menu_book_rounded,
            label: 'Setup Guide',
            subtitle: 'How to get your API key and connect',
            onTap: () => context.push('/ai-setup'),
          ),
        ],
      ),
    );
  }

  void _showApiKeyDialog(LlmConfig config, LlmConfigNotifier notifier) {
    final controller = TextEditingController(text: config.apiKey ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AuroraColors.surfaceElevated,
        title: Text('${config.provider.displayName} API Key',
            style: const TextStyle(color: AuroraColors.textPrimary)),
        content: TextField(
          controller: controller,
          obscureText: true,
          style: const TextStyle(color: AuroraColors.textPrimary),
          decoration: InputDecoration(
            hintText: config.provider.apiKeyHint,
            hintStyle: const TextStyle(color: AuroraColors.textTertiary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              notifier.setApiKey(controller.text.trim());
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
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;

    final lichen = Paint()
      ..color = AuroraColors.auroraGreen.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;

    final cx = w * 0.5;
    final top = h * 0.0;
    final bot = h * 1.0;
    final mid = h * 0.5;

    canvas.drawLine(Offset(cx, top), Offset(cx, bot), ember);

    final dRight = w * 0.95;
    canvas.drawLine(Offset(cx, top), Offset(dRight, mid), lichen);
    canvas.drawLine(Offset(dRight, mid), Offset(cx, bot), lichen);
    canvas.drawLine(Offset(cx, top), Offset(w * 0.05, mid), lichen);
    canvas.drawLine(Offset(w * 0.05, mid), Offset(cx, bot), lichen);

    final eTop = h * 0.22;
    final eMid = h * 0.38;
    final eBot = h * 0.54;
    final eRight = w * 0.82;
    canvas.drawLine(Offset(cx, eTop), Offset(eRight, eMid), ember);
    canvas.drawLine(Offset(eRight, eMid), Offset(cx, eBot), ember);

    final serifW = w * 0.12;
    final serifPaint = Paint()
      ..color = AuroraColors.auroraTeal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(Offset(cx - serifW, top), Offset(cx + serifW, top), serifPaint);
    canvas.drawLine(Offset(cx - serifW, bot), Offset(cx + serifW, bot), serifPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
