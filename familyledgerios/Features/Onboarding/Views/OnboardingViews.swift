import SwiftUI

struct OnboardingRequest: Encodable {
    let firstName: String
    let lastName: String
    let phone: String
    let circleName: String
    let goals: [String]
    let features: [String]
    let notificationsEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case phone
        case circleName = "circle_name"
        case goals, features
        case notificationsEnabled = "notifications_enabled"
    }
}

@Observable
final class OnboardingViewModel {
    var currentStep = 1
    var totalSteps = 5

    // Step 1: Profile
    var firstName = ""
    var lastName = ""
    var phone = ""

    // Step 2: Family Circle
    var circleName = ""

    // Step 3: Goals
    var selectedGoals: Set<String> = []

    // Step 4: Features
    var selectedFeatures: Set<String> = []

    // Step 5: Preferences
    var enableNotifications = true

    var isLoading = false
    var errorMessage: String?

    let availableGoals = [
        "Track Family Expenses",
        "Manage Family Documents",
        "Plan Family Activities",
        "Track Family Health",
        "Manage Co-Parenting"
    ]

    let availableFeatures = [
        "Expenses", "Goals", "Journal", "Shopping",
        "Pets", "Reminders", "Documents", "Co-Parenting"
    ]

    func nextStep() { if currentStep < totalSteps { currentStep += 1 } }
    func previousStep() { if currentStep > 1 { currentStep -= 1 } }

    @MainActor
    func completeOnboarding(appState: AppState) async {
        isLoading = true
        do {
            let body = OnboardingRequest(
                firstName: firstName,
                lastName: lastName,
                phone: phone,
                circleName: circleName,
                goals: Array(selectedGoals),
                features: Array(selectedFeatures),
                notificationsEnabled: enableNotifications
            )
            try await APIClient.shared.requestEmpty(.updateOnboarding, body: body)
            appState.setOnboardingComplete()
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to complete onboarding"
        }
        isLoading = false
    }
}

struct OnboardingContainerView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress
                ProgressView(value: Double(viewModel.currentStep), total: Double(viewModel.totalSteps))
                    .tint(AppColors.primary)
                    .padding()

                // Content
                TabView(selection: $viewModel.currentStep) {
                    OnboardingStep1View(viewModel: viewModel).tag(1)
                    OnboardingStep2View(viewModel: viewModel).tag(2)
                    OnboardingStep3View(viewModel: viewModel).tag(3)
                    OnboardingStep4View(viewModel: viewModel).tag(4)
                    OnboardingStep5View(viewModel: viewModel, appState: appState).tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Navigation
                HStack {
                    if viewModel.currentStep > 1 {
                        Button("Back") { viewModel.previousStep() }
                            .foregroundColor(AppColors.textSecondary)
                    }
                    Spacer()
                    if viewModel.currentStep < viewModel.totalSteps {
                        Button("Next") { viewModel.nextStep() }
                            .foregroundColor(AppColors.primary)
                            .fontWeight(.semibold)
                    }
                }
                .padding()
            }
            .navigationTitle("Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        Task { await viewModel.completeOnboarding(appState: appState) }
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .loadingOverlay(viewModel.isLoading)
    }
}

struct OnboardingStep1View: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "person.fill").font(.system(size: 60)).foregroundColor(AppColors.primary)
                Text("Let's set up your profile").font(AppTypography.displaySmall)
                Text("Tell us a bit about yourself").foregroundColor(AppColors.textSecondary)

                VStack(spacing: 16) {
                    TextField("First Name", text: $viewModel.firstName).textFieldStyle()
                    TextField("Last Name", text: $viewModel.lastName).textFieldStyle()
                    TextField("Phone (optional)", text: $viewModel.phone).textFieldStyle().keyboardType(.phonePad)
                }
            }
            .padding()
        }
    }
}

struct OnboardingStep2View: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "person.3.fill").font(.system(size: 60)).foregroundColor(AppColors.family)
                Text("Create your family circle").font(AppTypography.displaySmall)
                Text("This is where your family members will be organized").foregroundColor(AppColors.textSecondary)

                TextField("Circle Name (e.g., \"Smith Family\")", text: $viewModel.circleName).textFieldStyle()
            }
            .padding()
        }
    }
}

struct OnboardingStep3View: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "target").font(.system(size: 60)).foregroundColor(AppColors.goals)
                Text("What are your goals?").font(AppTypography.displaySmall)
                Text("Select what you want to achieve").foregroundColor(AppColors.textSecondary)

                VStack(spacing: 12) {
                    ForEach(viewModel.availableGoals, id: \.self) { goal in
                        Button {
                            if viewModel.selectedGoals.contains(goal) {
                                viewModel.selectedGoals.remove(goal)
                            } else {
                                viewModel.selectedGoals.insert(goal)
                            }
                        } label: {
                            HStack {
                                Text(goal).foregroundColor(AppColors.textPrimary)
                                Spacer()
                                Image(systemName: viewModel.selectedGoals.contains(goal) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(viewModel.selectedGoals.contains(goal) ? AppColors.success : AppColors.textTertiary)
                            }
                            .padding()
                            .background(viewModel.selectedGoals.contains(goal) ? AppColors.success.opacity(0.1) : AppColors.secondaryBackground)
                            .cornerRadius(12)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct OnboardingStep4View: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "square.grid.2x2.fill").font(.system(size: 60)).foregroundColor(AppColors.primary)
                Text("Choose your features").font(AppTypography.displaySmall)
                Text("Select the features you want to use").foregroundColor(AppColors.textSecondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(viewModel.availableFeatures, id: \.self) { feature in
                        Button {
                            if viewModel.selectedFeatures.contains(feature) {
                                viewModel.selectedFeatures.remove(feature)
                            } else {
                                viewModel.selectedFeatures.insert(feature)
                            }
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: viewModel.selectedFeatures.contains(feature) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(viewModel.selectedFeatures.contains(feature) ? AppColors.success : AppColors.textTertiary)
                                Text(feature).font(AppTypography.labelMedium).foregroundColor(AppColors.textPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.selectedFeatures.contains(feature) ? AppColors.success.opacity(0.1) : AppColors.secondaryBackground)
                            .cornerRadius(12)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct OnboardingStep5View: View {
    @Bindable var viewModel: OnboardingViewModel
    let appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.seal.fill").font(.system(size: 60)).foregroundColor(AppColors.success)
                Text("You're all set!").font(AppTypography.displaySmall)
                Text("Review your settings and get started").foregroundColor(AppColors.textSecondary)

                VStack(spacing: 16) {
                    Toggle("Enable Notifications", isOn: $viewModel.enableNotifications)
                        .padding()
                        .background(AppColors.secondaryBackground)
                        .cornerRadius(12)
                }

                PrimaryButton(title: "Get Started", icon: "arrow.right", isLoading: viewModel.isLoading) {
                    Task { await viewModel.completeOnboarding(appState: appState) }
                }
            }
            .padding()
        }
    }
}
