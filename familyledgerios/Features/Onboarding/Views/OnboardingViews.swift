import SwiftUI

// MARK: - Data Models

struct OnboardingGoal: Identifiable {
    let id: String
    let title: String
    let description: String
}

struct OnboardingRole: Identifiable {
    let id: String
    let title: String
    let description: String
}

struct OnboardingQuickSetup: Identifiable {
    let id: String
    let title: String
    let description: String
}

struct OnboardingCountry: Identifiable {
    let id: String
    let name: String
}

struct OnboardingFamilyType: Identifiable {
    let id: String
    let name: String
}

// MARK: - ViewModel

@Observable
final class OnboardingViewModel {
    var currentStep = 1
    let totalSteps = 5

    // Step 1: Goals
    var selectedGoals: Set<String> = []

    // Step 2: Household Setup
    var householdName = ""
    var selectedCountry = "US" // Pre-selected and fixed to United States
    var selectedTimezone = ""
    var selectedFamilyType = ""

    // Step 3: Role
    var selectedRole = ""

    // Step 4: Quick Setup
    var selectedQuickSetup: Set<String> = []

    // Step 5: Security
    var enableNotifications = true
    var enable2FA = false

    var isLoading = false
    var errorMessage: String?

    // Data
    let goals: [OnboardingGoal] = [
        OnboardingGoal(id: "documents", title: "Manage family documents", description: "Store and organize important papers"),
        OnboardingGoal(id: "coparenting", title: "Co-parenting coordination", description: "Shared schedules and communication"),
        OnboardingGoal(id: "household", title: "Household organization", description: "Lists, tasks, and family coordination"),
        OnboardingGoal(id: "financial", title: "Financial and expense tracking", description: "Budgets, bills and shared expenses"),
        OnboardingGoal(id: "all", title: "All of the above", description: "Complete family management solution"),
    ]

    let countries: [OnboardingCountry] = [
        OnboardingCountry(id: "US", name: "United States"),
        OnboardingCountry(id: "GB", name: "United Kingdom"),
        OnboardingCountry(id: "CA", name: "Canada"),
        OnboardingCountry(id: "AU", name: "Australia"),
        OnboardingCountry(id: "DE", name: "Germany"),
        OnboardingCountry(id: "FR", name: "France"),
        OnboardingCountry(id: "OTHER", name: "Other"),
    ]

    let timezones: [(id: String, name: String)] = [
        ("America/New_York", "Eastern Time (ET)"),
        ("America/Chicago", "Central Time (CT)"),
        ("America/Denver", "Mountain Time (MT)"),
        ("America/Los_Angeles", "Pacific Time (PT)"),
        ("America/Phoenix", "Arizona (MST)"),
        ("America/Anchorage", "Alaska Time (AKT)"),
        ("Pacific/Honolulu", "Hawaii Time (HT)"),
    ]

    let familyTypes: [OnboardingFamilyType] = [
        OnboardingFamilyType(id: "married", name: "Married / Partnered"),
        OnboardingFamilyType(id: "coparenting", name: "Co-parenting"),
        OnboardingFamilyType(id: "single_parent", name: "Single Parent"),
        OnboardingFamilyType(id: "multi_generation", name: "Multi-generation household"),
    ]

    let roles: [OnboardingRole] = [
        OnboardingRole(id: "parent", title: "Parent / Primary Guardian", description: "Full access to all features"),
        OnboardingRole(id: "coparent", title: "Co-parent", description: "Shared access with coordinated permissions"),
        OnboardingRole(id: "guardian", title: "Guardian", description: "Extended family or legal guardian"),
        OnboardingRole(id: "family_member", title: "Family Member", description: "Limited access to shared information"),
        OnboardingRole(id: "advisor", title: "Advisor", description: "CPA, Lawyer, Caregiver, or other professional"),
    ]

    let quickSetupOptions: [OnboardingQuickSetup] = [
        OnboardingQuickSetup(id: "documents", title: "Upload important documents", description: "Birth certificates, insurance, legal papers"),
        OnboardingQuickSetup(id: "expenses", title: "Track shared expenses", description: "Bills, budgets, and reimbursements"),
        OnboardingQuickSetup(id: "lists", title: "Create family lists", description: "Shopping, to-dos, meal planning"),
        OnboardingQuickSetup(id: "medical", title: "Add medical / insurance info", description: "Health records, providers, medications"),
    ]

