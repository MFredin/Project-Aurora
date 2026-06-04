import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'social_models.dart';

const _uuid = Uuid();
const _socialKey = 'social_data';

class SocialData {
  final List<UserProfileModel> users;
  final List<ActivityFeedItem> feed;
  final List<String> followingIds;
  final List<BookClubModel> clubs;
  final List<DiscussionThreadModel> threads;
  final List<BookRecommendation> recommendations;
  final List<BookVoteModel> votes;
  final List<ContentWarning> contentWarnings;

  const SocialData({
    this.users = const [],
    this.feed = const [],
    this.followingIds = const [],
    this.clubs = const [],
    this.threads = const [],
    this.recommendations = const [],
    this.votes = const [],
    this.contentWarnings = const [],
  });

  SocialData copyWith({
    List<UserProfileModel>? users,
    List<ActivityFeedItem>? feed,
    List<String>? followingIds,
    List<BookClubModel>? clubs,
    List<DiscussionThreadModel>? threads,
    List<BookRecommendation>? recommendations,
    List<BookVoteModel>? votes,
    List<ContentWarning>? contentWarnings,
  }) {
    return SocialData(
      users: users ?? this.users,
      feed: feed ?? this.feed,
      followingIds: followingIds ?? this.followingIds,
      clubs: clubs ?? this.clubs,
      threads: threads ?? this.threads,
      recommendations: recommendations ?? this.recommendations,
      votes: votes ?? this.votes,
      contentWarnings: contentWarnings ?? this.contentWarnings,
    );
  }

  Map<String, dynamic> toJson() => {
        'users': users.map((u) => u.toJson()).toList(),
        'feed': feed.map((f) => f.toJson()).toList(),
        'followingIds': followingIds,
        'clubs': clubs.map((c) => c.toJson()).toList(),
        'threads': threads.map((t) => t.toJson()).toList(),
        'recommendations': recommendations.map((r) => r.toJson()).toList(),
        'votes': votes.map((v) => v.toJson()).toList(),
        'contentWarnings': contentWarnings.map((w) => w.toJson()).toList(),
      };

