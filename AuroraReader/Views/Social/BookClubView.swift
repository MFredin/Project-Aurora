import SwiftUI
import SwiftData

/// Book Club / Shared Reading view for synchronized reading
struct BookClubView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var clubs: [BookClub]
    @Query private var discussions: [ClubDiscussion]

    @State private var showCreateClub = false
    @State private var selectedClub: BookClub?

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraTheme.deepSpace.ignoresSafeArea()

                Circle()
                    .fill(AuroraTheme.auroraPurple.opacity(0.06))
                    .frame(width: 350, height: 350)
                    .blur(radius: 90)
                    .offset(x: -80, y: -200)
                    .ignoresSafeArea()

                if clubs.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Active clubs
                            ForEach(clubs.filter(\.isActive)) { club in
                                clubCard(club)
                            }

                            // Past clubs
                            let pastClubs = clubs.filter { !$0.isActive }
                            if !pastClubs.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Past Clubs")
                                        .font(.headline)
                                        .foregroundStyle(AuroraTheme.textSecondary)

                                    ForEach(pastClubs) { club in
                                        clubCard(club)
                                            .opacity(0.7)
                                    }
                                }
                            }
                        }
                        .padding()
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Book Clubs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateClub = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(AuroraTheme.auroraTeal)
                    }
                }
            }
            .sheet(isPresented: $showCreateClub) {
                CreateBookClubSheet()
            }
            .sheet(item: $selectedClub) { club in
                BookClubDetailView(club: club)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Club Card

    private func clubCard(_ club: BookClub) -> some View {
        Button {
            selectedClub = club
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(club.name)
                            .font(.headline)
                            .foregroundStyle(AuroraTheme.textPrimary)
                        Text(club.bookTitle)
                            .font(.subheadline)
                            .foregroundStyle(AuroraTheme.textSecondary)
                    }
                    Spacer()
                    Text(club.pace.rawValue)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(AuroraTheme.auroraTeal)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AuroraTheme.auroraTeal.opacity(0.12), in: Capsule())
                }

                // Progress
                VStack(spacing: 4) {
                    ProgressView(value: club.progressPercentage)
                        .tint(AuroraTheme.auroraTeal)
                    HStack {
                        Text("Chapter \(club.targetChapter) of \(club.totalChapters)")
                            .font(.caption2)
                            .foregroundStyle(AuroraTheme.textTertiary)
                        Spacer()
                        Text("\(Int(club.progressPercentage * 100))%")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(AuroraTheme.auroraTeal)
                    }
                }

                // Members
                HStack(spacing: -8) {
                    ForEach(club.memberAvatars.prefix(5), id: \.self) { avatar in
                        Text(avatar)
                            .font(.body)
                            .frame(width: 30, height: 30)
                            .background(AuroraTheme.surface, in: Circle())
                            .overlay(Circle().strokeBorder(AuroraTheme.deepSpace, lineWidth: 2))
                    }

                    if club.memberCount > 5 {
                        Text("+\(club.memberCount - 5)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(AuroraTheme.textSecondary)
                            .frame(width: 30, height: 30)
                            .background(AuroraTheme.surface, in: Circle())
                            .overlay(Circle().strokeBorder(AuroraTheme.deepSpace, lineWidth: 2))
                    }

                    Spacer()

                    let clubDiscussions = discussions.filter { $0.clubId == club.id }
                    Label("\(clubDiscussions.count)", systemImage: "bubble.left.and.bubble.right.fill")
                        .font(.caption2)
                        .foregroundStyle(AuroraTheme.textTertiary)
                        .symbolRenderingMode(.hierarchical)
                }
            }
            .padding(16)
            .auroraCard()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 44))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(AuroraTheme.textTertiary)

            Text("No Book Clubs")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AuroraTheme.textPrimary)

            Text("Create a book club to read together with friends, sync pace, and discuss chapters")
                .font(.subheadline)
                .foregroundStyle(AuroraTheme.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                showCreateClub = true
            } label: {
                Label("Create Book Club", systemImage: "plus.circle.fill")
            }
            .buttonStyle(AuroraButtonStyle())
        }
        .padding(40)
    }
}

// MARK: - Create Club Sheet