    var canProceed: Bool {
        switch currentStep {
        case 1: return !selectedGoals.isEmpty
        case 2: return !householdName.isEmpty && !selectedCountry.isEmpty && !selectedTimezone.isEmpty
        case 3: return !selectedRole.isEmpty
        case 4: return !selectedQuickSetup.isEmpty
        case 5: return true
        default: return false
        }
    }

    func nextStep() {
        if currentStep < totalSteps {
            currentStep += 1
        }
    }

    func previousStep() {
        if currentStep > 1 {
            currentStep -= 1
        }
    }

    @MainActor
    func saveCurrentStep() async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            switch currentStep {
            case 1:
                let body = OnboardingStep1Request(goals: Array(selectedGoals))
                let _: OnboardingStepResponse = try await APIClient.shared.request(
                    .saveOnboardingStep(step: currentStep),
                    body: body
                )
            case 2:
                let body = OnboardingStep2Request(
                    name: householdName,
                    country: selectedCountry,
                    timezone: selectedTimezone,
                    familyType: selectedFamilyType.isEmpty ? nil : selectedFamilyType
                )
                let _: OnboardingStepResponse = try await APIClient.shared.request(
                    .saveOnboardingStep(step: currentStep),
                    body: body
                )
            case 3:
                let body = OnboardingStep3Request(role: selectedRole)
                let _: OnboardingStepResponse = try await APIClient.shared.request(
                    .saveOnboardingStep(step: currentStep),
                    body: body
                )
            case 4:
                let body = OnboardingStep4Request(features: Array(selectedQuickSetup))
                let _: OnboardingStepResponse = try await APIClient.shared.request(
                    .saveOnboardingStep(step: currentStep),
                    body: body
                )
            case 5:
                let body = OnboardingStep5Request(enableNotifications: enableNotifications, enable2fa: enable2FA)
                let _: OnboardingStepResponse = try await APIClient.shared.request(
                    .saveOnboardingStep(step: currentStep),
                    body: body
                )
            default:
                break
            }
            isLoading = false
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to save progress"
        }

        isLoading = false
        return false
    }

    @MainActor
    func completeOnboarding(appState: AppState) async {
        // First save step 5
        let saved = await saveCurrentStep()
        if !saved {
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let _: OnboardingCompleteResponse = try await APIClient.shared.request(.completeOnboarding)
            appState.setOnboardingComplete()
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to complete setup"
        }

        isLoading = false
    }
}

// MARK: - Request Models

struct OnboardingStep1Request: Encodable {
    let goals: [String]
}

struct OnboardingStep2Request: Encodable {
    let name: String
    let country: String
    let timezone: String
    let familyType: String?

    enum CodingKeys: String, CodingKey {
        case name, country, timezone
        case familyType = "family_type"
    }
}

struct OnboardingStep3Request: Encodable {
    let role: String
}

struct OnboardingStep4Request: Encodable {
    let features: [String]
}

struct OnboardingStep5Request: Encodable {
    let enableNotifications: Bool
    let enable2fa: Bool

    enum CodingKeys: String, CodingKey {
        case enableNotifications = "enable_notifications"
        case enable2fa = "enable_2fa"
    }
}

// MARK: - Response Models

struct OnboardingStepResponse: Decodable {
    let step: Int?
    let nextStep: Int?

    enum CodingKeys: String, CodingKey {
        case step
        case nextStep = "next_step"
    }
}

struct OnboardingCompleteResponse: Decodable {
    let completed: Bool?
    let redirect: String?
}

// MARK: - Container View

struct OnboardingContainerView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(1...viewModel.totalSteps, id: \.self) { step in
                        Capsule()
                            .fill(step <= viewModel.currentStep ? AppColors.primary : Color(.systemGray4))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // Step content
                TabView(selection: $viewModel.currentStep) {
                    OnboardingStep1View(viewModel: viewModel).tag(1)
                    OnboardingStep2View(viewModel: viewModel).tag(2)
                    OnboardingStep3View(viewModel: viewModel).tag(3)
                    OnboardingStep4View(viewModel: viewModel).tag(4)
                    OnboardingStep5View(viewModel: viewModel, appState: appState).tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: viewModel.currentStep)

