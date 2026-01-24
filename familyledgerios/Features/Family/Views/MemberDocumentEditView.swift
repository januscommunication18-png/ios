import SwiftUI
import PhotosUI

struct MemberDocumentEditView: View {
    let circleId: Int
    let memberId: Int
    let documentType: DocumentType
    let existingDocument: MemberDocument?
    var onSave: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = FamilyViewModel()

    // Form fields
    @State private var documentNumber = ""
    @State private var stateOfIssue = ""
    @State private var countryOfIssue = ""
    @State private var issueDate: Date?
    @State private var expiryDate: Date?

    // Image fields
    @State private var frontImage: UIImage?
    @State private var backImage: UIImage?
    @State private var showingFrontImagePicker = false
    @State private var showingBackImagePicker = false
    @State private var selectedFrontItem: PhotosPickerItem?
    @State private var selectedBackItem: PhotosPickerItem?
    @State private var existingFrontImageUrl: String?
    @State private var existingBackImageUrl: String?
    @State private var hasChangedFrontImage = false
    @State private var hasChangedBackImage = false

    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""

    enum DocumentType: String, CaseIterable {
        case driversLicense = "drivers_license"
        case passport = "passport"
        case socialSecurity = "social_security"
        case birthCertificate = "birth_certificate"

        var title: String {
            switch self {
            case .driversLicense: return "Driver's License"
            case .passport: return "Passport"
            case .socialSecurity: return "Social Security"
            case .birthCertificate: return "Birth Certificate"
            }
        }

        var icon: String {
            switch self {
            case .driversLicense: return "car.fill"
            case .passport: return "book.closed.fill"
            case .socialSecurity: return "lock.shield.fill"
            case .birthCertificate: return "doc.text.fill"
            }
        }

        var hasExpiry: Bool {
            switch self {
            case .driversLicense, .passport: return true
            case .socialSecurity, .birthCertificate: return false
            }
        }

        var hasIssueDate: Bool {
            switch self {
            case .driversLicense, .passport, .birthCertificate: return true
            case .socialSecurity: return false
            }
        }

        var numberLabel: String {
            switch self {
            case .driversLicense: return "License Number"
            case .passport: return "Passport Number"
            case .socialSecurity: return "SSN"
            case .birthCertificate: return "Certificate Number"
            }
        }

        var numberPlaceholder: String {
            switch self {
            case .driversLicense: return "e.g., D1234567"
            case .passport: return "e.g., A12345678"
            case .socialSecurity: return "123-45-6789"
            case .birthCertificate: return "e.g., BC-123456"
            }
        }

        var isNumberRequired: Bool {
            switch self {
            case .driversLicense, .passport, .socialSecurity: return true
            case .birthCertificate: return false
            }
        }

        var locationLabel: String {
            switch self {
            case .driversLicense: return "State of Issue"
            case .passport: return "Country of Issue"
            case .birthCertificate: return "State/Country of Issue"
            case .socialSecurity: return ""
            }
        }

        var locationPlaceholder: String {
            switch self {
            case .driversLicense: return "e.g., California"
            case .passport: return "e.g., United States"
            case .birthCertificate: return "e.g., California or United States"
            case .socialSecurity: return ""
            }
        }

        var frontImageLabel: String {
            switch self {
            case .driversLicense: return "Front Image"
            case .passport: return "Photo Page"
            case .socialSecurity: return "Front of Card"
            case .birthCertificate: return "Front of Certificate"
            }
        }

        var backImageLabel: String {
            switch self {
            case .driversLicense: return "Back Image"
            case .passport: return "Additional Pages"
            case .socialSecurity: return "Back of Card"
            case .birthCertificate: return "Back of Certificate"
            }
        }
    }

    var isEditing: Bool {
        existingDocument != nil && existingDocument?.id ?? 0 > 0
    }

