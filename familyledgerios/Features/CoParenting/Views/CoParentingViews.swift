import SwiftUI

@Observable
final class CoParentingViewModel {
    var children: [CoparentChild] = []
    var coparents: [ChildCoparent] = []
    var pendingInvites: [PendingInvite] = []
    var stats: CoparentingStats?
    var currentUser: CurrentCoparentUser?
    var activities: [CoparentActivity] = []
    var conversations: [CoparentConversation] = []
    var messages: [CoparentMessage] = []
    var schedule: CoparentingSchedule?
    var selectedChild: CoparentChild?
    var isLoading = false
    var errorMessage: String?

    @MainActor
    func loadDashboard() async {
        isLoading = children.isEmpty
        do {
            let response: CoparentingDashboardResponse = try await APIClient.shared.request(.coparenting)
            children = response.children ?? []
            coparents = response.coparents ?? []
            pendingInvites = response.pendingInvites ?? []
            stats = response.stats
            currentUser = response.currentUser
            activities = response.upcomingActivities ?? []
        } catch { errorMessage = "Failed to load co-parenting data" }
        isLoading = false
    }

    @MainActor
    func loadChildren() async {
        do { children = try await APIClient.shared.request(.coparentingChildren) }
        catch { errorMessage = "Failed to load children" }
    }

    @MainActor
    func loadChild(id: Int) async {
        isLoading = selectedChild == nil
        do { selectedChild = try await APIClient.shared.request(.coparentingChild(id: id)) }
        catch { errorMessage = "Failed to load child" }
        isLoading = false
    }

    @MainActor
    func loadSchedule() async {
        do { schedule = try await APIClient.shared.request(.coparentingSchedule) }
        catch { }
    }

    @MainActor
    func loadActivities() async {
        do { activities = try await APIClient.shared.request(.coparentingActivities) }
        catch { }
    }

    @MainActor
    func loadConversations() async {
        do { conversations = try await APIClient.shared.request(.coparentingConversations) }
        catch { }
    }

    @MainActor
    func loadMessages(conversationId: Int) async {
        isLoading = messages.isEmpty
        do {
            let response: CoparentConversation = try await APIClient.shared.request(.coparentingConversation(id: conversationId))
            // Messages would be in a nested response
        } catch { }
        isLoading = false
    }
}

enum CoParentingTab: String, CaseIterable {
    case dashboard = "Dashboard"
    case calendar = "Calendar"
    case activities = "Activities"
    case messages = "Messages"
    case expenses = "Expenses"

    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .calendar: return "calendar"
        case .activities: return "figure.walk"
        case .messages: return "message.fill"
        case .expenses: return "dollarsign.circle.fill"
        }
    }
}

