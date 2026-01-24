import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section {
                    profileRow
                }

                // Account Section
                Section("Account") {
                    NavigationLink {
                        EditProfileView()
                    } label: {
                        SettingsRow(icon: "person.fill", title: "Edit Profile", color: AppColors.primary)
                    }

                    NavigationLink {
                        // TODO: Change Password
                        Text("Change Password")
                    } label: {
                        SettingsRow(icon: "lock.fill", title: "Change Password", color: AppColors.warning)
                    }
                }

                // Preferences Section
                Section("Preferences") {
                    NavigationLink {
                        // TODO: Notifications settings
                        Text("Notifications")
                    } label: {
                        SettingsRow(icon: "bell.fill", title: "Notifications", color: AppColors.reminders)
                    }

                    NavigationLink {
                        // TODO: Privacy settings
                        Text("Privacy")
                    } label: {
                        SettingsRow(icon: "hand.raised.fill", title: "Privacy", color: AppColors.family)
                    }
                }

                // Support Section
                Section("Support") {
                    NavigationLink {
                        // TODO: Help Center
                        Text("Help Center")
                    } label: {
                        SettingsRow(icon: "questionmark.circle.fill", title: "Help Center", color: AppColors.info)
                    }

                    NavigationLink {
                        // TODO: Contact Us
                        Text("Contact Us")
                    } label: {
                        SettingsRow(icon: "envelope.fill", title: "Contact Us", color: AppColors.expenses)
                    }
                }

                // About Section
                Section("About") {
                    HStack {
                        SettingsRow(icon: "info.circle.fill", title: "Version", color: AppColors.textSecondary)
                        Spacer()
                        Text("1.0.0")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textSecondary)
                    }

                    NavigationLink {
                        // TODO: Terms of Service
                        Text("Terms of Service")
                    } label: {
                        SettingsRow(icon: "doc.text.fill", title: "Terms of Service", color: AppColors.textSecondary)
                    }

                    NavigationLink {
                        // TODO: Privacy Policy
                        Text("Privacy Policy")
                    } label: {
                        SettingsRow(icon: "shield.fill", title: "Privacy Policy", color: AppColors.textSecondary)
                    }
                }

                // Logout Section
                Section {
                    Button {
                        appState.logout()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Log Out")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.error)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var profileRow: some View {
        HStack(spacing: 16) {
            // Avatar
            if let avatarUrl = appState.user?.avatar, !avatarUrl.isEmpty {
                AsyncImage(url: URL(string: avatarUrl)) { phase in
                    switch phase {
                    case .empty:
                        profilePlaceholder
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        profilePlaceholder
                    @unknown default:
                        profilePlaceholder
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
            } else {
                profilePlaceholder
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(appState.user?.displayName ?? "User")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                Text(appState.user?.email ?? "")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)

                Text(appState.user?.roleName ?? "")
                    .font(AppTypography.captionSmall)
                    .foregroundColor(AppColors.primary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var profilePlaceholder: some View {
        ZStack {
            Circle()
                .fill(AppColors.primary.opacity(0.2))

            Text(appState.user?.initials ?? "?")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.primary)
        }
        .frame(width: 60, height: 60)
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let title: String
    var color: Color = AppColors.primary

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.1))
                .cornerRadius(6)

            Text(title)
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textPrimary)
        }
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phone = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("Personal Information") {
                TextField("First Name", text: $firstName)
                    .onChange(of: firstName) { _, newValue in
                        firstName = newValue.filter { !$0.isNumber }
                    }
                TextField("Last Name", text: $lastName)
                    .onChange(of: lastName) { _, newValue in
                        lastName = newValue.filter { !$0.isNumber }
                    }
                TextField("Phone", text: $phone)
                    .keyboardType(.phonePad)
            }

            Section {
                Text(appState.user?.email ?? "")
                    .foregroundColor(AppColors.textSecondary)
            } header: {
                Text("Email")
            } footer: {
                Text("Email cannot be changed")
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    // TODO: Save profile
                }
                .disabled(isLoading)
            }
        }
        .onAppear {
            firstName = appState.user?.firstName ?? ""
            lastName = appState.user?.lastName ?? ""
            phone = appState.user?.phone ?? ""
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
}