  factory SocialData.fromJson(Map<String, dynamic> json) => SocialData(
        users: (json['users'] as List?)
                ?.map(
                    (u) => UserProfileModel.fromJson(u as Map<String, dynamic>))
                .toList() ??
            [],
        feed: (json['feed'] as List?)
                ?.map(
                    (f) => ActivityFeedItem.fromJson(f as Map<String, dynamic>))
                .toList() ??
            [],
        followingIds: (json['followingIds'] as List?)?.cast<String>() ?? [],
        clubs: (json['clubs'] as List?)
                ?.map(
                    (c) => BookClubModel.fromJson(c as Map<String, dynamic>))
                .toList() ??
            [],
        threads: (json['threads'] as List?)
                ?.map((t) =>
                    DiscussionThreadModel.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [],
        recommendations: (json['recommendations'] as List?)
                ?.map((r) =>
                    BookRecommendation.fromJson(r as Map<String, dynamic>))
                .toList() ??
            [],
        votes: (json['votes'] as List?)
                ?.map(
                    (v) => BookVoteModel.fromJson(v as Map<String, dynamic>))
                .toList() ??
            [],
        contentWarnings: (json['contentWarnings'] as List?)
                ?.map(
                    (w) => ContentWarning.fromJson(w as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class SocialRepository extends Notifier<SocialData> {
  Box get _box => Hive.box('aurora_reader');

  @override
  SocialData build() {
    final raw = _box.get(_socialKey);
    if (raw == null) {
      // Generate demo data on first access
      final demo = generateDemoData();
      _box.put(_socialKey, jsonEncode(demo.toJson()));
      return demo;
    }
    try {
      final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
      return SocialData.fromJson(decoded);
    } catch (_) {
      return const SocialData();
    }
  }

  void _persist() {
    _box.put(_socialKey, jsonEncode(state.toJson()));
  }

  // --- Activity Feed ---

  void addFeedItem(ActivityFeedItem item) {
    state = state.copyWith(feed: [item, ...state.feed]);
    _persist();
  }

  List<ActivityFeedItem> getFeed() {
    final following = state.followingIds.toSet();
    return state.feed
        .where((item) => following.contains(item.userId))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<ActivityFeedItem> getAllFeed() {
    return List.from(state.feed)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // --- Follow / Unfollow ---

  void followUser(String userId) {
    if (state.followingIds.contains(userId)) return;
    state = state.copyWith(
      followingIds: [...state.followingIds, userId],
      users: state.users.map((u) {
        if (u.id == userId) return u.copyWith(isFollowing: true);
        return u;
      }).toList(),
    );
    _persist();
  }

  void unfollowUser(String userId) {
    state = state.copyWith(
      followingIds: state.followingIds.where((id) => id != userId).toList(),
      users: state.users.map((u) {
        if (u.id == userId) return u.copyWith(isFollowing: false);
        return u;
      }).toList(),
    );
    _persist();
  }

  bool isFollowing(String userId) => state.followingIds.contains(userId);

  // --- Book Clubs ---

  void createClub(BookClubModel club) {
    state = state.copyWith(clubs: [...state.clubs, club]);
    _persist();
  }

  void updateClub(BookClubModel club) {
    state = state.copyWith(
      clubs: state.clubs.map((c) => c.id == club.id ? club : c).toList(),
    );
    _persist();
  }

  void deleteClub(String clubId) {
    state = state.copyWith(
      clubs: state.clubs.where((c) => c.id != clubId).toList(),
      threads: state.threads.where((t) => t.clubId != clubId).toList(),
    );
    _persist();
  }

  BookClubModel? getClub(String clubId) {
    for (final club in state.clubs) {
      if (club.id == clubId) return club;
    }
    return null;
  }

  void joinClub(String clubId, String userId) {
    state = state.copyWith(
      clubs: state.clubs.map((c) {
        if (c.id == clubId && !c.memberIds.contains(userId)) {
          return c.copyWith(
            memberIds: [...c.memberIds, userId],
            memberCount: c.memberCount + 1,
          );
        }
        return c;
      }).toList(),
    );
    _persist();
  }

  void leaveClub(String clubId, String userId) {
    state = state.copyWith(
      clubs: state.clubs.map((c) {
        if (c.id == clubId) {
          return c.copyWith(
            memberIds: c.memberIds.where((id) => id != userId).toList(),
            memberCount: (c.memberCount - 1).clamp(0, c.memberCount),
          );
        }
        return c;
      }).toList(),
    );
    _persist();
  }

  // --- Discussion Threads ---

  void addThread(DiscussionThreadModel thread) {
    state = state.copyWith(threads: [...state.threads, thread]);
    _persist();
  }

  List<DiscussionThreadModel> getThreadsForClub(String clubId) {
    return state.threads.where((t) => t.clubId == clubId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void addReply(String threadId, DiscussionReplyModel reply) {
    state = state.copyWith(
      threads: state.threads.map((t) {
        if (t.id == threadId) {
          return DiscussionThreadModel(
            id: t.id,
            clubId: t.clubId,
            title: t.title,
            chapterGate: t.chapterGate,
            authorId: t.authorId,
            authorName: t.authorName,
            replyCount: t.replyCount + 1,
            createdAt: t.createdAt,
            replies: [...t.replies, reply],
          );
        }
        return t;
      }).toList(),
    );
    _persist();
  }

  // --- Book Voting ---

  void addVoteCandidate(String clubId, BookVoteModel vote) {
    state = state.copyWith(votes: [...state.votes, vote]);
    _persist();
  }

  void castVote(String voteId, String userId) {
    state = state.copyWith(
      votes: state.votes.map((v) {
        if (v.id == voteId && !v.voterIds.contains(userId)) {
          return v.copyWith(
            voteCount: v.voteCount + 1,
            voterIds: [...v.voterIds, userId],
          );
        }
        return v;
      }).toList(),
    );
    _persist();
  }

  void removeVote(String voteId, String userId) {
    state = state.copyWith(
      votes: state.votes.map((v) {
        if (v.id == voteId && v.voterIds.contains(userId)) {
          return v.copyWith(
            voteCount: (v.voteCount - 1).clamp(0, v.voteCount),
            voterIds: v.voterIds.where((id) => id != userId).toList(),
          );
        }
        return v;
      }).toList(),
    );
    _persist();
  }

  List<BookVoteModel> getVotesForClub(String clubId) {
    // Votes are stored with clubId as prefix in their id
    return state.votes
        .where((v) => v.id.startsWith(clubId))
        .toList()
      ..sort((a, b) => b.voteCount.compareTo(a.voteCount));
  }

  // --- Content Warnings ---

  void addContentWarning(ContentWarning warning) {
    state = state.copyWith(
        contentWarnings: [...state.contentWarnings, warning]);
    _persist();
  }

  List<ContentWarning> getWarningsForBook(String bookTitle) {
    return state.contentWarnings
        .where((w) => w.category.startsWith(bookTitle))
        .toList();
  }

  // --- Recommendations ---

  void addRecommendation(BookRecommendation rec) {
    state = state.copyWith(
        recommendations: [rec, ...state.recommendations]);
    _persist();
  }

  List<BookRecommendation> getRecommendations() {
    return List.from(state.recommendations)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // --- Demo Data ---

  static SocialData generateDemoData() {
    final now = DateTime.now();

    final users = [
      UserProfileModel(
        id: 'user_alice',
        displayName: 'Alice Thornberry',
        booksRead: 47,
        followers: 128,
        following: 89,
        joinedDate: now.subtract(const Duration(days: 400)),
        isFollowing: true,
      ),
      UserProfileModel(
        id: 'user_bob',
        displayName: 'Bob Navarro',
        booksRead: 23,
        followers: 56,
        following: 42,
        joinedDate: now.subtract(const Duration(days: 280)),
        isFollowing: true,
      ),
      UserProfileModel(
        id: 'user_clara',
        displayName: 'Clara Whitfield',
        booksRead: 91,
        followers: 312,
        following: 165,
        joinedDate: now.subtract(const Duration(days: 700)),
        isFollowing: true,
      ),
      UserProfileModel(
        id: 'user_dex',
        displayName: 'Dex Morales',
        booksRead: 15,
        followers: 34,
        following: 28,
        joinedDate: now.subtract(const Duration(days: 120)),
        isFollowing: false,
      ),
      UserProfileModel(
        id: 'user_emma',
        displayName: 'Emma Sato',
        booksRead: 63,
        followers: 201,
        following: 97,
        joinedDate: now.subtract(const Duration(days: 550)),
        isFollowing: true,
      ),
    ];

    final feed = [
      ActivityFeedItem(
        id: 'feed_1',
        userId: 'user_alice',
        userName: 'Alice Thornberry',
        type: ActivityType.finishedBook,
        bookTitle: 'Project Hail Mary',
        bookAuthor: 'Andy Weir',
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      ActivityFeedItem(
        id: 'feed_2',
        userId: 'user_bob',
        userName: 'Bob Navarro',
        type: ActivityType.ratedBook,
        bookTitle: 'The Three-Body Problem',
        bookAuthor: 'Liu Cixin',
        detail: '4.5 stars',
        timestamp: now.subtract(const Duration(hours: 5)),
      ),
      ActivityFeedItem(
        id: 'feed_3',
        userId: 'user_clara',
        userName: 'Clara Whitfield',
        type: ActivityType.startedBook,
        bookTitle: 'Piranesi',
        bookAuthor: 'Susanna Clarke',
        timestamp: now.subtract(const Duration(hours: 8)),
      ),
      ActivityFeedItem(
        id: 'feed_4',
        userId: 'user_emma',
        userName: 'Emma Sato',
        type: ActivityType.reviewedBook,
        bookTitle: 'Klara and the Sun',
        bookAuthor: 'Kazuo Ishiguro',
        detail:
            'A beautiful meditation on love and what it means to truly see another person. Ishiguro at his most tender.',
        timestamp: now.subtract(const Duration(hours: 12)),
      ),
      ActivityFeedItem(
        id: 'feed_5',
        userId: 'user_alice',
        userName: 'Alice Thornberry',
        type: ActivityType.highlight,
        bookTitle: 'The Midnight Library',
        bookAuthor: 'Matt Haig',
        detail:
            '"Between life and death there is a library... and within that library, the shelves go on forever."',
        timestamp: now.subtract(const Duration(days: 1)),
      ),
      ActivityFeedItem(
        id: 'feed_6',
        userId: 'user_bob',
        userName: 'Bob Navarro',
        type: ActivityType.addedToShelf,
        bookTitle: 'Dune',
        bookAuthor: 'Frank Herbert',
        timestamp: now.subtract(const Duration(days: 1, hours: 3)),
      ),
      ActivityFeedItem(
        id: 'feed_7',
        userId: 'user_clara',
        userName: 'Clara Whitfield',
        type: ActivityType.finishedBook,
        bookTitle: 'The Name of the Wind',
        bookAuthor: 'Patrick Rothfuss',
        timestamp: now.subtract(const Duration(days: 2)),
      ),
      ActivityFeedItem(
        id: 'feed_8',
        userId: 'user_emma',
        userName: 'Emma Sato',
        type: ActivityType.ratedBook,
        bookTitle: 'Circe',
        bookAuthor: 'Madeline Miller',
        detail: '5.0 stars',
        timestamp: now.subtract(const Duration(days: 2, hours: 6)),
      ),
    ];

    final followingIds = ['user_alice', 'user_bob', 'user_clara', 'user_emma'];

    final clubs = [
      BookClubModel(
        id: 'club_scifi',
        name: 'Stellar Readers',
        description:
            'A club for science fiction enthusiasts exploring the best of the genre, from classic to modern.',
        creatorId: 'user_alice',
        memberIds: [
          'user_alice',
          'user_bob',
          'user_clara',
          'user_self',
          'user_dex'
        ],
        memberCount: 5,
        currentBookTitle: 'Project Hail Mary',
        currentBookAuthor: 'Andy Weir',
        schedule: BookClubSchedule(
          startDate: now.subtract(const Duration(days: 14)),
          endDate: now.add(const Duration(days: 21)),
          chaptersPerWeek: 5,
          milestones: [
            BookClubMilestone(
              weekNumber: 1,
              startChapter: 1,
              endChapter: 5,
              dueDate: now.subtract(const Duration(days: 7)),
            ),
            BookClubMilestone(
              weekNumber: 2,
              startChapter: 6,
              endChapter: 10,
              dueDate: now,
            ),
            BookClubMilestone(
              weekNumber: 3,
              startChapter: 11,
              endChapter: 15,
              dueDate: now.add(const Duration(days: 7)),
            ),
            BookClubMilestone(
              weekNumber: 4,
              startChapter: 16,
              endChapter: 20,
              dueDate: now.add(const Duration(days: 14)),
            ),
            BookClubMilestone(
              weekNumber: 5,
              startChapter: 21,
              endChapter: 25,
              dueDate: now.add(const Duration(days: 21)),
            ),
          ],
        ),
        createdAt: now.subtract(const Duration(days: 90)),
      ),
      BookClubModel(
        id: 'club_fantasy',
        name: 'The Enchanted Circle',
        description:
            'Fantasy lovers unite! We tackle epic series and standalone gems.',
        creatorId: 'user_clara',
        memberIds: ['user_clara', 'user_emma', 'user_self'],
        memberCount: 3,
        currentBookTitle: 'Piranesi',
        currentBookAuthor: 'Susanna Clarke',
        schedule: BookClubSchedule(
          startDate: now.subtract(const Duration(days: 7)),
          endDate: now.add(const Duration(days: 14)),
          chaptersPerWeek: 4,
          milestones: [
            BookClubMilestone(
              weekNumber: 1,
              startChapter: 1,
              endChapter: 4,
              dueDate: now,
            ),
            BookClubMilestone(
              weekNumber: 2,
              startChapter: 5,
              endChapter: 8,
              dueDate: now.add(const Duration(days: 7)),
            ),
            BookClubMilestone(
              weekNumber: 3,
              startChapter: 9,
              endChapter: 12,
              dueDate: now.add(const Duration(days: 14)),
            ),
          ],
        ),
        createdAt: now.subtract(const Duration(days: 45)),
      ),
    ];

    final threads = [
      DiscussionThreadModel(
        id: 'thread_1',
        clubId: 'club_scifi',
        title: 'The science behind Rocky — how plausible is it?',
        chapterGate: 5,
        authorId: 'user_bob',
        authorName: 'Bob Navarro',
        replyCount: 3,
        createdAt: now.subtract(const Duration(days: 5)),
        replies: [
          DiscussionReplyModel(
            id: 'reply_1',
            authorId: 'user_alice',
            authorName: 'Alice Thornberry',
            content:
                'I love how Weir grounds the xenobiology in real chemistry. The Astrophage concept is surprisingly plausible!',
            createdAt: now.subtract(const Duration(days: 4)),
          ),
          DiscussionReplyModel(
            id: 'reply_2',
            authorId: 'user_clara',
            authorName: 'Clara Whitfield',
            content:
                'The way communication develops between Grace and Rocky is my favorite part so far.',
            createdAt: now.subtract(const Duration(days: 3)),
          ),
          DiscussionReplyModel(
            id: 'reply_3',
            authorId: 'user_dex',
            authorName: 'Dex Morales',
            content:
                'Agreed! The musical language aspect is genius. Reminds me of Arrival.',
            createdAt: now.subtract(const Duration(days: 2)),
          ),
        ],
      ),
      DiscussionThreadModel(
        id: 'thread_2',
        clubId: 'club_scifi',
        title: 'Grace as an unreliable narrator?',
        chapterGate: 10,
        authorId: 'user_alice',
        authorName: 'Alice Thornberry',
        replyCount: 1,
        createdAt: now.subtract(const Duration(days: 3)),
        replies: [
          DiscussionReplyModel(
            id: 'reply_4',
            authorId: 'user_bob',
            authorName: 'Bob Navarro',
            content:
                'The amnesia device is clever — we discover things as Grace does. Classic Weir.',
            createdAt: now.subtract(const Duration(days: 2)),
          ),
        ],
      ),
      DiscussionThreadModel(
        id: 'thread_3',
        clubId: 'club_fantasy',
        title: 'The House as a character — thoughts on the setting',
        chapterGate: 3,
        authorId: 'user_emma',
        authorName: 'Emma Sato',
        replyCount: 2,
        createdAt: now.subtract(const Duration(days: 4)),
        replies: [
          DiscussionReplyModel(
            id: 'reply_5',
            authorId: 'user_clara',
            authorName: 'Clara Whitfield',
            content:
                'Clarke makes the House feel alive. Every hall and statue has personality.',
            createdAt: now.subtract(const Duration(days: 3)),
          ),
          DiscussionReplyModel(
            id: 'reply_6',
            authorId: 'user_self',
            authorName: 'You',
            content:
                'The tidal imagery is mesmerizing. I keep picturing it as a mix of Escher and ancient Greek ruins.',
            createdAt: now.subtract(const Duration(days: 2)),
          ),
        ],
      ),
    ];

    final recommendations = [
      BookRecommendation(
        id: 'rec_1',
        fromUserId: 'user_alice',
        fromUserName: 'Alice Thornberry',
        bookTitle: 'The Martian',
        bookAuthor: 'Andy Weir',
        personalNote:
            'If you loved Project Hail Mary, you have to read this one too!',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      BookRecommendation(
        id: 'rec_2',
        fromUserId: 'user_clara',
        fromUserName: 'Clara Whitfield',
        bookTitle: 'Jonathan Strange & Mr Norrell',
        bookAuthor: 'Susanna Clarke',
        personalNote:
            'Same author as Piranesi but a completely different scale. Epic and brilliant.',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      BookRecommendation(
        id: 'rec_3',
        fromUserId: 'user_emma',
        fromUserName: 'Emma Sato',
        bookTitle: 'The Song of Achilles',
        bookAuthor: 'Madeline Miller',
        personalNote:
            'If Circe moved you, this will destroy you (in the best way).',
        createdAt: now.subtract(const Duration(days: 7)),
      ),
    ];

    final votes = [
      BookVoteModel(
        id: 'club_scifi_vote_1',
        bookTitle: 'Children of Time',
        bookAuthor: 'Adrian Tchaikovsky',
        voteCount: 3,
        voterIds: ['user_alice', 'user_bob', 'user_self'],
      ),
      BookVoteModel(
        id: 'club_scifi_vote_2',
        bookTitle: 'The Left Hand of Darkness',
        bookAuthor: 'Ursula K. Le Guin',
        voteCount: 2,
        voterIds: ['user_clara', 'user_dex'],
      ),
      BookVoteModel(
        id: 'club_scifi_vote_3',
        bookTitle: 'Blindsight',
        bookAuthor: 'Peter Watts',
        voteCount: 1,
        voterIds: ['user_bob'],
      ),
      BookVoteModel(
        id: 'club_fantasy_vote_1',
        bookTitle: 'The Starless Sea',
        bookAuthor: 'Erin Morgenstern',
        voteCount: 2,
        voterIds: ['user_emma', 'user_self'],
      ),
      BookVoteModel(
        id: 'club_fantasy_vote_2',
        bookTitle: 'Uprooted',
        bookAuthor: 'Naomi Novik',
        voteCount: 1,
        voterIds: ['user_clara'],
      ),
    ];

    return SocialData(
      users: users,
      feed: feed,
      followingIds: followingIds,
      clubs: clubs,
      threads: threads,
      recommendations: recommendations,
      votes: votes,
    );
  }
}

final socialRepositoryProvider =
    NotifierProvider<SocialRepository, SocialData>(SocialRepository.new);

final socialFeedProvider = Provider<List<ActivityFeedItem>>((ref) {
  final social = ref.watch(socialRepositoryProvider);
  final following = social.followingIds.toSet();
  return social.feed
      .where((item) => following.contains(item.userId))
      .toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
});

final socialClubsProvider = Provider<List<BookClubModel>>((ref) {
  final social = ref.watch(socialRepositoryProvider);
  return social.clubs;
});

final socialRecommendationsProvider =
    Provider<List<BookRecommendation>>((ref) {
  final social = ref.watch(socialRepositoryProvider);
  return List.from(social.recommendations)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

final clubByIdProvider =
    Provider.family<BookClubModel?, String>((ref, clubId) {
  final social = ref.watch(socialRepositoryProvider);
  for (final club in social.clubs) {
    if (club.id == clubId) return club;
  }
  return null;
});

final clubThreadsProvider =
    Provider.family<List<DiscussionThreadModel>, String>((ref, clubId) {
  final social = ref.watch(socialRepositoryProvider);
  return social.threads.where((t) => t.clubId == clubId).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

final clubVotesProvider =
    Provider.family<List<BookVoteModel>, String>((ref, clubId) {
  final social = ref.watch(socialRepositoryProvider);
  return social.votes
      .where((v) => v.id.startsWith(clubId))
      .toList()
    ..sort((a, b) => b.voteCount.compareTo(a.voteCount));
});