struct CoParentingDashboardView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = CoParentingViewModel()
    @State private var selectedTab: CoParentingTab = .dashboard

    var body: some View {
        VStack(spacing: 0) {
            // Tab Bar
            coparentingTabBar

            // Content
            Group {
                if viewModel.isLoading {
                    LoadingView(message: "Loading co-parenting...")
                } else {
                    switch selectedTab {
                    case .dashboard:
                        dashboardContent
                    case .calendar:
                        calendarContent
                    case .activities:
                        activitiesContent
                    case .messages:
                        messagesContent
                    case .expenses:
                        expensesContent
                    }
                }
            }
        }
        .navigationTitle("Co-Parenting")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    // TODO: Invite co-parent
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "person.badge.plus")
                        Text("Invite")
                    }
                    .font(.system(size: 14, weight: .medium))
                }
            }
        }
        .task { await viewModel.loadDashboard() }
        .refreshable { await viewModel.loadDashboard() }
    }

    // MARK: - Tab Bar

    private var coparentingTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(CoParentingTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 14))
                            Text(tab.rawValue)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(selectedTab == tab ? .white : AppColors.coparenting)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(selectedTab == tab ? AppColors.coparenting : AppColors.coparenting.opacity(0.1))
                        .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(AppColors.background)
    }

    // MARK: - Dashboard Content

    private var dashboardContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Stats Cards
                statsSection

                // Children & Co-parents Section
                childrenSection

                // Pending Invites Section
                if !viewModel.pendingInvites.isEmpty {
                    pendingInvitesSection
                }

                // Upcoming Activities
                if !viewModel.activities.isEmpty {
                    upcomingActivitiesSection
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Calendar Content

    private var calendarContent: some View {
        VStack {
            if let schedule = viewModel.schedule {
                ScrollView {
                    VStack(spacing: 16) {
                        // Schedule Info Card
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.coparenting.opacity(0.15))
                                    .frame(width: 64, height: 64)
                                Image(systemName: "calendar")
                                    .font(.system(size: 28))
                                    .foregroundColor(AppColors.coparenting)
                            }

                            Text(schedule.name)
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.textPrimary)

                            Text(schedule.templateType)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.background)
                        .cornerRadius(16)
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
            } else {
                EmptyStateView(
                    icon: "calendar",
                    title: "No Schedule",
                    message: "Custody schedule not set up yet."
                )
            }
        }
        .task { await viewModel.loadSchedule() }
    }

    // MARK: - Activities Content

    private var activitiesContent: some View {
        Group {
            if viewModel.activities.isEmpty {
                EmptyStateView(
                    icon: "figure.walk",
                    title: "No Activities",
                    message: "No upcoming activities scheduled."
                )
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.activities) { activity in
                            ActivityCard(activity: activity)
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
            }
        }
        .task { await viewModel.loadActivities() }
    }

    // MARK: - Messages Content

    private var messagesContent: some View {
        Group {
            if viewModel.conversations.isEmpty {
                EmptyStateView(
                    icon: "message.fill",
                    title: "No Messages",
                    message: "Start a conversation with your co-parent."
                )
            } else {
                List(viewModel.conversations) { conversation in
                    Button {
                        router.navigate(to: .coparentingMessageThread(id: conversation.id))
                    } label: {
                        ConversationRow(conversation: conversation)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .task { await viewModel.loadConversations() }
    }

    // MARK: - Expenses Content

    private var expensesContent: some View {
        EmptyStateView(
            icon: "dollarsign.circle.fill",
            title: "Shared Expenses",
            message: "Track and split child-related expenses with your co-parent."
        ) {
            Button {
                // TODO: Add expense
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Expense")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(AppColors.coparenting)
                .cornerRadius(10)
            }
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: 12) {
            CoparentingStatCard(
                value: viewModel.stats?.childrenCount ?? viewModel.children.count,
                label: "Children",
                icon: "figure.child",
                color: .pink
            )
            CoparentingStatCard(
                value: viewModel.stats?.coparentsCount ?? viewModel.coparents.count,
                label: "Co-parents",
                icon: "person.2.fill",
                color: AppColors.coparenting
            )
            CoparentingStatCard(
                value: viewModel.stats?.pendingInvitesCount ?? viewModel.pendingInvites.count,
                label: "Pending",
                icon: "clock.fill",
                color: .orange
            )
        }
    }

    // MARK: - Children Section

    private var childrenSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Children & Co-parents")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }

            if viewModel.children.isEmpty {
                // Empty State
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 64, height: 64)
                        Image(systemName: "figure.child")
                            .font(.system(size: 28))
                            .foregroundColor(AppColors.textTertiary)
                    }
                    Text("No children in co-parenting yet")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(AppColors.background)
                .cornerRadius(16)
            } else {
                ForEach(viewModel.children) { child in
                    ChildCoparentCard(
                        child: child,
                        currentUser: viewModel.currentUser,
                        onTap: { router.navigate(to: .coparentingChild(id: child.id)) }
                    )
                }
            }
        }
    }

    // MARK: - Pending Invites Section

    private var pendingInvitesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
                Text("Pending Invitations")
                    .font(AppTypography.headline)
                    .foregroundColor(.orange)
            }

            ForEach(viewModel.pendingInvites) { invite in
                PendingInviteRow(invite: invite)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(16)
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            HStack(spacing: 12) {
                QuickActionCard(title: "Schedule", icon: "calendar", color: AppColors.coparenting) {
                    router.navigate(to: .coparentingSchedule)
                }
                QuickActionCard(title: "Activities", icon: "figure.walk", color: AppColors.coparenting) {
                    router.navigate(to: .coparentingActivities)
                }
                QuickActionCard(title: "Messages", icon: "message.fill", color: AppColors.coparenting) {
                    router.navigate(to: .coparentingMessages)
                }
            }
        }
    }

    // MARK: - Upcoming Activities Section (for Dashboard)

    private var upcomingActivitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming Activities")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            ForEach(viewModel.activities.prefix(3)) { activity in
                ActivityCard(activity: activity)
            }

            if viewModel.activities.count > 3 {
                Button {
                    selectedTab = .activities
                } label: {
                    Text("View all activities")
                        .font(AppTypography.captionSmall)
                        .foregroundColor(AppColors.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
            }
        }
    }
}

// MARK: - Activity Card

