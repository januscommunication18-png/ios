import SwiftUI

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @State private var viewModel = DashboardViewModel()

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome Header
                    welcomeHeader

                    // Stats Cards
                    if let stats = viewModel.stats {
                        statsSection(stats: stats)
                    }

                    // Reminders Widget
                    if viewModel.hasReminders {
                        remindersWidget
                    }

                    // Quick Actions
                    quickActionsSection

                    // Features Grid
                    featuresSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadDashboard()
            }
            .navigationDestination(for: AppRoute.self) { route in
                destinationView(for: route)
            }
        }
        .environment(router)
        .overlay {
            if viewModel.isLoading {
                LoadingView(message: "Loading dashboard...")
            }
        }
    }

    // MARK: - Welcome Header

    private var welcomeHeader: some View {
        HStack(spacing: 16) {
            // Avatar
            if let avatarUrl = appState.user?.avatar, !avatarUrl.isEmpty {
                AsyncImage(url: URL(string: avatarUrl)) { phase in
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
                .frame(width: 56, height: 56)
                .clipShape(Circle())
            } else {
                avatarPlaceholder
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)

                Text(appState.user?.displayName ?? "User")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
            }

            Spacer()

            // Notifications
            Button {
                // TODO: Show notifications
            } label: {
                Image(systemName: "bell.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(16)
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Circle()
                .fill(AppColors.primary.opacity(0.2))

            Text(appState.user?.initials ?? "?")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.primary)
        }
        .frame(width: 56, height: 56)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }

    // MARK: - Reminders Widget

    private var remindersWidget: some View {
        DashboardRemindersWidget(
            overdue: viewModel.overdueReminders,
            today: viewModel.todayReminders,
            upcoming: viewModel.upcomingReminders,
            onViewAll: {
                router.navigate(to: .reminders)
            },
            onComplete: { id in
                Task { await viewModel.completeReminder(id: id) }
            },
            onTap: { id in
                router.navigate(to: .reminder(id: id))
            }
        )
    }

    // MARK: - Stats Section

    private func statsSection(stats: DashboardStats) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    title: "Family Members",
                    value: "\(stats.familyMembers ?? 0)",
                    icon: "person.3.fill",
                    color: AppColors.family
                )

                StatCard(
                    title: "Assets",
                    value: "\(stats.assets ?? 0)",
                    icon: "house.fill",
                    color: AppColors.assets
                )
            }

            StatCard(
                title: "Total Asset Value",
                value: stats.formattedAssetValue ?? "$0.00",
                icon: "dollarsign.circle.fill",
                color: AppColors.expenses
            )
        }
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionCard(
                    title: "Add Member",
                    icon: "person.badge.plus",
                    color: AppColors.family
                ) {
                    // TODO: Navigate to add member
                }

                QuickActionCard(
                    title: "Add Asset",
                    icon: "plus.circle",
                    color: AppColors.assets
                ) {
                    // TODO: Navigate to add asset
                }

                QuickActionCard(
                    title: "Documents",
                    icon: "doc.fill",
                    color: AppColors.primary
                ) {
                    router.navigate(to: .documents)
                }

                QuickActionCard(
                    title: "Settings",
                    icon: "gearshape.fill",
                    color: AppColors.textSecondary
                ) {
                    router.navigate(to: .settings)
                }
            }
        }
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Features")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            VStack(spacing: 12) {
                FeatureCard(
                    title: "Expenses",
                    subtitle: "Track and manage spending",
                    icon: "dollarsign.circle.fill",
                    color: AppColors.expenses
                ) {
                    router.navigate(to: .expenses)
                }

                FeatureCard(
                    title: "Goals & Tasks",
                    subtitle: "Set and achieve your goals",
                    icon: "target",
                    color: AppColors.goals
                ) {
                    router.navigate(to: .goals)
                }

                FeatureCard(
                    title: "Journal",
                    subtitle: "Capture memories and thoughts",
                    icon: "book.fill",
                    color: AppColors.journal
                ) {
                    router.navigate(to: .journal)
                }

                FeatureCard(
                    title: "Shopping Lists",
                    subtitle: "Organize your shopping",
                    icon: "cart.fill",
                    color: AppColors.shopping
                ) {
                    router.navigate(to: .shopping)
                }

                FeatureCard(
                    title: "Pets",
                    subtitle: "Care for your furry friends",
                    icon: "pawprint.fill",
                    color: AppColors.pets
                ) {
                    router.navigate(to: .pets)
                }

                FeatureCard(
                    title: "People",
                    subtitle: "Your personal directory",
                    icon: "person.crop.circle.fill",
                    color: AppColors.family
                ) {
                    router.navigate(to: .people)
                }

                FeatureCard(
                    title: "Reminders",
                    subtitle: "Never miss an important date",
                    icon: "bell.fill",
                    color: AppColors.reminders
                ) {
                    router.navigate(to: .reminders)
                }

                FeatureCard(
                    title: "Co-Parenting",
                    subtitle: "Coordinate with co-parents",
                    icon: "figure.2.and.child.holdinghands",
                    color: AppColors.coparenting
                ) {
                    router.navigate(to: .coparenting)
                }

                FeatureCard(
                    title: "Resources",
                    subtitle: "Important documents & files",
                    icon: "folder.fill",
                    color: AppColors.primary
                ) {
                    router.navigate(to: .resources)
                }
            }
        }
    }

    // MARK: - Navigation Destinations

    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .expenses:
            ExpensesListView()
        case .expense(let id):
            ExpenseDetailView(expenseId: id)
        case .createExpense:
            CreateExpenseView()
        case .budget(let id):
            BudgetDetailView(budgetId: id)
        case .goals:
            GoalsListView()
        case .goal(let id):
            GoalDetailView(goalId: id)
        case .createGoal:
            CreateGoalView()
        case .task(let id):
            TaskDetailView(taskId: id)
        case .createTask:
            CreateTaskView()
        case .journal:
            JournalListView()
        case .journalEntry(let id):
            JournalDetailView(entryId: id)
        case .createJournalEntry:
            CreateJournalEntryView()
        case .shopping:
            ShoppingListsView()
        case .shoppingList(let id):
            ShoppingDetailView(listId: id)
        case .createShoppingList:
            CreateShoppingListView()
        case .pets:
            PetsListView()
        case .pet(let id):
            PetDetailView(petId: id)
        case .createPet:
            CreatePetView()
        case .people:
            PeopleListView()
        case .person(let id):
            PersonDetailView(personId: id)
        case .createPerson:
            CreatePersonView()
        case .reminders:
            RemindersListView()
        case .reminder(let id):
            ReminderDetailView(reminderId: id)
        case .createReminder:
            CreateReminderView()
        case .documents:
            DocumentsView()
        case .insurancePolicy(let id):
            InsurancePolicyDetailView(policyId: id)
        case .taxReturn(let id):
            TaxReturnDetailView(returnId: id)
        case .resources:
            ResourcesListView()
        case .resource(let id):
            ResourceDetailView(resourceId: id)
        case .coparenting:
            CoParentingDashboardView()
        case .coparentingSchedule:
            ScheduleView()
        case .coparentingActivities:
            ActivitiesView()
        case .coparentingChild(let id):
            ChildDetailView(childId: id)
        case .coparentingMessages:
            MessagesListView()
        case .coparentingMessageThread(let id):
            MessageThreadView(conversationId: id)
        case .settings:
            SettingsView()
        case .editProfile:
            EditProfileView()
        case .familyCircle(let id):
            FamilyCircleDetailView(circleId: id)
        case .familyMember(let circleId, let memberId):
            MemberDetailView(circleId: circleId, memberId: memberId)
        case .asset(let id):
            AssetDetailView(assetId: id)
        case .memberDriversLicense(let circleId, let memberId, let document):
            DriversLicenseDetailView(circleId: circleId, memberId: memberId, document: document)
        case .memberPassport(let circleId, let memberId, let document):
            PassportDetailView(circleId: circleId, memberId: memberId, document: document)
        case .memberSocialSecurity(let circleId, let memberId, let document):
            SocialSecurityDetailView(circleId: circleId, memberId: memberId, document: document)
        case .memberBirthCertificate(let circleId, let memberId, let document):
            BirthCertificateDetailView(circleId: circleId, memberId: memberId, document: document)
        case .familyResource(let circleId, let resourceId):
            FamilyResourceDetailView(circleId: circleId, resourceId: resourceId)
        case .legalDocument(let circleId, let documentId):
            LegalDocumentDetailView(circleId: circleId, documentId: documentId)
        }
    }
}

#Preview {
    DashboardView()
        .environment(AppState())
}
