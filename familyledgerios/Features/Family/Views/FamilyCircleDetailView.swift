import SwiftUI

// MARK: - Tab Enum

enum FamilyCircleTab: String, CaseIterable {
    case members = "Members"
    case resources = "Resources"
    case legal = "Legal"

    var icon: String {
        switch self {
        case .members: return "person.3.fill"
        case .resources: return "doc.fill"
        case .legal: return "briefcase.fill"
        }
    }
}

// MARK: - Main View

struct FamilyCircleDetailView: View {
    let circleId: Int

    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @State private var viewModel = FamilyViewModel()
    @State private var selectedTab: FamilyCircleTab = .members

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading family circle...")
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error) {
                    Task {
                        await viewModel.loadCircle(id: circleId)
                    }
                }
            } else {
                mainContent
            }
        }
        .navigationTitle(viewModel.selectedCircle?.name ?? "Family Circle")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await refreshCurrentTab()
        }
        .task {
            // Load all data upfront so tab counts show immediately
            await viewModel.loadCircle(id: circleId)
            async let resourcesTask: () = viewModel.loadFamilyResources(circleId: circleId)
            async let legalTask: () = viewModel.loadLegalDocuments(circleId: circleId)
            _ = await (resourcesTask, legalTask)
        }
        .onChange(of: selectedTab) { _, newTab in
            Task {
                await loadDataForTab(newTab)
            }
        }
    }

    private func refreshCurrentTab() async {
        switch selectedTab {
        case .members:
            await viewModel.loadCircle(id: circleId)
        case .resources:
            await viewModel.loadFamilyResources(circleId: circleId)
        case .legal:
            await viewModel.loadLegalDocuments(circleId: circleId)
        }
    }

    private func loadDataForTab(_ tab: FamilyCircleTab) async {
        switch tab {
        case .members:
            // Already loaded
            break
        case .resources:
            if viewModel.familyResources.isEmpty {
                await viewModel.loadFamilyResources(circleId: circleId)
            }
        case .legal:
            if viewModel.legalDocuments.isEmpty {
                await viewModel.loadLegalDocuments(circleId: circleId)
            }
        }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            // Circle Header
            circleHeader

            // Tab Bar
            tabBar

            // Tab Content
            TabView(selection: $selectedTab) {
                membersTab
                    .tag(FamilyCircleTab.members)

                familyResourcesTab
                    .tag(FamilyCircleTab.resources)

                legalDocumentsTab
                    .tag(FamilyCircleTab.legal)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Circle Header

    private var circleHeader: some View {
        VStack(spacing: 12) {
            // Circle Image or Icon
            if let imageUrl = viewModel.selectedCircle?.coverImageUrl, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        circleIconPlaceholder
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    case .failure:
                        circleIconPlaceholder
                    @unknown default:
                        circleIconPlaceholder
                    }
                }
            } else {
                circleIconPlaceholder
            }

            // Circle Name
            Text(viewModel.selectedCircle?.name ?? "Family Circle")
                .font(AppTypography.displaySmall)
                .foregroundColor(AppColors.textPrimary)

            // Member Count
            Text("\(viewModel.members.count) member\(viewModel.members.count == 1 ? "" : "s")")
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(AppColors.background)
    }

    private var circleIconPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.family.opacity(0.15))
                .frame(width: 80, height: 80)

            Text("👨‍👩‍👧‍👦")
                .font(.system(size: 40))
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(FamilyCircleTab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .background(AppColors.background)
    }

    private func tabButton(for tab: FamilyCircleTab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: tab.icon)
                        .font(.system(size: 14))

                    Text(tab.rawValue)
                        .font(AppTypography.caption)
                        .lineLimit(1)

                    // Badge for counts
                    if let count = badgeCount(for: tab), count > 0 {
                        Text("\(count)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(selectedTab == tab ? AppColors.family : AppColors.textTertiary)
                            .clipShape(Capsule())
                    }
                }
                .foregroundColor(selectedTab == tab ? AppColors.family : AppColors.textSecondary)

                // Indicator
                Rectangle()
                    .fill(selectedTab == tab ? AppColors.family : Color.clear)
                    .frame(height: 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 12)
        }
        .buttonStyle(.plain)
    }

    private func badgeCount(for tab: FamilyCircleTab) -> Int? {
        switch tab {
        case .members: return viewModel.members.count
        case .resources: return viewModel.familyResources.count
        case .legal: return viewModel.legalDocuments.count
        }
    }

    // MARK: - Members Tab

    private var membersTab: some View {
        ScrollView {
            if viewModel.hasMembers {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.members) { member in
                        FamilyMemberCard(member: member) {
                            router.navigate(to: .familyMember(circleId: circleId, memberId: member.id))
                        }
                    }
                }
                .padding()
            } else {
                emptyMembersView
            }
        }
    }

    private var emptyMembersView: some View {
        VStack(spacing: 12) {
            Text("👤")
                .font(.system(size: 48))

            Text("No Members Yet")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            Text("Add family members to this circle")
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    // MARK: - Family Resources Tab

    private var familyResourcesTab: some View {
        ScrollView {
            if viewModel.isLoadingResources {
                ProgressView()
                    .padding(40)
            } else if viewModel.hasFamilyResources {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.familyResources) { resource in
                        FamilyResourceCard(resource: resource) {
                            router.navigate(to: .familyResource(circleId: circleId, resourceId: resource.id))
                        }
                    }
                }
                .padding()
            } else {
                emptyResourcesView
            }
        }
    }

    private var emptyResourcesView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "doc.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.green)
            }

            Text("No Family Resources Yet")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            Text("Add resources like emergency plans, warranties, and more.")
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    // MARK: - Legal Documents Tab

    private var legalDocumentsTab: some View {
        ScrollView {
            if viewModel.isLoadingLegalDocs {
                ProgressView()
                    .padding(40)
            } else if viewModel.hasLegalDocuments {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.legalDocuments) { document in
                        LegalDocumentCard(document: document) {
                            router.navigate(to: .legalDocument(circleId: circleId, documentId: document.id))
                        }
                    }
                }
                .padding()
            } else {
                emptyLegalView
            }
        }
    }

    private var emptyLegalView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "briefcase.fill")
                    .font(.system(size: 32))
                    .foregroundColor(AppColors.primary)
            }

            Text("No Legal Documents Yet")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            Text("Add wills, trusts, power of attorney, and other legal documents.")
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

