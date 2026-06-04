import 'dart:convert';

class UserProfileModel {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final int booksRead;
  final int followers;
  final int following;
  final DateTime joinedDate;
  final bool isFollowing;

  const UserProfileModel({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.booksRead = 0,
    this.followers = 0,
    this.following = 0,
    required this.joinedDate,
    this.isFollowing = false,
  });

  UserProfileModel copyWith({
    String? displayName,
    String? avatarUrl,
    int? booksRead,
    int? followers,
    int? following,
    bool? isFollowing,
  }) {
    return UserProfileModel(
      id: id,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      booksRead: booksRead ?? this.booksRead,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      joinedDate: joinedDate,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'booksRead': booksRead,
        'followers': followers,
        'following': following,
        'joinedDate': joinedDate.toIso8601String(),
        'isFollowing': isFollowing,
      };

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      UserProfileModel(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        booksRead: json['booksRead'] as int? ?? 0,
        followers: json['followers'] as int? ?? 0,
        following: json['following'] as int? ?? 0,
        joinedDate: DateTime.parse(json['joinedDate'] as String),
        isFollowing: json['isFollowing'] as bool? ?? false,
      );
}

class ActivityFeedItem {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final ActivityType type;
  final String bookTitle;
  final String? bookAuthor;
  final String? detail;
  final DateTime timestamp;

