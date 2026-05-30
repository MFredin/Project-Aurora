import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/aurora_theme.dart';
import '../../core/theme/aurora_widgets.dart';
import '../../services/cloud/google_drive_service.dart';
import '../../services/logging/error_logger.dart';
import 'drive_file_picker.dart';

class CloudScreen extends ConsumerStatefulWidget {
  const CloudScreen({super.key});

  @override
  ConsumerState<CloudScreen> createState() => _CloudScreenState();
}

class _CloudScreenState extends ConsumerState<CloudScreen> {
  bool _driveConnecting = false;
  String? _error;

  bool get _driveConnected =>
      ref.read(googleDriveServiceProvider).isConnected;

  Future<void> _connectGoogleDrive() async {
    setState(() {
      _driveConnecting = true;
      _error = null;
    });

    try {
      final drive = ref.read(googleDriveServiceProvider);
      await drive.connect();
      if (mounted) setState(() => _driveConnecting = false);
    } on DriveException catch (e) {
      ErrorLogger.instance.capture(e, source: 'CloudScreen.connectDrive');
      if (mounted) {
        setState(() {
          _driveConnecting = false;
          _error = e.message;
        });
      }
    } catch (e, stack) {
      ErrorLogger.instance.capture(e, stackTrace: stack, source: 'CloudScreen.connectDrive');
      if (mounted) {
        setState(() {
          _driveConnecting = false;
          _error = 'Drive connection failed: $e';
        });
      }
    }
  }

  Future<void> _disconnectGoogleDrive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AuroraColors.surfaceElevated,
        title: const Text(
          'Disconnect Google Drive?',
          style: TextStyle(color: AuroraColors.textPrimary, fontSize: 16),
        ),
        content: const Text(
          'Your imported books will remain in your library.',
          style: TextStyle(color: AuroraColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AuroraColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Disconnect',
                style: TextStyle(color: AuroraColors.auroraWarm)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final drive = ref.read(googleDriveServiceProvider);
      await drive.disconnect();
      if (mounted) setState(() {});
    }
  }

  void _openDriveFilePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DriveFilePicker(),
    );
  }

  void _onGoogleDriveTap() {
    if (_driveConnecting) return;
    if (_driveConnected) {
      _openDriveFilePicker();
    } else {
      _connectGoogleDrive();
    }
  }

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
                    'Import books from cloud storage',
                    style: TextStyle(
                      color: AuroraColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_error != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AuroraColors.auroraWarm.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AuroraColors.auroraWarm.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: AuroraColors.auroraWarm, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: AuroraColors.auroraWarm,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _error = null),
                            child: const Icon(Icons.close_rounded,
                                color: AuroraColors.auroraWarm, size: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

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

                  _buildGoogleDriveCard(),
                  const SizedBox(height: 8),

                  _buildCloudProvider(
                    icon: Icons.cloud_circle_outlined,
                    name: 'Dropbox',
                    description: 'Coming soon',
                    color: AuroraColors.auroraBlue,
                    connected: false,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Dropbox integration coming in a future update.',
                            style: TextStyle(color: AuroraColors.textPrimary),
                          ),
                          backgroundColor: AuroraColors.surfaceElevated,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  if (_driveConnected) ...[
                    const Text(
                      'IMPORT',
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
                      onTap: _openDriveFilePicker,
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AuroraColors.auroraTeal.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.file_download_rounded,
                                color: AuroraColors.auroraTeal, size: 24),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Browse Google Drive',
                                  style: TextStyle(
                                    color: AuroraColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Find and import EPUB, PDF, or TXT files',
                                  style: TextStyle(
                                    color: AuroraColors.textTertiary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: AuroraColors.textTertiary, size: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  const Text(
                    'ABOUT',
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
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: AuroraColors.textTertiary, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              'How it works',
                              style: TextStyle(
                                color: AuroraColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Connect your Google Drive to browse and import ebooks directly into your Edda library. '
                          'Files are downloaded and stored locally on your device. '
                          'Edda only requests read-only access to your Drive.',
                          style: TextStyle(
                            color: AuroraColors.textTertiary,
                            fontSize: 13,
                            height: 1.5,
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

  Widget _buildGoogleDriveCard() {
    return AuroraCard(
      padding: const EdgeInsets.all(16),
      onTap: _onGoogleDriveTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AuroraColors.auroraGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.cloud_outlined,
                color: AuroraColors.auroraGreen, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Google Drive',
                  style: TextStyle(
                    color: AuroraColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _driveConnected
                      ? 'Tap to browse and import ebooks'
                      : 'Import books from Google Drive',
                  style: const TextStyle(
                    color: AuroraColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (_driveConnecting)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AuroraColors.auroraTeal,
              ),
            )
          else if (_driveConnected)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AuroraColors.auroraGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Connected',
                    style: TextStyle(
                      color: AuroraColors.auroraGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: _disconnectGoogleDrive,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.link_off_rounded,
                        color: AuroraColors.textTertiary, size: 16),
                  ),
                ),
              ],
            )
          else
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AuroraColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Connect',
                style: TextStyle(
                  color: AuroraColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCloudProvider({
    required IconData icon,
    required String name,
    required String description,
    required Color color,
    required bool connected,
    required VoidCallback onTap,
  }) {
    return AuroraCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
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
              color: AuroraColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              connected ? 'Connected' : 'Connect',
              style: TextStyle(
                color: connected
                    ? AuroraColors.auroraGreen
                    : AuroraColors.textTertiary,
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

