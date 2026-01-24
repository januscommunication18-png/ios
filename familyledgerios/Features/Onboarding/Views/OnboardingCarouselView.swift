import SwiftUI

struct OnboardingSlide: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct OnboardingCarouselView: View {
    @Binding var showSignUp: Bool
    @Environment(\.dismiss) private var dismiss

    var onSignInTapped: (() -> Void)?

    @State private var currentPage = 0

    let slides: [OnboardingSlide] = [
        OnboardingSlide(
            icon: "folder.fill.badge.person.crop",
            title: "Organize Family Documents",
            description: "Keep all your important family documents, records, and information safely organized in one secure place.",
            color: .blue
        ),
        OnboardingSlide(
            icon: "bell.badge.fill",
            title: "Never Miss Important Dates",
            description: "Set reminders for birthdays, anniversaries, document renewals, and other important family events.",
            color: .orange
        ),
        OnboardingSlide(
            icon: "person.3.fill",
            title: "Collaborate with Family",
            description: "Share access with family members and manage co-parenting schedules, expenses, and activities together.",
            color: .green
        )
    ]

    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Back button
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                            .frame(width: 40, height: 40)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.05), radius: 4)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                // Carousel
                TabView(selection: $currentPage) {
                    ForEach(Array(slides.enumerated()), id: \.element.id) { index, slide in
                        slideView(slide: slide)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page Indicator
                HStack(spacing: 8) {
                    ForEach(0..<slides.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? AppColors.primary : Color(.systemGray4))
                            .frame(width: currentPage == index ? 24 : 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                .padding(.bottom, 30)

                // Continue Button
                Button {
                    if currentPage < slides.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        showSignUp = true
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(currentPage < slides.count - 1 ? "Continue" : "Get Started")
                            .font(.system(size: 18, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.primary)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)

                // Skip button
                if currentPage < slides.count - 1 {
                    Button {
                        showSignUp = true
                    } label: {
                        Text("Skip")
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.bottom, 20)
                } else {
                    Spacer()
                        .frame(height: 40)
                }
            }
        }
    }

    private func slideView(slide: OnboardingSlide) -> some View {
        VStack(spacing: 30) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(slide.color.opacity(0.15))
                    .frame(width: 140, height: 140)

                Image(systemName: slide.icon)
                    .font(.system(size: 60))
                    .foregroundColor(slide.color)
            }

            // Title
            Text(slide.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            // Description
            Text(slide.description)
                .font(.system(size: 16))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)

            Spacer()
        }
        .padding(.top, 40)
    }
}

#Preview {
    OnboardingCarouselView(showSignUp: .constant(false))
}
