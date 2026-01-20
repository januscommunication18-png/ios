import SwiftUI

@Observable
final class PeopleViewModel {
    var people: [Person] = []
    var selectedPerson: Person?
    var emails: [PersonEmail] = []
    var phones: [PersonPhone] = []
    var addresses: [PersonAddress] = []
    var importantDates: [PersonImportantDate] = []
    var links: [PersonLink] = []
    var attachments: [PersonAttachment] = []
    var isLoading = false
    var errorMessage: String?

    @MainActor
    func loadPeople() async {
        isLoading = people.isEmpty
        do {
            let response: PeopleResponse = try await APIClient.shared.request(.people)
            people = response.people ?? []
        }
        catch { errorMessage = "Failed to load contacts" }
        isLoading = false
    }

    @MainActor
    func loadPerson(id: Int) async {
        isLoading = selectedPerson == nil
        do {
            let response: PersonDetailResponse = try await APIClient.shared.request(.person(id: id))
            selectedPerson = response.person
            emails = response.emails ?? []
            phones = response.phones ?? []
            addresses = response.addresses ?? []
            importantDates = response.importantDates ?? []
            links = response.links ?? []
            attachments = response.attachments ?? []
        }
        catch { errorMessage = "Failed to load contact" }
        isLoading = false
    }
}

struct PeopleListView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = PeopleViewModel()
    @State private var searchText = ""

    var filteredPeople: [Person] {
        guard !searchText.isEmpty else { return viewModel.people }
        return viewModel.people.filter { ($0.fullName ?? "").localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading contacts...")
            } else if viewModel.people.isEmpty {
                EmptyStateView.noPeople { router.navigate(to: .createPerson) }
            } else {
                List(filteredPeople) { person in
                    Button { router.navigate(to: .person(id: person.id)) } label: {
                        HStack(spacing: 12) {
                            PersonAvatarSmall(person: person)
                            VStack(alignment: .leading) {
                                Text(person.fullName ?? "\(person.firstName ?? "") \(person.lastName ?? "")").font(AppTypography.headline)
                                if let company = person.company { Text(company).font(AppTypography.caption).foregroundColor(AppColors.textSecondary) }
                            }
                            Spacer()
                            Text(person.relationshipName ?? person.relationship ?? "").font(AppTypography.captionSmall).foregroundColor(AppColors.textTertiary)
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search contacts")
            }
        }
        .navigationTitle("People")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { router.navigate(to: .createPerson) } label: { Image(systemName: "plus") }
            }
        }
        .task { await viewModel.loadPeople() }
    }
}

struct PersonAvatarSmall: View {
    let person: Person