  const ActivityFeedItem({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.type,
    required this.bookTitle,
    this.bookAuthor,
    this.detail,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'type': type.name,
        'bookTitle': bookTitle,
        'bookAuthor': bookAuthor,
        'detail': detail,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ActivityFeedItem.fromJson(Map<String, dynamic> json) =>
      ActivityFeedItem(
        id: json['id'] as String,
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        userAvatar: json['userAvatar'] as String?,
        type: ActivityType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => ActivityType.startedBook,
        ),
        bookTitle: json['bookTitle'] as String,
        bookAuthor: json['bookAuthor'] as String?,
        detail: json['detail'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

enum ActivityType {
  finishedBook,
  startedBook,
  ratedBook,
  reviewedBook,
  addedToShelf,
  highlight;

  String get label {
    switch (this) {
      case ActivityType.finishedBook:
        return 'finished reading';
      case ActivityType.startedBook:
        return 'started reading';
      case ActivityType.ratedBook:
        return 'rated';
      case ActivityType.reviewedBook:
        return 'reviewed';
      case ActivityType.addedToShelf:
        return 'added to shelf';
      case ActivityType.highlight:
        return 'highlighted a passage in';
    }
  }

  String get icon {
    switch (this) {
      case ActivityType.finishedBook:
        return 'check_circle';
      case ActivityType.startedBook:
        return 'auto_stories';
      case ActivityType.ratedBook:
        return 'star';
      case ActivityType.reviewedBook:
        return 'rate_review';
      case ActivityType.addedToShelf:
        return 'bookmark_add';
      case ActivityType.highlight:
        return 'format_quote';
    }
  }
}

class BookClubModel {
  final String id;
  final String name;
  final String description;
  final String creatorId;
  final List<String> memberIds;
  final int memberCount;
  final String? currentBookTitle;
  final String? currentBookAuthor;
  final BookClubSchedule? schedule;
  final DateTime createdAt;
  final String? imageUrl;

  const BookClubModel({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    this.memberIds = const [],
    this.memberCount = 0,
    this.currentBookTitle,
    this.currentBookAuthor,
    this.schedule,
    required this.createdAt,
    this.imageUrl,
  });

  BookClubModel copyWith({
    String? name,
    String? description,
    List<String>? memberIds,
    int? memberCount,
    String? Function()? currentBookTitle,
    String? Function()? currentBookAuthor,
    BookClubSchedule? Function()? schedule,
    String? Function()? imageUrl,
  }) {
    return BookClubModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      creatorId: creatorId,
      memberIds: memberIds ?? this.memberIds,
      memberCount: memberCount ?? this.memberCount,
      currentBookTitle: currentBookTitle != null
          ? currentBookTitle()
          : this.currentBookTitle,
      currentBookAuthor: currentBookAuthor != null
          ? currentBookAuthor()
          : this.currentBookAuthor,
      schedule: schedule != null ? schedule() : this.schedule,
      createdAt: createdAt,
      imageUrl: imageUrl != null ? imageUrl() : this.imageUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'creatorId': creatorId,
        'memberIds': memberIds,
        'memberCount': memberCount,
        'currentBookTitle': currentBookTitle,
        'currentBookAuthor': currentBookAuthor,
        'schedule': schedule?.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'imageUrl': imageUrl,
      };

  factory BookClubModel.fromJson(Map<String, dynamic> json) => BookClubModel(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        creatorId: json['creatorId'] as String,
        memberIds: (json['memberIds'] as List?)?.cast<String>() ?? [],
        memberCount: json['memberCount'] as int? ?? 0,
        currentBookTitle: json['currentBookTitle'] as String?,
        currentBookAuthor: json['currentBookAuthor'] as String?,
        schedule: json['schedule'] != null
            ? BookClubSchedule.fromJson(
                json['schedule'] as Map<String, dynamic>)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        imageUrl: json['imageUrl'] as String?,
      );
}

class BookClubSchedule {
  final DateTime startDate;
  final DateTime endDate;
  final int chaptersPerWeek;
  final List<BookClubMilestone> milestones;

  const BookClubSchedule({
    required this.startDate,
    required this.endDate,
    this.chaptersPerWeek = 3,
    this.milestones = const [],
  });

  Map<String, dynamic> toJson() => {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'chaptersPerWeek': chaptersPerWeek,
        'milestones': milestones.map((m) => m.toJson()).toList(),
      };

  factory BookClubSchedule.fromJson(Map<String, dynamic> json) =>
      BookClubSchedule(
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        chaptersPerWeek: json['chaptersPerWeek'] as int? ?? 3,
        milestones: (json['milestones'] as List?)
                ?.map((m) =>
                    BookClubMilestone.fromJson(m as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class BookClubMilestone {
  final int weekNumber;
  final int startChapter;
  final int endChapter;
  final DateTime dueDate;

  const BookClubMilestone({
    required this.weekNumber,
    required this.startChapter,
    required this.endChapter,
    required this.dueDate,
  });

  Map<String, dynamic> toJson() => {
        'weekNumber': weekNumber,
        'startChapter': startChapter,
        'endChapter': endChapter,
        'dueDate': dueDate.toIso8601String(),
      };

  factory BookClubMilestone.fromJson(Map<String, dynamic> json) =>
      BookClubMilestone(
        weekNumber: json['weekNumber'] as int,
        startChapter: json['startChapter'] as int,
        endChapter: json['endChapter'] as int,
        dueDate: DateTime.parse(json['dueDate'] as String),
      );
}

class DiscussionThreadModel {
  final String id;
  final String clubId;
  final String title;
  final int chapterGate;
  final String authorId;
  final String authorName;
  final int replyCount;
  final DateTime createdAt;
  final List<DiscussionReplyModel> replies;

  const DiscussionThreadModel({
    required this.id,
    required this.clubId,
    required this.title,
    this.chapterGate = 0,
    required this.authorId,
    required this.authorName,
    this.replyCount = 0,
    required this.createdAt,
    this.replies = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'clubId': clubId,
        'title': title,
        'chapterGate': chapterGate,
        'authorId': authorId,
        'authorName': authorName,
        'replyCount': replyCount,
        'createdAt': createdAt.toIso8601String(),
        'replies': replies.map((r) => r.toJson()).toList(),
      };

  factory DiscussionThreadModel.fromJson(Map<String, dynamic> json) =>
      DiscussionThreadModel(
        id: json['id'] as String,
        clubId: json['clubId'] as String,
        title: json['title'] as String,
        chapterGate: json['chapterGate'] as int? ?? 0,
        authorId: json['authorId'] as String,
        authorName: json['authorName'] as String,
        replyCount: json['replyCount'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        replies: (json['replies'] as List?)
                ?.map((r) =>
                    DiscussionReplyModel.fromJson(r as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class DiscussionReplyModel {
  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;

  const DiscussionReplyModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorId': authorId,
        'authorName': authorName,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DiscussionReplyModel.fromJson(Map<String, dynamic> json) =>
      DiscussionReplyModel(
        id: json['id'] as String,
        authorId: json['authorId'] as String,
        authorName: json['authorName'] as String,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class BookRecommendation {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final String bookTitle;
  final String bookAuthor;
  final String? isbn;
  final String personalNote;
  final DateTime createdAt;

  const BookRecommendation({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.bookTitle,
    required this.bookAuthor,
    this.isbn,
    this.personalNote = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromUserId': fromUserId,
        'fromUserName': fromUserName,
        'bookTitle': bookTitle,
        'bookAuthor': bookAuthor,
        'isbn': isbn,
        'personalNote': personalNote,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BookRecommendation.fromJson(Map<String, dynamic> json) =>
      BookRecommendation(
        id: json['id'] as String,
        fromUserId: json['fromUserId'] as String,
        fromUserName: json['fromUserName'] as String,
        bookTitle: json['bookTitle'] as String,
        bookAuthor: json['bookAuthor'] as String,
        isbn: json['isbn'] as String?,
        personalNote: json['personalNote'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

enum ContentWarningLevel { graphic, moderate, minor }

class ContentWarning {
  final String category;
  final ContentWarningLevel level;
  final int voteCount;

  const ContentWarning({
    required this.category,
    required this.level,
    this.voteCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'category': category,
        'level': level.name,
        'voteCount': voteCount,
      };

  factory ContentWarning.fromJson(Map<String, dynamic> json) => ContentWarning(
        category: json['category'] as String,
        level: ContentWarningLevel.values.firstWhere(
          (l) => l.name == json['level'],
          orElse: () => ContentWarningLevel.minor,
        ),
        voteCount: json['voteCount'] as int? ?? 0,
      );
}

class BookVoteModel {
  final String id;
  final String bookTitle;
  final String bookAuthor;
  final String? isbn;
  final int voteCount;
  final List<String> voterIds;

  const BookVoteModel({
    required this.id,
    required this.bookTitle,
    required this.bookAuthor,
    this.isbn,
    this.voteCount = 0,
    this.voterIds = const [],
  });

  BookVoteModel copyWith({
    int? voteCount,
    List<String>? voterIds,
  }) {
    return BookVoteModel(
      id: id,
      bookTitle: bookTitle,
      bookAuthor: bookAuthor,
      isbn: isbn,
      voteCount: voteCount ?? this.voteCount,
      voterIds: voterIds ?? this.voterIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookTitle': bookTitle,
        'bookAuthor': bookAuthor,
        'isbn': isbn,
        'voteCount': voteCount,
        'voterIds': voterIds,
      };

  factory BookVoteModel.fromJson(Map<String, dynamic> json) => BookVoteModel(
        id: json['id'] as String,
        bookTitle: json['bookTitle'] as String,
        bookAuthor: json['bookAuthor'] as String,
        isbn: json['isbn'] as String?,
        voteCount: json['voteCount'] as int? ?? 0,
        voterIds: (json['voterIds'] as List?)?.cast<String>() ?? [],
      );
}