// MARK: - Family Resource Card

struct FamilyResourceCard: View {
    let resource: FamilyResource
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: resource.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(resource.name)
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)

                        Spacer()

                        if let status = resource.statusName {
                            SmallBadge(text: status, color: statusColor(for: resource.status))
                        }
                    }

                    Text(resource.documentTypeName ?? "Resource")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)

                    if let filesCount = resource.filesCount ?? resource.files?.count, filesCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "doc")
                                .font(.system(size: 12))
                            Text("\(filesCount) file\(filesCount == 1 ? "" : "s")")
                                .font(AppTypography.captionSmall)
                        }
                        .foregroundColor(AppColors.textTertiary)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding()
            .background(AppColors.background)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func statusColor(for status: String?) -> Color {
        switch status {
        case "active": return .green
        case "expired": return .red
        case "archived": return .gray
        default: return .gray
        }
    }
}

// MARK: - Legal Document Card

struct LegalDocumentCard: View {
    let document: LegalDocument
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.primary.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: document.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.primary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(document.name ?? "Untitled")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)

                        Spacer()

                        if let status = document.statusName {
                            SmallBadge(text: status, color: statusColor(for: document.status))
                        }
                    }

                    Text(document.documentTypeName ?? "Legal Document")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)

                    HStack(spacing: 12) {
                        if let attorney = document.attorneyName, !attorney.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "person")
                                    .font(.system(size: 12))
                                Text(attorney)
                                    .font(AppTypography.captionSmall)
                            }
                            .foregroundColor(AppColors.textTertiary)
                        }

                        if let date = document.formattedExecutionDate {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 12))
                                Text(date)
                                    .font(AppTypography.captionSmall)
                            }
                            .foregroundColor(AppColors.textTertiary)
                        }
                    }

                    if let filesCount = document.filesCount, filesCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "doc")
                                .font(.system(size: 12))
                            Text("\(filesCount) file\(filesCount == 1 ? "" : "s")")
                                .font(AppTypography.captionSmall)
                        }
                        .foregroundColor(AppColors.textTertiary)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding()
            .background(AppColors.background)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func statusColor(for status: String?) -> Color {
        switch status {
        case "active": return .green
        case "superseded": return .orange
        case "expired": return .red
        case "revoked": return .gray
        default: return .gray
        }
    }
}

// MARK: - Small Badge

struct SmallBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .cornerRadius(6)
    }
}

// MARK: - Family Member Card

struct FamilyMemberCard: View {
    let member: FamilyMemberBasic
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Avatar
                MemberAvatar(member: member, size: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text(member.fullName ?? member.displayName)
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)

                    HStack(spacing: 8) {
                        Image(systemName: member.relationshipIcon)
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.family)

                        Text(member.relationshipName ?? member.relationship ?? "Member")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }

                    if let age = member.formattedAge {
                        Text(age)
                            .font(AppTypography.captionSmall)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }

                Spacer()

                // Badges
                VStack(alignment: .trailing, spacing: 4) {
                    if member.isMinor == true {
                        Badge(text: "Minor", color: AppColors.warning)
                    }

                    if member.coParentingEnabled == true {
                        Badge(text: "Co-Parenting", color: AppColors.coparenting)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding()
            .background(AppColors.background)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Member Avatar

struct MemberAvatar: View {
    let profileImageUrl: String?
    let initials: String
    var size: CGFloat = 56

    // Convenience initializer for FamilyMemberBasic
    init(member: FamilyMemberBasic, size: CGFloat = 56) {
        self.profileImageUrl = member.profileImageUrl
        self.initials = member.initials
        self.size = size
    }

    // Convenience initializer for FamilyMember (full)
    init(member: FamilyMember, size: CGFloat = 56) {
        self.profileImageUrl = member.profileImageUrl
        self.initials = member.initials
        self.size = size
    }

    var body: some View {
        Group {
            if let imageUrl = profileImageUrl, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        avatarPlaceholder
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        avatarPlaceholder
                    @unknown default:
                        avatarPlaceholder
                    }
                }
            } else {
                avatarPlaceholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Circle()
                .fill(AppColors.family.opacity(0.2))

            Text(initials)
                .font(.system(size: size * 0.35, weight: .semibold))
                .foregroundColor(AppColors.family)
        }
    }
}

// MARK: - Badge

struct Badge: View {
    let text: String
    var color: Color = AppColors.primary

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .cornerRadius(6)
    }
}

#Preview {
    NavigationStack {
        FamilyCircleDetailView(circleId: 1)
            .environment(AppState())
            .environment(AppRouter())
    }
}