    var body: some View {
        Group {
            if let url = person.profileImageUrl, !url.isEmpty {
                AsyncImage(url: URL(string: url)) { phase in
                    switch phase {
                    case .empty:
                        placeholder
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else { placeholder }
        }
        .frame(width: 44, height: 44)
        .clipShape(Circle())
    }

    private var placeholder: some View {
        ZStack {
            Circle().fill(AppColors.family.opacity(0.2))
            Text(person.initials).font(.system(size: 14, weight: .semibold)).foregroundColor(AppColors.family)
        }
    }
}

struct PersonDetailView: View {
    let personId: Int
    @State private var viewModel = PeopleViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading contact...")
            } else if let person = viewModel.selectedPerson {
                ScrollView {
                    VStack(spacing: 16) {
                        // Hero Card
                        heroCard(person: person)

                        // Quick Stats (Company, Birthday)
                        if person.company != nil || person.birthday != nil {
                            quickStatsRow(person: person)
                        }

                        // Contact Information
                        if !viewModel.emails.isEmpty || !viewModel.phones.isEmpty || !viewModel.addresses.isEmpty {
                            contactInfoCard(person: person)
                        }

                        // How We Know
                        if let howWeKnow = person.howWeKnow, !howWeKnow.isEmpty {
                            howWeKnowCard(text: howWeKnow)
                        }

                        // Notes
                        if let notes = person.notes, !notes.isEmpty {
                            notesCard(notes: notes)
                        }

                        // Links
                        if !viewModel.links.isEmpty {
                            linksCard()
                        }

                        // Important Dates
                        if !viewModel.importantDates.isEmpty {
                            importantDatesCard()
                        }

                        // Tags
                        if let tags = person.tags, !tags.isEmpty {
                            tagsCard(tags: tags)
                        }

                        // Record Info
                        recordInfoCard(person: person)
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
            } else {
                VStack {
                    Text("Contact not found")
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .navigationTitle(viewModel.selectedPerson?.fullName ?? "Contact")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadPerson(id: personId) }
    }

    // MARK: - Hero Card

    private func heroCard(person: Person) -> some View {
        VStack(spacing: 0) {
            // Gradient background header
            ZStack {
                LinearGradient(
                    colors: [Color.purple, Color.indigo],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: 12) {
                    // Avatar
                    PersonAvatarLarge(person: person)

                    // Name
                    Text(person.fullName ?? "\(person.firstName ?? "") \(person.lastName ?? "")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    // Nickname
                    if let nickname = person.nickname, !nickname.isEmpty {
                        Text("\"\(nickname)\"")
                            .font(AppTypography.bodySmall)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    // Badges
                    HStack(spacing: 8) {
                        // Relationship badge
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 12))
                            Text(person.relationshipName ?? person.relationship ?? "Contact")
                                .font(AppTypography.captionSmall)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.2))
                        .cornerRadius(20)
                        .foregroundColor(.white)
                    }
                }
                .padding(.vertical, 24)
            }
            .cornerRadius(16)
        }
        .background(AppColors.background)
        .cornerRadius(16)
    }

    // MARK: - Quick Stats

    private func quickStatsRow(person: Person) -> some View {
        HStack(spacing: 12) {
            // Company card
            if let company = person.company {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 36, height: 36)
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("COMPANY")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(AppColors.textTertiary)
                            Text(company)
                                .font(AppTypography.bodySmall)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            if let job = person.jobTitle {
                                Text(job)
                                    .font(AppTypography.captionSmall)
                                    .foregroundColor(AppColors.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.background)
                .cornerRadius(12)
            }

            // Birthday card
            if let birthday = person.birthday {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(LinearGradient(colors: [.pink, .red.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 36, height: 36)
                            Image(systemName: "gift.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("BIRTHDAY")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(AppColors.textTertiary)
                            Text(birthday)
                                .font(AppTypography.bodySmall)
                                .fontWeight(.semibold)
                            if let age = person.age {
                                Text("\(age) years old")
                                    .font(AppTypography.captionSmall)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.background)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Contact Info Card

    private func contactInfoCard(person: Person) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 40, height: 40)
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading) {
                    Text("Contact Information")
                        .font(AppTypography.headline)
                    Text("Email, phone & addresses")
                        .font(AppTypography.captionSmall)
                        .foregroundColor(AppColors.textTertiary)
                }
            }

            // Emails
            if !viewModel.emails.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("EMAIL ADDRESSES")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(AppColors.textTertiary)

                    ForEach(viewModel.emails, id: \.wrappedId) { email in
                        if let emailAddr = email.email {
                            HStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.blue.opacity(0.1))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "envelope.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.blue)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(emailAddr)
                                        .font(AppTypography.bodySmall)
                                        .foregroundColor(AppColors.textPrimary)
                                    Text(email.label ?? "Personal")
                                        .font(AppTypography.captionSmall)
                                        .foregroundColor(AppColors.textTertiary)
                                }
                                Spacer()
                                Link(destination: URL(string: "mailto:\(emailAddr)")!) {
                                    Image(systemName: "paperplane.fill")
                                        .foregroundColor(AppColors.primary)
                                }
                            }
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                }
            }

            // Phones
            if !viewModel.phones.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("PHONE NUMBERS")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(AppColors.textTertiary)

                    ForEach(viewModel.phones, id: \.wrappedId) { phone in
                        if let phoneNum = phone.phone {
                            HStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.green.opacity(0.1))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "phone.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.green)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(phone.formattedPhone ?? phoneNum)
                                        .font(AppTypography.bodySmall)
                                        .foregroundColor(AppColors.textPrimary)
                                    Text(phone.label ?? "Mobile")
                                        .font(AppTypography.captionSmall)
                                        .foregroundColor(AppColors.textTertiary)
                                }
                                Spacer()
                                HStack(spacing: 8) {
                                    Link(destination: URL(string: "tel:\(phoneNum)")!) {
                                        Image(systemName: "phone.fill")
                                            .foregroundColor(.green)
                                    }
                                    Link(destination: URL(string: "sms:\(phoneNum)")!) {
                                        Image(systemName: "message.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                }
            }

            // Addresses
            if !viewModel.addresses.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ADDRESSES")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(AppColors.textTertiary)

                    ForEach(viewModel.addresses) { address in
                        if let fullAddress = address.fullAddress {
                            HStack(alignment: .top) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.purple.opacity(0.1))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.purple)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(address.label ?? "Home")
                                        .font(AppTypography.captionSmall)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.purple.opacity(0.1))
                                        .foregroundColor(.purple)
                                        .cornerRadius(4)
                                    Text(fullAddress)
                                        .font(AppTypography.bodySmall)
                                        .foregroundColor(AppColors.textPrimary)
                                }
                                Spacer()
                                if let encoded = fullAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                                   let url = URL(string: "maps://?q=\(encoded)") {
                                    Link(destination: url) {
                                        Image(systemName: "map.fill")
                                            .foregroundColor(.purple)
                                    }
                                }
                            }
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                }
            }
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(16)
    }

    // MARK: - How We Know Card

    private func howWeKnowCard(text: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(colors: [.teal, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 40, height: 40)
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .foregroundColor(.white)
                }
                Text("How We Know")
                    .font(AppTypography.headline)
            }

            Text(text)
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textSecondary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(16)
    }

    // MARK: - Notes Card

    private func notesCard(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(colors: [.gray, .gray.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 40, height: 40)
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.white)
                }
                Text("Notes")
                    .font(AppTypography.headline)
            }

            Text(notes)
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textSecondary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(16)
    }

    // MARK: - Links Card

    private func linksCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 40, height: 40)
                    Image(systemName: "link")
                        .foregroundColor(.white)
                }
                Text("Links")
                    .font(AppTypography.headline)
            }

            ForEach(viewModel.links) { link in
                if let urlString = link.url, let url = URL(string: urlString) {
                    Link(destination: url) {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white)
                                    .frame(width: 32, height: 32)
                                    .shadow(color: .black.opacity(0.1), radius: 2)
                                Image(systemName: linkIcon(for: link.label))
                                    .font(.system(size: 14))
                                    .foregroundColor(linkColor(for: link.label))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(link.label ?? "Website")
                                    .font(AppTypography.bodySmall)
                                    .foregroundColor(AppColors.textPrimary)
                                Text(urlString)
                                    .font(AppTypography.captionSmall)
                                    .foregroundColor(AppColors.textTertiary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textTertiary)
                        }
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(16)
    }

    private func linkIcon(for label: String?) -> String {
        let l = label?.lowercased() ?? ""
        if l.contains("linkedin") { return "link" }
        if l.contains("facebook") { return "link" }
        if l.contains("twitter") || l.contains("x") { return "link" }
        if l.contains("instagram") { return "camera" }
        return "globe"
    }

    private func linkColor(for label: String?) -> Color {
        let l = label?.lowercased() ?? ""
        if l.contains("linkedin") { return .blue }
        if l.contains("facebook") { return .blue }
        if l.contains("twitter") || l.contains("x") { return .black }
        if l.contains("instagram") { return .pink }
        return .indigo
    }

    // MARK: - Important Dates Card

    private func importantDatesCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(colors: [.pink, .red.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 40, height: 40)
                    Image(systemName: "calendar")
                        .foregroundColor(.white)
                }
                Text("Important Dates")
                    .font(AppTypography.headline)
            }

            ForEach(viewModel.importantDates) { date in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(date.label ?? "Date")
                            .font(AppTypography.bodySmall)
                            .fontWeight(.semibold)
                        Text(date.date ?? "")
                            .font(AppTypography.captionSmall)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    Spacer()
                    if date.isAnnual == true {
                        Text("Yearly")
                            .font(AppTypography.captionSmall)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                }
                .padding(12)
                .background(
                    LinearGradient(colors: [Color.pink.opacity(0.05), Color.clear], startPoint: .leading, endPoint: .trailing)
                )
                .overlay(
                    Rectangle()
                        .fill(Color.pink)
                        .frame(width: 4),
                    alignment: .leading
                )
                .cornerRadius(8)
            }
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(16)
    }

    // MARK: - Tags Card

    private func tagsCard(tags: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 40, height: 40)
                    Image(systemName: "tag.fill")
                        .foregroundColor(.white)
                }
                Text("Tags")
                    .font(AppTypography.headline)
            }

            FlowLayout(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    HStack(spacing: 4) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 10))
                        Text(tag)
                            .font(AppTypography.captionSmall)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(colors: [Color.orange.opacity(0.1), Color.yellow.opacity(0.1)], startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundColor(.orange)
                    .cornerRadius(20)
                }
            }
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(16)
    }

    // MARK: - Record Info Card

    private func recordInfoCard(person: Person) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(colors: [.gray, .gray.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 40, height: 40)
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.white)
                }
                Text("Details")
                    .font(AppTypography.headline)
            }

            VStack(spacing: 0) {
                if let visibility = person.visibilityName {
                    recordInfoRow(label: "Visibility", value: visibility, icon: "eye.fill", color: .blue)
                    Divider()
                }
                if let source = person.sourceName {
                    recordInfoRow(label: "Source", value: source, icon: "doc.badge.plus", color: .green)
                    Divider()
                }
                if let created = person.createdAt {
                    recordInfoRow(label: "Created", value: created, icon: "calendar.badge.plus", color: .gray)
                    Divider()
                }
                if let updated = person.updatedAt, updated != person.createdAt {
                    recordInfoRow(label: "Updated", value: updated, icon: "calendar.badge.clock", color: .gray)
                }
            }
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(16)
    }

    private func recordInfoRow(label: String, value: String, icon: String? = nil, color: Color = .gray) -> some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                    .frame(width: 24)
            }
            Text(label)
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(AppTypography.bodySmall)
                .fontWeight(.medium)
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Person Avatar Large

struct PersonAvatarLarge: View {
    let person: Person

    var body: some View {
        Group {
            if let url = person.profileImageUrl, !url.isEmpty {
                AsyncImage(url: URL(string: url)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: 88, height: 88)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.3), lineWidth: 4)
        )
        .shadow(color: .black.opacity(0.2), radius: 8)
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.2))
            Text(person.initials)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// Note: FlowLayout and RoundedCorner are defined in MemberDetailView.swift

struct CreatePersonView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var firstName = ""
    @State private var lastName = ""

    var body: some View {
        Form {
            TextField("First Name", text: $firstName)
            TextField("Last Name", text: $lastName)
        }
        .navigationTitle("New Contact")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) { Button("Add") { dismiss() }.disabled(firstName.isEmpty) }
        }
    }
}
