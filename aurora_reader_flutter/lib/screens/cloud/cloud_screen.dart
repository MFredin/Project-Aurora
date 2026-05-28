import 'package:flutter/material.dart';
import '../../core/layout/responsive.dart';
import '../../core/theme/aurora_theme.dart';
import '../../core/theme/aurora_widgets.dart';

/// Cloud storage and sync management screen.
class CloudScreen extends StatefulWidget {
  const CloudScreen({super.key});

  @override
  State<CloudScreen> createState() => _CloudScreenState();
}

class _CloudScreenState extends State<CloudScreen> {
  bool _googleDriveConnected = false;
  bool _dropboxConnected = false;
  bool _iCloudSyncEnabled = true;
  bool _isSyncing = false;

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
                'Cloud',
                style: TextStyle(
                  color: AuroraColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Sync your library across devices',
                style: TextStyle(
                  color: AuroraColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // Sync status card
              AuroraCard(
                child: Column(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AuroraColors.accentGradient.createShader(bounds),
                      child: const Icon(Icons.cloud_done_rounded,
                          size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'All synced',
                      style: TextStyle(
                        color: AuroraColors.auroraGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Last synced: 5 minutes ago',
                      style: TextStyle(
                        color: AuroraColors.textTertiary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AuroraButton(
                      label: _isSyncing ? 'Syncing...' : 'Sync Now',
                      icon: Icons.sync_rounded,
                      onPressed: _isSyncing
                          ? null
                          : () {
                              setState(() => _isSyncing = true);
                              Future.delayed(const Duration(seconds: 2), () {
                                if (mounted) setState(() => _isSyncing = false);
                              });
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // iCloud Sync
              const Text(
                'DEVICE SYNC',
                style: TextStyle(
                  color: AuroraColors.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              AuroraCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AuroraColors.auroraBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.cloud_sync_rounded,
                          color: AuroraColors.auroraBlue, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cross-Device Sync',
                            style: TextStyle(
                              color: AuroraColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Reading progress, bookmarks, highlights',
                            style: TextStyle(
                              color: AuroraColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _iCloudSyncEnabled,
                      onChanged: (v) => setState(() => _iCloudSyncEnabled = v),
                      activeColor: AuroraColors.auroraTeal,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Cloud Storage
              const Text(
                'CLOUD STORAGE',
                style: TextStyle(
                  color: AuroraColors.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),

              // Google Drive
              _buildCloudProvider(
                icon: Icons.cloud_outlined,
                name: 'Google Drive',
                description: 'Import books from Google Drive',
                color: AuroraColors.auroraBlue,
                connected: _googleDriveConnected,
                onToggle: () => setState(
                    () => _googleDriveConnected = !_googleDriveConnected),
              ),
              const SizedBox(height: 8),

              // Dropbox
              _buildCloudProvider(
                icon: Icons.cloud_circle_outlined,
                name: 'Dropbox',
                description: 'Import books from Dropbox',
                color: AuroraColors.auroraTeal,
                connected: _dropboxConnected,
                onToggle: () =>
                    setState(() => _dropboxConnected = !_dropboxConnected),
              ),
              const SizedBox(height: 24),

              // Storage usage
              const Text(
                'STORAGE',
                style: TextStyle(
                  color: AuroraColors.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              AuroraCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Local Storage',
                          style: TextStyle(
                            color: AuroraColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '247 MB used',
                          style: TextStyle(
                            color: AuroraColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 0.12,
                        minHeight: 6,
                        backgroundColor: AuroraColors.surface,
                        valueColor: const AlwaysStoppedAnimation(
                            AuroraColors.auroraTeal),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        _StorageLegend(
                            color: AuroraColors.auroraTeal, label: 'Books'),
                        SizedBox(width: 16),
                        _StorageLegend(
                            color: AuroraColors.auroraPurple, label: 'Cache'),
                        SizedBox(width: 16),
                        _StorageLegend(
                            color: AuroraColors.auroraWarm, label: 'Data'),
                      ],
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

  Widget _buildCloudProvider({
    required IconData icon,
    required String name,
    required String description,
    required Color color,
    required bool connected,
    required VoidCallback onToggle,
  }) {
    return AuroraCard(
      padding: const EdgeInsets.all(16),
      onTap: onToggle,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AuroraColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    color: AuroraColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: connected
                  ? AuroraColors.auroraGreen.withOpacity(0.15)
                  : AuroraColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              connected ? 'Connected' : 'Connect',
              style: TextStyle(
                color: connected
                    ? AuroraColors.auroraGreen
                    : AuroraColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StorageLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _StorageLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AuroraColors.textTertiary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
