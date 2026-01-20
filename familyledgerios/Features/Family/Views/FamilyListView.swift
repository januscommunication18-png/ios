import SwiftUI

struct FamilyListView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @State private var viewModel = FamilyViewModel()

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            Group {
                if viewModel.isLoading {
                    LoadingView(message: "Loading family circles...")
                } else if let error = viewModel.errorMessage {
                    ErrorView(message: error) {
                        Task {
                            await viewModel.loadCircles()
                        }
                    }
                } else if viewModel.hasCircles {
                    circlesList
                } else {
                    EmptyStateView.noFamilyCircles {
                        // TODO: Navigate to create circle
                    }
                }
            }
            .navigationTitle("Family")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.refreshCircles()
            }
            .task {
                await viewModel.loadCircles()
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .familyCircle(let id):
                    FamilyCircleDetailView(circleId: id)
                case .familyMember(let circleId, let memberId):
                    MemberDetailView(circleId: circleId, memberId: memberId)
                case .documents:
                    DocumentsView()
                case .insurancePolicy(let id):
                    InsurancePolicyDetailView(policyId: id)
                case .taxReturn(let id):
                    TaxReturnDetailView(returnId: id)
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
                default:
                    EmptyView()
                }
            }
        }
        .environment(router)
    }

    private var circlesList: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Co-Parenting Banner (if any member has co-parenting enabled)
                coparentingBanner

                // Circles
                ForEach(viewModel.circles) { circle in
                    FamilyCircleCard(circle: circle) {
                        router.navigate(to: .familyCircle(id: circle.id))
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    @ViewBuilder
    private var coparentingBanner: some View {
        // Check if any circle has co-parenting members
        let hasCoparenting = viewModel.circles.contains { circle in
            circle.members?.contains { $0.coParentingEnabled == true } == true
        }

        if hasCoparenting {
            Button {
                router.navigate(to: .coparenting)
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "figure.2.and.child.holdinghands")
                        .font(.system(size: 24))
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Co-Parenting")
                            .font(AppTypography.headline)
                            .foregroundColor(.white)

                        Text("Manage shared custody and communication")
                            .font(AppTypography.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .background(AppColors.coparentingGradient)
                .cornerRadius(16)
            }
        }
    }
}

// MARK: - Family Circle Card

struct FamilyCircleCard: View {
    let circle: FamilyCircle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    // Circle Image or Placeholder
                    if let imageUrl = circle.coverImageUrl, !imageUrl.isEmpty {
                        AsyncImage(url: URL(string: imageUrl)) { phase in
                            switch phase {
                            case .empty:
                                circlePlaceholder
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                circlePlaceholder
                            @unknown default:
                                circlePlaceholder
                            }
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        circlePlaceholder
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(circle.name)
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)

                        Text("\(circle.membersCount ?? 0) member\((circle.membersCount ?? 0) == 1 ? "" : "s")")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)

                        if let description = circle.description, !description.isEmpty {
                            Text(description)
                                .font(AppTypography.captionSmall)
                                .foregroundColor(AppColors.textTertiary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textTertiary)
                }

                // Member Avatars Preview
                if let members = circle.members, !members.isEmpty {
                    HStack(spacing: -8) {
                        ForEach(members.prefix(5)) { member in
                            MemberAvatarSmall(member: member)
                        }

                        if members.count > 5 {
                            Text("+\(members.count - 5)")
                                .font(AppTypography.captionSmall)
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.leading, 12)
                        }
                    }
                }
            }
            .padding()
            .background(AppColors.background)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var circlePlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.family.opacity(0.2))

            Image(systemName: "person.3.fill")
                .font(.system(size: 24))
                .foregroundColor(AppColors.family)
        }
        .frame(width: 60, height: 60)
    }
}

// MARK: - Member Avatar Small

struct MemberAvatarSmall: View {
    let member: FamilyMemberBasic

    var body: some View {
        Group {
            if let imageUrl = member.profileImageUrl, !imageUrl.isEmpty {
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
        .frame(width: 32, height: 32)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(AppColors.background, lineWidth: 2)
        )
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Circle()
                .fill(AppColors.family.opacity(0.2))

            Text(member.initials)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(AppColors.family)
        }
    }
}

#Preview {
    FamilyListView()
        .environment(AppState())
}
