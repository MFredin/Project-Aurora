import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/aurora_theme.dart';
import '../../core/data/book_repository.dart';
import '../../services/cloud/google_drive_service.dart';
import '../../services/parser/book_parser_service.dart';
import '../../services/logging/error_logger.dart';

final googleDriveServiceProvider = Provider<GoogleDriveService>((ref) {
  final service = GoogleDriveService();
  service.restoreState();
  return service;
});

class DriveFilePicker extends ConsumerStatefulWidget {
  const DriveFilePicker({super.key});

  @override
  ConsumerState<DriveFilePicker> createState() => _DriveFilePickerState();
}

class _DriveFilePickerState extends ConsumerState<DriveFilePicker> {
  List<DriveFile> _files = [];
  bool _loading = true;
  String? _error;
  String? _downloading;

  final List<_FolderEntry> _folderStack = [];
  final _searchController = TextEditingController();
  bool _searching = false;

  String? get _currentFolderId =>
      _folderStack.isNotEmpty ? _folderStack.last.id : null;

  String get _currentFolderName =>
      _folderStack.isNotEmpty ? _folderStack.last.name : 'My Drive';

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final drive = ref.read(googleDriveServiceProvider);
      final result = await drive.listFiles(folderId: _currentFolderId);
      if (mounted) {
        setState(() {
          _files = result.files;
          _loading = false;
        });
      }
    } on DriveException catch (e) {
      ErrorLogger.instance.capture(e, source: 'DriveFilePicker.load');
      if (mounted) setState(() => _error = e.message);
    } catch (e, stack) {
      ErrorLogger.instance.capture(e, stackTrace: stack, source: 'DriveFilePicker.load');
      if (mounted) setState(() => _error = 'Failed to load files.');
    } finally {
      if (mounted && _loading) setState(() => _loading = false);
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      _searching = false;
      _loadFiles();
      return;
    }

    setState(() {
      _searching = true;
      _loading = true;
      _error = null;
    });

    try {
      final drive = ref.read(googleDriveServiceProvider);
      final files = await drive.searchEbooks(query);
      if (mounted) {
        setState(() {
          _files = files;
          _loading = false;
        });
      }
    } on DriveException catch (e) {
      ErrorLogger.instance.capture(e, source: 'DriveFilePicker.search');
      if (mounted) setState(() => _error = e.message);
    } catch (e, stack) {
      ErrorLogger.instance.capture(e, stackTrace: stack, source: 'DriveFilePicker.search');
      if (mounted) setState(() => _error = 'Search failed.');
    } finally {
      if (mounted && _loading) setState(() => _loading = false);
    }
  }

  void _openFolder(DriveFile folder) {
    _folderStack.add(_FolderEntry(id: folder.id, name: folder.name));
    _loadFiles();
  }

  void _goBack() {
    if (_searching) {
      _searchController.clear();
      _searching = false;
      _loadFiles();
      return;
    }
    if (_folderStack.isNotEmpty) {
      _folderStack.removeLast();
      _loadFiles();
    }
  }

  void _goToRoot() {
    _folderStack.clear();
    _searchController.clear();
    _searching = false;
    _loadFiles();
  }

  Future<void> _importFile(DriveFile file) async {
    setState(() => _downloading = file.id);

    try {
      final drive = ref.read(googleDriveServiceProvider);
      final bytes = await drive.downloadFile(file.id);

      final parser = ref.read(bookParserServiceProvider);
      final result = await parser.parseBookFromBytes(bytes, file.name);

      final repo = ref.read(bookRepositoryProvider.notifier);
      repo.addParsedBook(result);

      if (mounted) {
        setState(() => _downloading = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Imported "${result.metadata.title}"',
              style: const TextStyle(color: AuroraColors.textPrimary),
            ),
            backgroundColor: AuroraColors.surfaceElevated,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on DriveException catch (e) {
      ErrorLogger.instance.capture(e, source: 'DriveFilePicker.import');
      if (mounted) {
        setState(() => _downloading = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AuroraColors.auroraWarm.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stack) {
      ErrorLogger.instance.capture(e, stackTrace: stack, source: 'DriveFilePicker.import');
      if (mounted) {
        setState(() => _downloading = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to import file.'),
            backgroundColor: AuroraColors.auroraWarm.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AuroraColors.deepSpace,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          _buildSearchBar(),
          if (_folderStack.isNotEmpty && !_searching) _buildBreadcrumb(),
          const Divider(color: Color(0xFF252E27), height: 1),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: AuroraColors.textTertiary.withOpacity(0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
      child: Row(
        children: [
          if (_folderStack.isNotEmpty || _searching)
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: AuroraColors.textSecondary, size: 22),
              onPressed: _goBack,
            ),
          Expanded(
            child: Text(
              _searching ? 'Search Results' : _currentFolderName,
              style: const TextStyle(
                color: AuroraColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                color: AuroraColors.textSecondary, size: 22),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: AuroraColors.surface.withOpacity(0.75),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF252E27), width: 0.5),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: AuroraColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded,
                color: AuroraColors.textTertiary, size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded,
                        color: AuroraColors.textTertiary, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      _searching = false;
                      _loadFiles();
                    },
                  )
                : null,
            hintText: 'Search ebooks in Drive...',
            hintStyle: const TextStyle(color: AuroraColors.textTertiary, fontSize: 14),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onSubmitted: _search,
          onChanged: (v) => setState(() {}),
        ),
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SizedBox(
        height: 28,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            GestureDetector(
              onTap: _goToRoot,
              child: const Text(
                'My Drive',
                style: TextStyle(
                  color: AuroraColors.auroraTeal,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            for (var i = 0; i < _folderStack.length; i++) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '/',
                  style: TextStyle(color: AuroraColors.textTertiary, fontSize: 12),
                ),
              ),
              GestureDetector(
                onTap: i < _folderStack.length - 1
                    ? () {
                        _folderStack.removeRange(i + 1, _folderStack.length);
                        _loadFiles();
                      }
                    : null,
                child: Text(
                  _folderStack[i].name,
                  style: TextStyle(
                    color: i < _folderStack.length - 1
                        ? AuroraColors.auroraTeal
                        : AuroraColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AuroraColors.auroraTeal,
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AuroraColors.auroraWarm, size: 40),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AuroraColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _loadFiles,
                child: const Text(
                  'Try Again',
                  style: TextStyle(color: AuroraColors.auroraTeal),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_files.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _searching ? Icons.search_off_rounded : Icons.folder_open_rounded,
              color: AuroraColors.textTertiary,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              _searching ? 'No ebooks found' : 'No ebooks in this folder',
              style: const TextStyle(
                color: AuroraColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Supported formats: EPUB, PDF, TXT',
              style: TextStyle(
                color: AuroraColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _files.length,
      separatorBuilder: (_, __) =>
          const Divider(color: Color(0xFF1A201C), height: 1, indent: 64),
      itemBuilder: (context, index) {
        final file = _files[index];
        final isDownloading = _downloading == file.id;

        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: file.isFolder
                  ? AuroraColors.auroraBlue.withOpacity(0.15)
                  : AuroraColors.auroraTeal.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              file.isFolder
                  ? Icons.folder_rounded
                  : _iconForFile(file),
              color: file.isFolder
                  ? AuroraColors.auroraBlue
                  : AuroraColors.auroraTeal,
              size: 22,
            ),
          ),
          title: Text(
            file.name,
            style: const TextStyle(
              color: AuroraColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: file.isFolder
              ? null
              : Text(
                  '${file.sizeLabel}${file.modifiedTime != null ? '  •  ${_formatDate(file.modifiedTime!)}' : ''}',
                  style: const TextStyle(
                    color: AuroraColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
          trailing: file.isFolder
              ? const Icon(Icons.chevron_right_rounded,
                  color: AuroraColors.textTertiary, size: 20)
              : isDownloading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AuroraColors.auroraTeal,
                      ),
                    )
                  : const Icon(Icons.download_rounded,
                      color: AuroraColors.auroraTeal, size: 20),
          onTap: isDownloading
              ? null
              : file.isFolder
                  ? () => _openFolder(file)
                  : () => _importFile(file),
        );
      },
    );
  }

  IconData _iconForFile(DriveFile file) {
    switch (file.extension) {
      case 'epub':
        return Icons.menu_book_rounded;
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'txt':
        return Icons.text_snippet_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _FolderEntry {
  final String id;
  final String name;
  const _FolderEntry({required this.id, required this.name});
}