struct ActivityCard: View {
    let activity: CoparentActivity

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.coparenting.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "figure.walk")
                    .foregroundColor(AppColors.coparenting)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(AppTypography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                HStack(spacing: 4) {
                    Text(activity.date)
                        .font(AppTypography.captionSmall)
                        .foregroundColor(AppColors.textSecondary)
                    if let time = activity.time {
                        Text("at \(time)")
                            .font(AppTypography.captionSmall)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    if let location = activity.location {
                        Text("•")
                            .foregroundColor(AppColors.textTertiary)
                        Text(location)
                            .font(AppTypography.captionSmall)
                            .foregroundColor(AppColors.textTertiary)
                            .lineLimit(1)
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(AppColors.textTertiary)
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(12)
    }
}

// MARK: - Conversation Row

struct ConversationRow: View {
    let conversation: CoparentConversation

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColors.coparenting.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "message.fill")
                    .foregroundColor(AppColors.coparenting)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.title)
                    .font(AppTypography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                if let lastMessage = conversation.lastMessage {
                    Text(lastMessage)
                        .font(AppTypography.captionSmall)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if conversation.unreadCount > 0 {
                Text("\(conversation.unreadCount)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColors.coparenting)
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Coparenting Stat Card

struct CoparentingStatCard: View {
    let value: Int
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("\(value)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                Text(label)
                    .font(AppTypography.captionSmall)
                    .foregroundColor(AppColors.textSecondary)
            }
            Spacer()
        }
        .padding(12)
        .background(AppColors.background)
        .cornerRadius(12)
    }
}

// MARK: - Child Coparent Card

struct ChildCoparentCard: View {
    let child: CoparentChild
    let currentUser: CurrentCoparentUser?
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Child Info Row
            HStack(spacing: 12) {
                // Avatar
                if let imageUrl = child.profileImageUrl, !imageUrl.isEmpty, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            childAvatarPlaceholder
                        }
                    }
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.pink.opacity(0.3), lineWidth: 2))
                } else {
                    childAvatarPlaceholder
                }

                // Name & Age
                VStack(alignment: .leading, spacing: 4) {
                    Text(child.fullName)
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                    if let age = child.age {
                        Text("\(age) years old")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }

                Spacer()

                // View Details Button
                Button(action: onTap) {
                    HStack(spacing: 4) {
                        Text("View Details")
                            .font(AppTypography.captionSmall)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(AppColors.primary)
                }
            }

            // Divider
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 1)

            // Co-parents Section
            VStack(alignment: .leading, spacing: 8) {
                Text("CO-PARENTS")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AppColors.textTertiary)
                    .tracking(0.5)

                // Co-parent Tags
                FlowLayout(spacing: 8) {
                    // Current User Tag
                    if let user = currentUser {
                        CoparentTag(
                            name: user.name ?? "You",
                            initials: user.initials ?? "U",
                            role: "You",
                            roleColor: AppColors.coparenting
                        )
                    }

                    // Other Co-parents
                    if let coparents = child.coparents {
                        ForEach(coparents) { coparent in
                            CoparentTag(
                                name: coparent.displayName ?? coparent.name ?? "Co-parent",
                                initials: String((coparent.displayName ?? coparent.name ?? "C").prefix(1)).uppercased(),
                                avatarUrl: coparent.avatarUrl,
                                role: coparent.parentRoleLabel ?? coparent.relationship ?? "Co-parent",
                                roleColor: roleColor(for: coparent.parentRole)
                            )
                        }
                    }

                    // Empty state
                    if child.coparents?.isEmpty ?? true {
                        Text("No other co-parents yet")
                            .font(AppTypography.captionSmall)
                            .foregroundColor(AppColors.textTertiary)
                            .italic()
                    }
                }
            }
        }
        .padding()
        .background(AppColors.background)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .cornerRadius(16)
    }

    private var childAvatarPlaceholder: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [.pink, .red.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 56, height: 56)
            Text(child.initials ?? String(child.fullName.prefix(1)).uppercased())
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
        }
        .overlay(Circle().stroke(Color.pink.opacity(0.3), lineWidth: 2))
    }

    private func roleColor(for role: String?) -> Color {
        switch role?.lowercased() {
        case "mother": return .pink
        case "father": return .blue
        default: return .green
        }
    }
}

// MARK: - Coparent Tag

struct CoparentTag: View {
    let name: String
    let initials: String
    var avatarUrl: String? = nil
    let role: String
    let roleColor: Color

