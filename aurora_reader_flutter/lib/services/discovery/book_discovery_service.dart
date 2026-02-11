import 'package:dio/dio.dart';

/// Discovers and searches for books via Open Library and Google Books APIs.
///
/// Provides search, trending lists, recommendations, and metadata lookup
/// for books the user might want to add to their library.
class BookDiscoveryService {
  final Dio _dio = Dio();

  static const _openLibraryBase = 'https://openlibrary.org';
  static const _googleBooksBase = 'https://www.googleapis.com/books/v1';

  /// Search Open Library for books matching [query].
  Future<List<DiscoveredBook>> search(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final response = await _dio.get(
        '$_openLibraryBase/search.json',
        queryParameters: {'q': query, 'limit': 20},
      );

      final docs = response.data['docs'] as List? ?? [];
      return docs.map((doc) {
        final coverId = doc['cover_i'];
        return DiscoveredBook(
          title: doc['title'] ?? 'Unknown Title',
          author: (doc['author_name'] as List?)?.firstOrNull?.toString() ??
              'Unknown Author',
          isbn: (doc['isbn'] as List?)?.firstOrNull?.toString(),
          coverUrl: coverId != null
              ? 'https://covers.openlibrary.org/b/id/$coverId-M.jpg'
              : null,
          publishYear: doc['first_publish_year']?.toString(),
          openLibraryKey: doc['key']?.toString(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Get trending / popular books.
  Future<List<DiscoveredBook>> getTrending() async {
    try {
      final response = await _dio.get(
        '$_openLibraryBase/trending/daily.json',
        queryParameters: {'limit': 20},
      );

      final works = response.data['works'] as List? ?? [];
      return works.map((work) {
        final coverId = work['cover_i'];
        return DiscoveredBook(
          title: work['title'] ?? 'Unknown Title',
          author: work['author_name']?.toString() ?? 'Unknown Author',
          coverUrl: coverId != null
              ? 'https://covers.openlibrary.org/b/id/$coverId-M.jpg'
              : null,
          openLibraryKey: work['key']?.toString(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Look up detailed book info by ISBN via Google Books.
  Future<DiscoveredBook?> lookupByIsbn(String isbn) async {
    try {
      final response = await _dio.get(
        '$_googleBooksBase/volumes',
        queryParameters: {'q': 'isbn:$isbn'},
      );

      final items = response.data['items'] as List?;
      if (items == null || items.isEmpty) return null;

      final info = items.first['volumeInfo'];
      return DiscoveredBook(
        title: info['title'] ?? 'Unknown Title',
        author: (info['authors'] as List?)?.join(', ') ?? 'Unknown Author',
        isbn: isbn,
        coverUrl: info['imageLinks']?['thumbnail'],
        publishYear: info['publishedDate'],
        description: info['description'],
        pageCount: info['pageCount'],
      );
    } catch (_) {
      return null;
    }
  }
}

/// A book discovered from an external API (not yet in the user's library).
class DiscoveredBook {
  final String title;
  final String author;
  final String? isbn;
  final String? coverUrl;
  final String? publishYear;
  final String? openLibraryKey;
  final String? description;
  final int? pageCount;

  const DiscoveredBook({
    required this.title,
    required this.author,
    this.isbn,
    this.coverUrl,
    this.publishYear,
    this.openLibraryKey,
    this.description,
    this.pageCount,
  });
}