struct CreateBookClubSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var books: [Book]

    @State private var clubName = ""
    @State private var selectedBook: Book?
    @State private var pace: BookClub.PaceType = .weekly

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraTheme.deepSpace.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        TextField("Club Name", text: $clubName)
                            .textFieldStyle(.plain)
                            .foregroundStyle(AuroraTheme.textPrimary)
                            .padding(12)
                            .background(AuroraTheme.surface, in: RoundedRectangle(cornerRadius: 8))

                        // Book selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Select Book")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(AuroraTheme.textSecondary)

                            ForEach(books) { book in
                                Button {
                                    selectedBook = book
                                } label: {
                                    HStack {
                                        Image(systemName: book.bookFormat.iconName)
                                            .foregroundStyle(AuroraTheme.auroraTeal)
                                        Text(book.title)
                                            .font(.subheadline)
                                            .foregroundStyle(AuroraTheme.textPrimary)
                                        Spacer()
                                        if selectedBook?.id == book.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(AuroraTheme.auroraTeal)
                                        }
                                    }
                                    .padding(10)
                                    .background(
                                        selectedBook?.id == book.id
                                            ? AuroraTheme.auroraTeal.opacity(0.1)
                                            : AuroraTheme.surface,
                                        in: RoundedRectangle(cornerRadius: 8)
                                    )
                                }
                            }
                        }

                        // Pace picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reading Pace")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(AuroraTheme.textSecondary)

                            Picker("Pace", selection: $pace) {
                                ForEach(BookClub.PaceType.allCases, id: \.self) { p in
                                    Text(p.rawValue).tag(p)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Create Club")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createClub()
                        dismiss()
                    }
                    .disabled(clubName.isEmpty)
                }
            }
        }
    }

    private func createClub() {
        let club = BookClub(
            name: clubName,
            bookTitle: selectedBook?.title ?? "",
            bookAuthor: selectedBook?.author ?? "",
            totalChapters: Int(selectedBook?.readingProgress?.totalPages ?? 0),
            pace: pace
        )
        club.book = selectedBook
        modelContext.insert(club)
        try? modelContext.save()
    }
}

// MARK: - Club Detail View

struct BookClubDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var discussions: [ClubDiscussion]

    let club: BookClub

    @State private var newMessage = ""
    @State private var selectedChapter = 0

    private var clubDiscussions: [ClubDiscussion] {
        discussions
            .filter { $0.clubId == club.id && $0.chapterIndex == selectedChapter }
            .sorted { $0.datePosted < $1.datePosted }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraTheme.deepSpace.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Chapter selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(0..<max(1, club.totalChapters), id: \.self) { chapter in
                                Button {
                                    selectedChapter = chapter
                                } label: {
                                    Text("Ch \(chapter + 1)")
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(selectedChapter == chapter ? .white : AuroraTheme.textSecondary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(
                                            selectedChapter == chapter
                                                ? AnyShapeStyle(AuroraTheme.accentGradient)
                                                : AnyShapeStyle(AuroraTheme.surface),
                                            in: Capsule()
                                        )
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }

                    Divider().overlay(AuroraTheme.surface)

                    // Discussion
                    ScrollView {
                        VStack(spacing: 10) {
                            if clubDiscussions.isEmpty {
                                VStack(spacing: 8) {
                                    Text("No discussion yet")
                                        .font(.subheadline)
                                        .foregroundStyle(AuroraTheme.textSecondary)
                                    Text("Start the conversation!")
                                        .font(.caption)
                                        .foregroundStyle(AuroraTheme.textTertiary)
                                }
                                .padding(30)
                            }

                            ForEach(clubDiscussions) { discussion in
                                discussionBubble(discussion)
                            }
                        }
                        .padding()
                    }

                    // Message input
                    HStack(spacing: 10) {
                        TextField("Add to discussion...", text: $newMessage)
                            .textFieldStyle(.plain)
                            .foregroundStyle(AuroraTheme.textPrimary)
                            .padding(10)
                            .background(AuroraTheme.surface, in: RoundedRectangle(cornerRadius: 20))

                        Button {
                            sendMessage()
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(newMessage.isEmpty ? AuroraTheme.textTertiary : AuroraTheme.auroraTeal)
                        }
                        .disabled(newMessage.isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                }
            }
            .navigationTitle(club.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func discussionBubble(_ discussion: ClubDiscussion) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(discussion.avatarEmoji)
                .font(.title3)
                .frame(width: 32, height: 32)
                .background(AuroraTheme.surface, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(discussion.username)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AuroraTheme.auroraTeal)
                    Text(discussion.datePosted, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(AuroraTheme.textTertiary)
                }

                if let highlighted = discussion.highlightedText {
                    Text(highlighted)
                        .font(.caption)
                        .italic()
                        .foregroundStyle(AuroraTheme.textTertiary)
                        .padding(6)
                        .background(AuroraTheme.auroraTeal.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                }

                Text(discussion.message)
                    .font(.subheadline)
                    .foregroundStyle(AuroraTheme.textPrimary)
            }

            Spacer()
        }
        .padding(10)
        .auroraCard()
    }

    private func sendMessage() {
        let discussion = ClubDiscussion(
            clubId: club.id,
            chapterIndex: selectedChapter,
            message: newMessage
        )
        modelContext.insert(discussion)
        try? modelContext.save()
        newMessage = ""
    }
}
