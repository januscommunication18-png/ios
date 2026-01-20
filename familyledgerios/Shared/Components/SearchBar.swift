import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search..."
    var onSubmit: (() -> Void)?

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textSecondary)

            TextField(placeholder, text: $text)
                .font(AppTypography.bodyMedium)
                .focused($isFocused)
                .submitLabel(.search)
                .onSubmit {
                    onSubmit?()
                }

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textTertiary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(AppColors.secondaryBackground)
        .cornerRadius(10)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.labelMedium)
                .foregroundColor(isSelected ? .white : AppColors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? AppColors.primary : AppColors.secondaryBackground)
                .cornerRadius(20)
        }
    }
}

struct FilterBar: View {
    let filters: [String]
    @Binding var selectedFilter: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "All",
                    isSelected: selectedFilter == nil
                ) {
                    selectedFilter = nil
                }

                ForEach(filters, id: \.self) { filter in
                    FilterChip(
                        title: filter,
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct SortOption: Identifiable {
    let id = UUID()
    let title: String
    let value: String
}

struct SortMenu: View {
    let options: [SortOption]
    @Binding var selectedOption: String

    var body: some View {
        Menu {
            ForEach(options) { option in
                Button {
                    selectedOption = option.value
                } label: {
                    HStack {
                        Text(option.title)
                        if selectedOption == option.value {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.arrow.down")
                Text("Sort")
            }
            .font(AppTypography.labelMedium)
            .foregroundColor(AppColors.primary)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SearchBar(text: .constant(""))
            .padding(.horizontal)

        SearchBar(text: .constant("Family"))
            .padding(.horizontal)

        FilterBar(
            filters: ["Pending", "Completed", "Cancelled"],
            selectedFilter: .constant("Pending")
        )

        HStack {
            Text("Results")
                .font(AppTypography.headline)
            Spacer()
            SortMenu(
                options: [
                    SortOption(title: "Newest First", value: "newest"),
                    SortOption(title: "Oldest First", value: "oldest"),
                    SortOption(title: "A-Z", value: "alpha")
                ],
                selectedOption: .constant("newest")
            )
        }
        .padding(.horizontal)
    }
}