                // Error message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                // Navigation buttons
                HStack {
                    if viewModel.currentStep > 1 {
                        Button("Back") {
                            viewModel.previousStep()
                        }
                        .foregroundColor(AppColors.textSecondary)
                    }

                    Spacer()

                    Button {
                        Task {
                            if viewModel.currentStep == viewModel.totalSteps {
                                await viewModel.completeOnboarding(appState: appState)
                            } else {
                                let saved = await viewModel.saveCurrentStep()
                                if saved {
                                    viewModel.nextStep()
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(viewModel.currentStep == viewModel.totalSteps ? "Complete Setup" : "Continue")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(viewModel.canProceed ? AppColors.primary : AppColors.primary.opacity(0.5))
                        .cornerRadius(8)
                    }
                    .disabled(!viewModel.canProceed || viewModel.isLoading)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Step 1: Goals

struct OnboardingStep1View: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome! Let's get started")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)

                    Text("What's your primary goal for using this app?")
                        .font(.system(size: 15))
                        .foregroundColor(AppColors.textSecondary)

                    Text("Select all that apply")
                        .font(.system(size: 13))
                        .foregroundColor(Color(.systemGray))
                        .padding(.top, 4)
                }

                VStack(spacing: 12) {
                    ForEach(viewModel.goals) { goal in
                        GoalSelectionRow(
                            goal: goal,
                            isSelected: viewModel.selectedGoals.contains(goal.id)
                        ) {
                            if viewModel.selectedGoals.contains(goal.id) {
                                viewModel.selectedGoals.remove(goal.id)
                            } else {
                                viewModel.selectedGoals.insert(goal.id)
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
    }
}

struct GoalSelectionRow: View {
    let goal: OnboardingGoal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? AppColors.primary : Color(.systemGray4))

                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)

                    Text(goal.description)
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()
            }
            .padding(16)
            .background(isSelected ? AppColors.primary.opacity(0.05) : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppColors.primary : Color(.systemGray4), lineWidth: 1)
            )
        }
    }
}

// MARK: - Step 2: Household Setup

struct OnboardingStep2View: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Set up your household")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)

                    Text("Define your family unit and preferences")
                        .font(.system(size: 15))
                        .foregroundColor(AppColors.textSecondary)
                }

                VStack(spacing: 20) {
                    // Household name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Household name *")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)

                        TextField("e.g., Smith Family", text: $viewModel.householdName)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )

                        Text("This is your first family circle")
                            .font(.system(size: 12))
                            .foregroundColor(Color(.systemGray))
                    }

                    // Country (Fixed to United States)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Country / Region")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)

                        HStack {
                            Text("United States")
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundColor(AppColors.primary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    }

                    // Timezone
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Timezone *")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)

                        Menu {
                            ForEach(viewModel.timezones, id: \.id) { tz in
                                Button(tz.name) {
                                    viewModel.selectedTimezone = tz.id
                                }
                            }
                        } label: {
                            HStack {
                                Text(viewModel.selectedTimezone.isEmpty ? "Select timezone" :
                                        viewModel.timezones.first { $0.id == viewModel.selectedTimezone }?.name ?? viewModel.selectedTimezone)
                                    .foregroundColor(viewModel.selectedTimezone.isEmpty ? Color(.placeholderText) : AppColors.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(Color(.systemGray))
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                        }
                    }

                    // Family type (optional)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Family type (optional)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)

                        Menu {
                            Button("None") {
                                viewModel.selectedFamilyType = ""
                            }
                            ForEach(viewModel.familyTypes) { type in
                                Button(type.name) {
                                    viewModel.selectedFamilyType = type.id
                                }
                            }
                        } label: {
                            HStack {
                                Text(viewModel.selectedFamilyType.isEmpty ? "Select family type" :
                                        viewModel.familyTypes.first { $0.id == viewModel.selectedFamilyType }?.name ?? "")
                                    .foregroundColor(viewModel.selectedFamilyType.isEmpty ? Color(.placeholderText) : AppColors.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(Color(.systemGray))
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                        }
                    }
                }
            }
            .padding(24)
        }
    }
}

// MARK: - Step 3: Role Selection