    var body: some View {
        HStack(spacing: 6) {
            // Avatar
            if let urlString = avatarUrl, !urlString.isEmpty, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        avatarPlaceholder
                    }
                }
                .frame(width: 24, height: 24)
                .clipShape(Circle())
            } else {
                avatarPlaceholder
            }

            // Name
            Text(name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(roleColor.opacity(0.9))

            // Role
            Text("(\(role))")
                .font(.system(size: 10))
                .foregroundColor(roleColor.opacity(0.7))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(roleColor.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(roleColor.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(20)
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Circle()
                .fill(roleColor)
                .frame(width: 24, height: 24)
            Text(initials)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Pending Invite Row

struct PendingInviteRow: View {
    let invite: PendingInvite

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(invite.fullName ?? invite.email ?? "Invited")
                        .font(AppTypography.bodySmall)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)
                    if let roleLabel = invite.parentRoleLabel {
                        Text("(\(roleLabel))")
                            .font(AppTypography.captionSmall)
                            .foregroundColor(.orange)
                    }
                }
                HStack(spacing: 4) {
                    if let children = invite.childrenNames {
                        Text(children)
                            .font(AppTypography.captionSmall)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    if let expires = invite.expiresIn {
                        Text("•")
                            .foregroundColor(AppColors.textTertiary)
                        Text("Expires \(expires)")
                            .font(AppTypography.captionSmall)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
            }

            Spacer()

            Text("Pending")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(6)
        }
        .padding(12)
        .background(Color.white.opacity(0.8))
        .cornerRadius(12)
    }
}


struct ScheduleView: View {
    @State private var viewModel = CoParentingViewModel()

    var body: some View {
        Group {
            if let schedule = viewModel.schedule {
                ScrollView {
                    VStack(spacing: 20) {
                        Text(schedule.name).font(AppTypography.displaySmall)
                        Text(schedule.templateType).foregroundColor(AppColors.textSecondary)
                    }
                    .padding()
                }
            } else {
                EmptyStateView(icon: "calendar", title: "No Schedule", message: "Schedule not set up yet.")
            }
        }
        .navigationTitle("Schedule")
        .task { await viewModel.loadSchedule() }
    }
}

struct ActivitiesView: View {
    @State private var viewModel = CoParentingViewModel()

    var body: some View {
        List(viewModel.activities) { activity in
            VStack(alignment: .leading) {
                Text(activity.title).font(AppTypography.headline)
                Text(activity.date).font(AppTypography.caption).foregroundColor(AppColors.textSecondary)
                if let location = activity.location { Text(location).font(AppTypography.captionSmall).foregroundColor(AppColors.textTertiary) }
            }
        }
        .navigationTitle("Activities")
        .task { await viewModel.loadActivities() }
    }
}

struct ChildDetailView: View {
    let childId: Int
    @State private var viewModel = CoParentingViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading { LoadingView(message: "Loading...") }
            else if let child = viewModel.selectedChild {
                ScrollView {
                    VStack(spacing: 20) {
                        Image(systemName: "figure.child").font(.system(size: 60)).foregroundColor(AppColors.coparenting)
                        Text(child.fullName).font(AppTypography.displaySmall)
                        if let age = child.age { Text("\(age) years old").foregroundColor(AppColors.textSecondary) }

                        if let school = child.schoolName {
                            DetailRow(label: "School", value: school)
                        }
                        if let allergies = child.allergies {
                            DetailRow(label: "Allergies", value: allergies)
                        }
                        if let conditions = child.medicalConditions {
                            DetailRow(label: "Medical Conditions", value: conditions)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Child Details")
        .task { await viewModel.loadChild(id: childId) }
    }
}

struct MessagesListView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = CoParentingViewModel()

    var body: some View {
        List(viewModel.conversations) { conversation in
            Button { router.navigate(to: .coparentingMessageThread(id: conversation.id)) } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(conversation.title).font(AppTypography.headline)
                        if let lastMessage = conversation.lastMessage {
                            Text(lastMessage).font(AppTypography.caption).foregroundColor(AppColors.textSecondary).lineLimit(1)
                        }
                    }
                    Spacer()
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)").font(AppTypography.captionSmall).foregroundColor(.white)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(AppColors.coparenting).clipShape(Capsule())
                    }
                }
            }
        }
        .navigationTitle("Messages")
        .task { await viewModel.loadConversations() }
    }
}

struct MessageThreadView: View {
    let conversationId: Int
    @State private var viewModel = CoParentingViewModel()
    @State private var newMessage = ""

    var body: some View {
        VStack {
            List(viewModel.messages) { message in
                HStack {
                    if message.isOwn { Spacer() }
                    VStack(alignment: message.isOwn ? .trailing : .leading) {
                        Text(message.content)
                            .padding()
                            .background(message.isOwn ? AppColors.coparenting : AppColors.secondaryBackground)
                            .foregroundColor(message.isOwn ? .white : AppColors.textPrimary)
                            .cornerRadius(16)
                        Text(message.createdAt).font(AppTypography.captionSmall).foregroundColor(AppColors.textTertiary)
                    }
                    if !message.isOwn { Spacer() }
                }
            }

            HStack {
                TextField("Message...", text: $newMessage)
                    .textFieldStyle(.roundedBorder)
                Button { } label: {
                    Image(systemName: "paperplane.fill").foregroundColor(AppColors.coparenting)
                }
            }
            .padding()
        }
        .navigationTitle("Conversation")
        .task { await viewModel.loadMessages(conversationId: conversationId) }
    }
}