    var body: some View {
        Form {
                // Document Details Section
                Section {
                    // Document Number
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(documentType.numberLabel)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            if documentType.isNumberRequired {
                                Text("*")
                                    .foregroundColor(.red)
                            }
                        }

                        if documentType == .socialSecurity {
                            TextField(documentType.numberPlaceholder, text: $documentNumber)
                                .keyboardType(.numberPad)
                                .font(.system(.body, design: .monospaced))
                                .onChange(of: documentNumber) { _, newValue in
                                    documentNumber = formatSSN(newValue)
                                }
                        } else {
                            TextField(documentType.numberPlaceholder, text: $documentNumber)
                                .textInputAutocapitalization(.characters)
                        }
                    }

                    // Location (State/Country of Issue) - not for Social Security
                    if !documentType.locationLabel.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(documentType.locationLabel)
                                .font(.subheadline)
                                .foregroundColor(.primary)

                            if documentType == .passport {
                                TextField(documentType.locationPlaceholder, text: $countryOfIssue)
                            } else {
                                TextField(documentType.locationPlaceholder, text: $stateOfIssue)
                            }
                        }
                    }
                } header: {
                    Label("\(documentType.title) Details", systemImage: documentType.icon)
                }

                // Dates Section - not for Social Security
                if documentType.hasIssueDate || documentType.hasExpiry {
                    Section {
                        if documentType.hasIssueDate {
                            DatePicker(
                                "Issue Date",
                                selection: Binding(
                                    get: { issueDate ?? Date() },
                                    set: { issueDate = $0 }
                                ),
                                displayedComponents: .date
                            )

                            if issueDate != nil {
                                Button("Clear Issue Date") {
                                    issueDate = nil
                                }
                                .foregroundColor(.red)
                                .font(.caption)
                            }
                        }

                        if documentType.hasExpiry {
                            DatePicker(
                                "Expiry Date",
                                selection: Binding(
                                    get: { expiryDate ?? Date() },
                                    set: { expiryDate = $0 }
                                ),
                                displayedComponents: .date
                            )

                            if expiryDate != nil {
                                Button("Clear Expiry Date") {
                                    expiryDate = nil
                                }
                                .foregroundColor(.red)
                                .font(.caption)
                            }
                        }
                    } header: {
                        Label("Dates", systemImage: "calendar")
                    }
                }

                // Document Images Section
                Section {
                    // Front Image
                    VStack(alignment: .leading, spacing: 8) {
                        Text(documentType.frontImageLabel)
                            .font(.subheadline)
                            .foregroundColor(.primary)

                        PhotosPicker(selection: $selectedFrontItem, matching: .images) {
                            if let frontImage = frontImage {
                                Image(uiImage: frontImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 120)
                                    .frame(maxWidth: .infinity)
                                    .clipped()
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            } else {
                                ImagePlaceholder(label: "Upload \(documentType.frontImageLabel)")
                            }
                        }
                        .onChange(of: selectedFrontItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    frontImage = image
                                    hasChangedFrontImage = true
                                }
                            }
                        }

                        if frontImage != nil {
                            Button("Remove Image") {
                                frontImage = nil
                                selectedFrontItem = nil
                                hasChangedFrontImage = true
                            }
                            .foregroundColor(.red)
                            .font(.caption)
                        }
                    }

                    // Back Image
                    VStack(alignment: .leading, spacing: 8) {
                        Text(documentType.backImageLabel)
                            .font(.subheadline)
                            .foregroundColor(.primary)

                        PhotosPicker(selection: $selectedBackItem, matching: .images) {
                            if let backImage = backImage {
                                Image(uiImage: backImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 120)
                                    .frame(maxWidth: .infinity)
                                    .clipped()
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            } else {
                                ImagePlaceholder(label: "Upload \(documentType.backImageLabel)")
                            }
                        }
                        .onChange(of: selectedBackItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    backImage = image
                                    hasChangedBackImage = true
                                }
                            }
                        }

                        if backImage != nil {
                            Button("Remove Image") {
                                backImage = nil
                                selectedBackItem = nil
                                hasChangedBackImage = true
                            }
                            .foregroundColor(.red)
                            .font(.caption)
                        }
                    }
                } header: {
                    Label("Document Images", systemImage: "photo")
                } footer: {
                    Text("PNG, JPG up to 2MB")
                }
            }
        .navigationTitle(isEditing ? "Edit \(documentType.title)" : "Add \(documentType.title)")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        await saveDocument()
                    }
                }
                .disabled((documentType.isNumberRequired && documentNumber.isEmpty) || isSaving)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            loadExistingData()
        }
    }

    private func loadExistingData() {
        guard let doc = existingDocument else { return }

        documentNumber = doc.documentNumber ?? ""
        stateOfIssue = doc.issuingState ?? ""
        countryOfIssue = doc.issuingCountry ?? ""

        if let issueDateStr = doc.issueDate {
            issueDate = parseDate(issueDateStr)
        }

        if let expiryDateStr = doc.expiryDate {
            expiryDate = parseDate(expiryDateStr)
        }

        // Load existing image URLs
        existingFrontImageUrl = doc.frontImageUrl
        existingBackImageUrl = doc.backImageUrl

        // Load images from URLs
        if let frontUrl = doc.frontImageUrl, !frontUrl.isEmpty {
            loadImageFromUrl(frontUrl) { image in
                DispatchQueue.main.async {
                    self.frontImage = image
                }
            }
        }

        if let backUrl = doc.backImageUrl, !backUrl.isEmpty {
            loadImageFromUrl(backUrl) { image in
                DispatchQueue.main.async {
                    self.backImage = image
                }
            }
        }
    }

    private func loadImageFromUrl(_ urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                completion(image)
            } else {
                completion(nil)
            }
        }.resume()
    }

    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func formatSSN(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }
        let limited = String(digits.prefix(9))

        var result = ""
        for (index, char) in limited.enumerated() {
            if index == 3 || index == 5 {
                result += "-"
            }
            result.append(char)
        }
        return result
    }

    private func imageToBase64(_ image: UIImage?) -> String? {
        guard let image = image,
              let imageData = image.jpegData(compressionQuality: 0.8) else { return nil }
        return "data:image/jpeg;base64," + imageData.base64EncodedString()
    }

    private func saveDocument() async {
        isSaving = true

        // Only send images if they have been changed
        let frontImageData = hasChangedFrontImage ? imageToBase64(frontImage) : nil
        let backImageData = hasChangedBackImage ? imageToBase64(backImage) : nil

        let request = MemberDocumentRequest(
            documentType: documentType.rawValue,
            documentNumber: documentNumber.isEmpty ? nil : documentNumber,
            issuingState: stateOfIssue.isEmpty ? nil : stateOfIssue,
            issuingCountry: countryOfIssue.isEmpty ? nil : countryOfIssue,
            issueDate: issueDate != nil ? formatDate(issueDate!) : nil,
            expiryDate: expiryDate != nil ? formatDate(expiryDate!) : nil,
            frontImage: frontImageData,
            backImage: backImageData
        )

        let success: Bool
        if isEditing, let docId = existingDocument?.id {
            success = await viewModel.updateDocument(
                circleId: circleId,
                memberId: memberId,
                documentId: docId,
                request: request
            )
        } else {
            success = await viewModel.createDocument(
                circleId: circleId,
                memberId: memberId,
                request: request
            )
        }

        isSaving = false

        if success {
            onSave?()
            dismiss()
        } else {
            errorMessage = viewModel.errorMessage ?? "Failed to save document"
            showError = true
        }
    }
}

// MARK: - Image Placeholder

struct ImagePlaceholder: View {
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.blue)

            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)

            Text("PNG, JPG up to 2MB")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [6]))
                .foregroundColor(Color.gray.opacity(0.4))
        )
    }
}

// MARK: - Request Model

struct MemberDocumentRequest: Encodable {
    let documentType: String
    let documentNumber: String?
    let issuingState: String?
    let issuingCountry: String?
    let issueDate: String?
    let expiryDate: String?
    let frontImage: String?
    let backImage: String?

    enum CodingKeys: String, CodingKey {
        case documentType = "document_type"
        case documentNumber = "document_number"
        case issuingState = "issuing_state"
        case issuingCountry = "issuing_country"
        case issueDate = "issue_date"
        case expiryDate = "expiry_date"
        case frontImage = "front_image"
        case backImage = "back_image"
    }
}

struct MemberDocumentResponse: Codable {
    let document: MemberDocument?
    let message: String?
}

#Preview {
    MemberDocumentEditView(
        circleId: 1,
        memberId: 1,
        documentType: .driversLicense,
        existingDocument: nil
    )
}