struct OnboardingStep3View: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What's your role?")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)

                    Text("This helps us set appropriate permissions and features")
                        .font(.system(size: 15))
                        .foregroundColor(AppColors.textSecondary)
                }

                VStack(spacing: 12) {
                    ForEach(viewModel.roles) { role in
                        RoleSelectionRow(
                            role: role,
                            isSelected: viewModel.selectedRole == role.id
                        ) {
                            viewModel.selectedRole = role.id
                        }
                    }
                }
            }
            .padding(24)
        }
    }
}

struct RoleSelectionRow: View {
    let role: OnboardingRole
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isSelected ? "circle.inset.filled" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? AppColors.primary : Color(.systemGray4))

                VStack(alignment: .leading, spacing: 4) {
                    Text(role.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)

                    Text(role.description)
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()
            }
            .padding(16)
            .background(isSelected ? AppColors.primary.opacity(0.05) : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppColors.primary : Color(.systemGray4), lineWidth: 1)
            )
        }
    }
}

// MARK: - Step 4: Quick Setup

struct OnboardingStep4View: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What do you want to set up first?")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)

                    Text("Select one or more to get started quickly")
                        .font(.system(size: 15))
                        .foregroundColor(AppColors.textSecondary)
                }

                VStack(spacing: 12) {
                    ForEach(viewModel.quickSetupOptions) { option in
                        QuickSetupOptionRowView(
                            option: option,
                            isSelected: viewModel.selectedQuickSetup.contains(option.id)
                        ) {
                            if viewModel.selectedQuickSetup.contains(option.id) {
                                viewModel.selectedQuickSetup.remove(option.id)
                            } else {
                                viewModel.selectedQuickSetup.insert(option.id)
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
    }
}

struct QuickSetupOptionRowView: View {
    let option: OnboardingQuickSetup
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? AppColors.primary : Color(.systemGray4))

                VStack(alignment: .leading, spacing: 4) {
                    Text(option.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)

                    Text(option.description)
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()
            }
            .padding(16)
            .background(isSelected ? AppColors.primary.opacity(0.05) : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppColors.primary : Color(.systemGray4), lineWidth: 1)
            )
        }
    }
}

// MARK: - Step 5: Security

struct OnboardingStep5View: View {
    @Bindable var viewModel: OnboardingViewModel
    let appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Security & privacy")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)

                    Text("Your data is encrypted and only shared with people you approve")
                        .font(.system(size: 15))
                        .foregroundColor(AppColors.textSecondary)
                }

                // Security features info
                VStack(spacing: 12) {
                    SecurityFeatureRow(
                        icon: "shield.checkered",
                        title: "End-to-end encryption",
                        description: "Your sensitive documents and data are encrypted at rest and in transit"
                    )

                    SecurityFeatureRow(
                        icon: "lock.fill",
                        title: "Role-based permissions",
                        description: "Control exactly who can view and edit different types of information"
                    )

                    SecurityFeatureRow(
                        icon: "lifepreserver.fill",
                        title: "Emergency access",
                        description: "Designate trusted contacts who can access critical information when needed"
                    )
                }

                Divider()
                    .padding(.vertical, 8)

                // Preferences
                VStack(spacing: 16) {
                    Toggle(isOn: $viewModel.enableNotifications) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Email notifications")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppColors.textPrimary)
                            Text("Get updates about important events and changes")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .tint(AppColors.primary)

                    // 2FA hidden for now
                    // Toggle(isOn: $viewModel.enable2FA) {
                    //     VStack(alignment: .leading, spacing: 4) {
                    //         Text("Two-factor authentication")
                    //             .font(.system(size: 16, weight: .medium))
                    //             .foregroundColor(AppColors.textPrimary)
                    //         Text("Recommended for extra security")
                    //             .font(.system(size: 14))
                    //             .foregroundColor(AppColors.textSecondary)
                    //     }
                    // }
                    // .tint(AppColors.primary)
                }

                Text("By continuing, you agree to our Terms of Service and Privacy Policy. We never sell your data.")
                    .font(.system(size: 12))
                    .foregroundColor(Color(.systemGray))
                    .padding(.top, 8)
            }
            .padding(24)
        }
    }
}

struct SecurityFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.green)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    OnboardingContainerView()
        .environment(AppState())
}
