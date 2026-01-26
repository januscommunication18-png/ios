import SwiftUI
import Combine
import PhotosUI
import UniformTypeIdentifiers

struct AddSchoolRecordView: View {
    let circleId: Int
    let memberId: Int
    let isMinor: Bool
    var onSave: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddSchoolRecordViewModel()

    // Document upload states
    @State private var showingDocumentPicker = false
    @State private var showingAddDocumentSheet = false
    @State private var pendingDocuments: [PendingDocument] = []
    @State private var currentDocumentData: Data?
    @State private var currentDocumentName: String = ""
    @State private var currentDocumentMimeType: String = ""
    @State private var newDocumentType: String = "other"
    @State private var newDocumentTitle: String = ""

    var body: some View {
        ScrollView {
                VStack(spacing: 20) {
                    // School Information Card
                    VStack(alignment: .leading, spacing: 16) {
                        SchoolSectionHeader(icon: "building.2.fill", title: "School Information", subtitle: "Basic school details", color: AppColors.info)

                        VStack(spacing: 16) {
                            // School Name (Required)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("School Name *")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary)

                                TextField("e.g., Lincoln Elementary School", text: $viewModel.schoolName)
                                    .textFieldStyle(RoundedTextFieldStyle())
                            }

                            HStack(spacing: 12) {
                                // School Year
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("School Year")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppColors.textSecondary)

                                    TextField("e.g., 2024-2025", text: $viewModel.schoolYear)
                                        .textFieldStyle(RoundedTextFieldStyle())
                                }

                                // Grade Level
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Grade Level")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppColors.textSecondary)

                                    Picker("Grade", selection: $viewModel.gradeLevel) {
                                        Text("Select grade").tag("")
                                        ForEach(viewModel.gradeLevels, id: \.key) { grade in
                                            Text(grade.value).tag(grade.key)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                }
                            }

                            // Student ID
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Student ID")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary)

                                TextField("Student ID number", text: $viewModel.studentId)
                                    .textFieldStyle(RoundedTextFieldStyle())
                            }

                            // Is Current
                            Toggle(isOn: $viewModel.isCurrent) {
                                Text("This is the current school")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.textPrimary)
                            }
                            .tint(AppColors.info)

                            // School Address
                            VStack(alignment: .leading, spacing: 6) {
                                Text("School Address")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary)

                                TextField("Full school address", text: $viewModel.schoolAddress)
                                    .textFieldStyle(RoundedTextFieldStyle())
                            }

                            HStack(spacing: 12) {
                                // School Phone
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("School Phone")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppColors.textSecondary)

                                    TextField("(555) 123-4567", text: $viewModel.schoolPhone)
                                        .textFieldStyle(RoundedTextFieldStyle())
                                        .keyboardType(.phonePad)
                                }

                                // School Email
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("School Email")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppColors.textSecondary)

                                    TextField("office@school.edu", text: $viewModel.schoolEmail)
                                        .textFieldStyle(RoundedTextFieldStyle())
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(AppColors.background)
                    .cornerRadius(16)

                    // Teacher & Counselor Card (Only for minors)
                    if isMinor {
                        VStack(alignment: .leading, spacing: 16) {
                            SchoolSectionHeader(icon: "person.2.fill", title: "Teacher & Counselor", subtitle: "Staff contact information", color: AppColors.success)

                            VStack(spacing: 16) {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Teacher Name")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(AppColors.textSecondary)

                                        TextField("Teacher's full name", text: $viewModel.teacherName)
                                            .textFieldStyle(RoundedTextFieldStyle())
                                    }

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Teacher Email")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(AppColors.textSecondary)

                                        TextField("teacher@school.edu", text: $viewModel.teacherEmail)
                                            .textFieldStyle(RoundedTextFieldStyle())
                                            .keyboardType(.emailAddress)
                                            .autocapitalization(.none)
                                    }
                                }

                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Counselor Name")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(AppColors.textSecondary)

                                        TextField("Counselor's full name", text: $viewModel.counselorName)
                                            .textFieldStyle(RoundedTextFieldStyle())
                                    }

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Counselor Email")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(AppColors.textSecondary)

                                        TextField("counselor@school.edu", text: $viewModel.counselorEmail)
                                            .textFieldStyle(RoundedTextFieldStyle())
                                            .keyboardType(.emailAddress)
                                            .autocapitalization(.none)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(AppColors.background)
                        .cornerRadius(16)

                        // Bus Information Card (Only for minors)
                        VStack(alignment: .leading, spacing: 16) {
                            SchoolSectionHeader(icon: "bus.fill", title: "Bus Information", subtitle: "Transportation details", color: AppColors.warning)

                            VStack(spacing: 16) {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Bus Number")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(AppColors.textSecondary)

                                        TextField("e.g., 42", text: $viewModel.busNumber)
                                            .textFieldStyle(RoundedTextFieldStyle())
                                    }

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Pickup Time")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(AppColors.textSecondary)

                                        TextField("e.g., 7:30 AM", text: $viewModel.busPickupTime)
                                            .textFieldStyle(RoundedTextFieldStyle())
                                    }

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Dropoff Time")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(AppColors.textSecondary)

                                        TextField("e.g., 3:30 PM", text: $viewModel.busDropoffTime)
                                            .textFieldStyle(RoundedTextFieldStyle())
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(AppColors.background)
                        .cornerRadius(16)
                    }

                    // Notes Card
                    VStack(alignment: .leading, spacing: 16) {
                        SchoolSectionHeader(icon: "note.text", title: "Notes", subtitle: "Additional information", color: AppColors.textSecondary)

                        TextEditor(text: $viewModel.notes)
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    .padding()
                    .background(AppColors.background)
                    .cornerRadius(16)

                    // Documents Card
                    VStack(alignment: .leading, spacing: 16) {
                        SchoolSectionHeader(icon: "doc.fill", title: "Documents", subtitle: "Report cards, transcripts, etc.", color: AppColors.success)

                        // Pending documents list
                        if !pendingDocuments.isEmpty {
                            VStack(spacing: 8) {
                                ForEach(pendingDocuments) { doc in
                                    HStack(spacing: 12) {
                                        Image(systemName: doc.iconName)
                                            .font(.system(size: 20))
                                            .foregroundColor(AppColors.info)
                                            .frame(width: 32)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(doc.title)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(AppColors.textPrimary)
                                                .lineLimit(1)

                                            Text(doc.documentTypeName)
                                                .font(.system(size: 12))
                                                .foregroundColor(AppColors.textSecondary)
                                        }

                                        Spacer()

                                        Button {
                                            pendingDocuments.removeAll { $0.id == doc.id }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(AppColors.textTertiary)
                                        }
                                    }
                                    .padding(12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                }
                            }
                        }

                        // Add document button
                        Button {
                            showingDocumentPicker = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18))
                                Text("Add Document")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(AppColors.info)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppColors.info.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(AppColors.background)
                    .cornerRadius(16)
                }
                .padding()
            }
            .fileImporter(
                isPresented: $showingDocumentPicker,
                allowedContentTypes: [.pdf, .jpeg, .png, .image],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Add School Record")
            .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        await viewModel.saveSchoolRecord(circleId: circleId, memberId: memberId, documents: pendingDocuments)
                        if viewModel.saveSuccess {
                            onSave?()
                            dismiss()
                        }
                    }
                } label: {
                    if viewModel.isSaving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Save")
                            .fontWeight(.semibold)
                    }
                }
                .disabled(viewModel.schoolName.isEmpty || viewModel.isSaving)
                .foregroundColor(viewModel.schoolName.isEmpty ? AppColors.textTertiary : AppColors.info)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .sheet(isPresented: $showingAddDocumentSheet) {
            AddDocumentDetailsSheet(
                documentTypes: viewModel.documentTypes,
                documentType: $newDocumentType,
                documentTitle: $newDocumentTitle,
                fileName: currentDocumentName,
                onSave: {
                    if let data = currentDocumentData {
                        let doc = PendingDocument(
                            data: data,
                            fileName: currentDocumentName,
                            mimeType: currentDocumentMimeType,
                            documentType: newDocumentType,
                            title: newDocumentTitle.isEmpty ? currentDocumentName : newDocumentTitle
                        )
                        pendingDocuments.append(doc)
                    }
                    resetDocumentFields()
                    showingAddDocumentSheet = false
                },
                onCancel: {
                    resetDocumentFields()
                    showingAddDocumentSheet = false
                }
            )
        }
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            // Start accessing the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let data = try Data(contentsOf: url)
                currentDocumentData = data
                currentDocumentName = url.lastPathComponent
                currentDocumentMimeType = getMimeType(for: url)
                newDocumentTitle = ""
                newDocumentType = "other"
                showingAddDocumentSheet = true
            } catch {
                viewModel.errorMessage = "Failed to read file: \(error.localizedDescription)"
                viewModel.showError = true
            }
        case .failure(let error):
            viewModel.errorMessage = "Failed to select file: \(error.localizedDescription)"
            viewModel.showError = true
        }
    }

    private func getMimeType(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "pdf": return "application/pdf"
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "doc": return "application/msword"
        case "docx": return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        default: return "application/octet-stream"
        }
    }

    private func resetDocumentFields() {
        currentDocumentData = nil
        currentDocumentName = ""
        currentDocumentMimeType = ""
        newDocumentType = "other"
        newDocumentTitle = ""
    }
}

// MARK: - Pending Document Model

struct PendingDocument: Identifiable {
    let id = UUID()
    let data: Data
    let fileName: String
    let mimeType: String
    let documentType: String
    let title: String

    var iconName: String {
        if mimeType.contains("pdf") {
            return "doc.fill"
        } else if mimeType.contains("image") {
            return "photo.fill"
        } else {
            return "doc.text.fill"
        }
    }

    var documentTypeName: String {
        let types: [String: String] = [
            "report_card": "Report Card",
            "transcript": "Transcript",
            "diploma": "Diploma",
            "certificate": "Certificate",
            "award": "Award",
            "iep": "IEP",
            "504_plan": "504 Plan",
            "enrollment": "Enrollment Document",
            "immunization": "Immunization Record",
            "other": "Other"
        ]
        return types[documentType] ?? "Document"
    }
}

// MARK: - Add Document Details Sheet

struct AddDocumentDetailsSheet: View {
    let documentTypes: [(key: String, value: String)]
    @Binding var documentType: String
    @Binding var documentTitle: String
    let fileName: String
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: "doc.fill")
                            .foregroundColor(AppColors.info)
                        Text(fileName)
                            .lineLimit(1)
                    }
                } header: {
                    Text("Selected File")
                }

                Section {
                    Picker("Document Type", selection: $documentType) {
                        ForEach(documentTypes, id: \.key) { type in
                            Text(type.value).tag(type.key)
                        }
                    }

                    TextField("Document Title", text: $documentTitle)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Document Details")
                } footer: {
                    Text("Give your document a descriptive title")
                }
            }
            .navigationTitle("Add Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onSave()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Section Header

struct SchoolSectionHeader: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textTertiary)
            }
        }
    }
}

// MARK: - Rounded Text Field Style

struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
    }
}

// MARK: - View Model

@MainActor
class AddSchoolRecordViewModel: ObservableObject {
    @Published var schoolName = ""
    @Published var schoolYear = ""
    @Published var gradeLevel = ""
    @Published var studentId = ""
    @Published var isCurrent = true
    @Published var schoolAddress = ""
    @Published var schoolPhone = ""
    @Published var schoolEmail = ""
    @Published var teacherName = ""
    @Published var teacherEmail = ""
    @Published var counselorName = ""
    @Published var counselorEmail = ""
    @Published var busNumber = ""
    @Published var busPickupTime = ""
    @Published var busDropoffTime = ""
    @Published var notes = ""

    @Published var isSaving = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var saveSuccess = false

    let gradeLevels: [(key: String, value: String)] = [
        ("pre_k", "Pre-Kindergarten"),
        ("kindergarten", "Kindergarten"),
        ("1st", "1st Grade"),
        ("2nd", "2nd Grade"),
        ("3rd", "3rd Grade"),
        ("4th", "4th Grade"),
        ("5th", "5th Grade"),
        ("6th", "6th Grade"),
        ("7th", "7th Grade"),
        ("8th", "8th Grade"),
        ("9th", "9th Grade (Freshman)"),
        ("10th", "10th Grade (Sophomore)"),
        ("11th", "11th Grade (Junior)"),
        ("12th", "12th Grade (Senior)"),
        ("college_freshman", "College Freshman"),
        ("college_sophomore", "College Sophomore"),
        ("college_junior", "College Junior"),
        ("college_senior", "College Senior"),
        ("graduate", "Graduate School"),
        ("other", "Other")
    ]

    let documentTypes: [(key: String, value: String)] = [
        ("report_card", "Report Card"),
        ("transcript", "Transcript"),
        ("diploma", "Diploma"),
        ("certificate", "Certificate"),
        ("award", "Award"),
        ("iep", "IEP (Individualized Education Program)"),
        ("504_plan", "504 Plan"),
        ("enrollment", "Enrollment Document"),
        ("immunization", "Immunization Record"),
        ("other", "Other")
    ]

    func saveSchoolRecord(circleId: Int, memberId: Int, documents: [PendingDocument] = []) async {
        isSaving = true

        do {
            let request = CreateSchoolRecordRequest(
                schoolName: schoolName,
                schoolYear: schoolYear.isEmpty ? nil : schoolYear,
                gradeLevel: gradeLevel.isEmpty ? nil : gradeLevel,
                studentId: studentId.isEmpty ? nil : studentId,
                isCurrent: isCurrent,
                schoolAddress: schoolAddress.isEmpty ? nil : schoolAddress,
                schoolPhone: schoolPhone.isEmpty ? nil : schoolPhone,
                schoolEmail: schoolEmail.isEmpty ? nil : schoolEmail,
                teacherName: teacherName.isEmpty ? nil : teacherName,
                teacherEmail: teacherEmail.isEmpty ? nil : teacherEmail,
                counselorName: counselorName.isEmpty ? nil : counselorName,
                counselorEmail: counselorEmail.isEmpty ? nil : counselorEmail,
                busNumber: busNumber.isEmpty ? nil : busNumber,
                busPickupTime: busPickupTime.isEmpty ? nil : busPickupTime,
                busDropoffTime: busDropoffTime.isEmpty ? nil : busDropoffTime,
                notes: notes.isEmpty ? nil : notes
            )

            let response: CreateSchoolRecordResponse = try await APIClient.shared.request(
                APIEndpoint.storeSchoolRecord(circleId: circleId, memberId: memberId),
                body: request
            )

            // Upload documents if any
            let schoolRecordId = response.schoolRecord?.id
            for document in documents {
                await uploadDocument(
                    circleId: circleId,
                    memberId: memberId,
                    schoolRecordId: schoolRecordId,
                    document: document
                )
            }

            saveSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isSaving = false
    }

    private func uploadDocument(circleId: Int, memberId: Int, schoolRecordId: Int?, document: PendingDocument) async {
        do {
            let base64Data = document.data.base64EncodedString()
            let request = CreateEducationDocumentRequest(
                documentType: document.documentType,
                title: document.title,
                description: nil,
                schoolYear: schoolYear.isEmpty ? nil : schoolYear,
                gradeLevel: gradeLevel.isEmpty ? nil : gradeLevel,
                schoolRecordId: schoolRecordId,
                file: base64Data,
                fileName: document.fileName,
                mimeType: document.mimeType
            )

            let _: CreateEducationDocumentResponse = try await APIClient.shared.request(
                APIEndpoint.storeEducationDocument(circleId: circleId, memberId: memberId),
                body: request
            )
        } catch {
            // Log error but don't fail the whole operation
            print("Failed to upload document: \(error.localizedDescription)")
        }
    }
}

// MARK: - Request/Response Models

struct CreateSchoolRecordRequest: Encodable {
    let schoolName: String
    let schoolYear: String?
    let gradeLevel: String?
    let studentId: String?
    let isCurrent: Bool
    let schoolAddress: String?
    let schoolPhone: String?
    let schoolEmail: String?
    let teacherName: String?
    let teacherEmail: String?
    let counselorName: String?
    let counselorEmail: String?
    let busNumber: String?
    let busPickupTime: String?
    let busDropoffTime: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case notes
        case schoolName = "school_name"
        case schoolYear = "school_year"
        case gradeLevel = "grade_level"
        case studentId = "student_id"
        case isCurrent = "is_current"
        case schoolAddress = "school_address"
        case schoolPhone = "school_phone"
        case schoolEmail = "school_email"
        case teacherName = "teacher_name"
        case teacherEmail = "teacher_email"
        case counselorName = "counselor_name"
        case counselorEmail = "counselor_email"
        case busNumber = "bus_number"
        case busPickupTime = "bus_pickup_time"
        case busDropoffTime = "bus_dropoff_time"
    }
}

struct CreateSchoolRecordResponse: Codable {
    let schoolRecord: SchoolRecordBasic?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case schoolRecord = "school_record"
        case message
    }
}

struct SchoolRecordBasic: Codable {
    let id: Int
    let schoolName: String?
    let gradeLevel: String?
    let gradeLevelName: String?
    let schoolYear: String?
    let isCurrent: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case schoolName = "school_name"
        case gradeLevel = "grade_level"
        case gradeLevelName = "grade_level_name"
        case schoolYear = "school_year"
        case isCurrent = "is_current"
    }
}

struct CreateEducationDocumentRequest: Encodable {
    let documentType: String
    let title: String
    let description: String?
    let schoolYear: String?
    let gradeLevel: String?
    let schoolRecordId: Int?
    let file: String
    let fileName: String
    let mimeType: String

    enum CodingKeys: String, CodingKey {
        case documentType = "document_type"
        case title
        case description
        case schoolYear = "school_year"
        case gradeLevel = "grade_level"
        case schoolRecordId = "school_record_id"
        case file
        case fileName = "file_name"
        case mimeType = "mime_type"
    }
}

struct CreateEducationDocumentResponse: Codable {
    let document: EducationDocumentBasic?
    let message: String?
}

struct EducationDocumentBasic: Codable {
    let id: Int
    let documentType: String?
    let documentTypeName: String?
    let title: String?
    let fileName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case documentType = "document_type"
        case documentTypeName = "document_type_name"
        case title
        case fileName = "file_name"
    }
}

// MARK: - Edit School Record View

struct EditSchoolRecordView: View {
    let circleId: Int
    let memberId: Int
    let schoolRecord: MemberSchoolInfo
    let isMinor: Bool
    var onSave: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = EditSchoolRecordViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // School Information Card
                    VStack(alignment: .leading, spacing: 16) {
                        SchoolSectionHeader(icon: "building.2.fill", title: "School Information", subtitle: "Basic school details", color: AppColors.info)

                        VStack(spacing: 16) {
                            // School Name (Required)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("School Name *")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary)

                                TextField("e.g., Lincoln Elementary School", text: $viewModel.schoolName)
                                    .textFieldStyle(RoundedTextFieldStyle())
                            }

                            HStack(spacing: 12) {
                                // School Year
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("School Year")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppColors.textSecondary)

                                    TextField("e.g., 2024-2025", text: $viewModel.schoolYear)
                                        .textFieldStyle(RoundedTextFieldStyle())
                                }

                                // Grade Level
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Grade Level")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppColors.textSecondary)

                                    Picker("Grade", selection: $viewModel.gradeLevel) {
                                        Text("Select grade").tag("")
                                        ForEach(viewModel.gradeLevels, id: \.key) { grade in
                                            Text(grade.value).tag(grade.key)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                }
                            }

                            // Student ID
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Student ID")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary)

                                TextField("Student ID number", text: $viewModel.studentId)
                                    .textFieldStyle(RoundedTextFieldStyle())
                            }

                            // Is Current
                            Toggle(isOn: $viewModel.isCurrent) {
                                Text("This is the current school")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.textPrimary)
                            }
                            .tint(AppColors.info)

                            // School Address
                            VStack(alignment: .leading, spacing: 6) {
                                Text("School Address")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary)

                                TextField("Full school address", text: $viewModel.schoolAddress)
                                    .textFieldStyle(RoundedTextFieldStyle())
                            }

                            HStack(spacing: 12) {
                                // School Phone
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("School Phone")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppColors.textSecondary)

                                    TextField("(555) 123-4567", text: $viewModel.schoolPhone)
                                        .textFieldStyle(RoundedTextFieldStyle())
                                        .keyboardType(.phonePad)
                                }

                                // School Email
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("School Email")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppColors.textSecondary)

                                    TextField("office@school.edu", text: $viewModel.schoolEmail)
                                        .textFieldStyle(RoundedTextFieldStyle())
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(AppColors.background)
                    .cornerRadius(16)

                    // Teacher & Counselor Card (Only for minors)
                    if isMinor {
                        VStack(alignment: .leading, spacing: 16) {
                            SchoolSectionHeader(icon: "person.2.fill", title: "Teacher & Counselor", subtitle: "Staff contact information", color: AppColors.success)

                            VStack(spacing: 16) {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Teacher Name")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(AppColors.textSecondary)

                                        TextField("Teacher's full name", text: $viewModel.teacherName)
                                            .textFieldStyle(RoundedTextFieldStyle())
                                    }

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Teacher Email")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(AppColors.textSecondary)

                                        TextField("teacher@school.edu", text: $viewModel.teacherEmail)
                                            .textFieldStyle(RoundedTextFieldStyle())
                                            .keyboardType(.emailAddress)
                                            .autocapitalization(.none)
                                    }
                                }

                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Counselor Name")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(AppColors.textSecondary)

                                        TextField("Counselor's full name", text: $viewModel.counselorName)
                                            .textFieldStyle(RoundedTextFieldStyle())
                                    }

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Counselor Email")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(AppColors.textSecondary)

                                        TextField("counselor@school.edu", text: $viewModel.counselorEmail)
                                            .textFieldStyle(RoundedTextFieldStyle())
                                            .keyboardType(.emailAddress)
                                            .autocapitalization(.none)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(AppColors.background)
                        .cornerRadius(16)

                        // Bus Information Card (Only for minors)
                        VStack(alignment: .leading, spacing: 16) {
                            SchoolSectionHeader(icon: "bus.fill", title: "Bus Information", subtitle: "Transportation details", color: AppColors.warning)

                            VStack(spacing: 16) {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Bus Number")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(AppColors.textSecondary)

                                        TextField("e.g., 42", text: $viewModel.busNumber)
                                            .textFieldStyle(RoundedTextFieldStyle())
                                    }

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Pickup Time")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(AppColors.textSecondary)

                                        TextField("e.g., 7:30 AM", text: $viewModel.busPickupTime)
                                            .textFieldStyle(RoundedTextFieldStyle())
                                    }

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Dropoff Time")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(AppColors.textSecondary)

                                        TextField("e.g., 3:30 PM", text: $viewModel.busDropoffTime)
                                            .textFieldStyle(RoundedTextFieldStyle())
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(AppColors.background)
                        .cornerRadius(16)
                    }

                    // Notes Card
                    VStack(alignment: .leading, spacing: 16) {
                        SchoolSectionHeader(icon: "note.text", title: "Notes", subtitle: "Additional information", color: AppColors.textSecondary)

                        TextEditor(text: $viewModel.notes)
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    .padding()
                    .background(AppColors.background)
                    .cornerRadius(16)

                    // Existing Documents Card
                    if let documents = schoolRecord.documents, !documents.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            SchoolSectionHeader(icon: "doc.fill", title: "Documents", subtitle: "Uploaded documents", color: AppColors.success)

                            VStack(spacing: 12) {
                                ForEach(documents) { document in
                                    EditDocumentRow(
                                        document: document,
                                        circleId: circleId,
                                        memberId: memberId,
                                        onDelete: {
                                            // Refresh will happen when sheet dismisses
                                        }
                                    )
                                }
                            }
                        }
                        .padding()
                        .background(AppColors.background)
                        .cornerRadius(16)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Edit School Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await viewModel.updateSchoolRecord(
                                circleId: circleId,
                                memberId: memberId,
                                schoolRecordId: schoolRecord.id
                            )
                            if viewModel.saveSuccess {
                                onSave?()
                                dismiss()
                            }
                        }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(viewModel.schoolName.isEmpty || viewModel.isSaving)
                    .foregroundColor(viewModel.schoolName.isEmpty ? AppColors.textTertiary : AppColors.info)
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .onAppear {
                viewModel.loadFromSchoolRecord(schoolRecord)
            }
        }
    }
}

// MARK: - Edit Document Row

struct EditDocumentRow: View {
    let document: MemberEducationDocument
    let circleId: Int
    let memberId: Int
    let onDelete: () -> Void

    @State private var showDeleteAlert = false
    @State private var isDeleting = false

    var body: some View {
        HStack(spacing: 12) {
            // File icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.info.opacity(0.1))
                    .frame(width: 44, height: 44)

                Image(systemName: document.fileIcon)
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.info)
            }

            // Document info
            VStack(alignment: .leading, spacing: 4) {
                Text(document.displayTitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let typeName = document.documentTypeName {
                        Text(typeName)
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                    }

                    if let fileSize = document.formattedFileSize {
                        Text("•")
                            .foregroundColor(AppColors.textTertiary)
                        Text(fileSize)
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
            }

            Spacer()

            // View button
            if let fileUrl = document.fileUrl, let url = URL(string: fileUrl) {
                Button {
                    UIApplication.shared.open(url)
                } label: {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.info)
                        .padding(8)
                        .background(AppColors.info.opacity(0.1))
                        .cornerRadius(6)
                }
            }

            // Delete button
            Button {
                showDeleteAlert = true
            } label: {
                if isDeleting {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 32, height: 32)
                } else {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(6)
                }
            }
            .disabled(isDeleting)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .alert("Delete Document", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteDocument()
                }
            }
        } message: {
            Text("Are you sure you want to delete this document?")
        }
    }

    private func deleteDocument() async {
        isDeleting = true
        do {
            try await APIClient.shared.requestEmpty(
                APIEndpoint.deleteEducationDocument(circleId: circleId, memberId: memberId, documentId: document.id)
            )
            onDelete()
        } catch {
            print("Failed to delete document: \(error.localizedDescription)")
        }
        isDeleting = false
    }
}

// MARK: - Edit School Record View Model

@MainActor
class EditSchoolRecordViewModel: ObservableObject {
    @Published var schoolName = ""
    @Published var schoolYear = ""
    @Published var gradeLevel = ""
    @Published var studentId = ""
    @Published var isCurrent = true
    @Published var schoolAddress = ""
    @Published var schoolPhone = ""
    @Published var schoolEmail = ""
    @Published var teacherName = ""
    @Published var teacherEmail = ""
    @Published var counselorName = ""
    @Published var counselorEmail = ""
    @Published var busNumber = ""
    @Published var busPickupTime = ""
    @Published var busDropoffTime = ""
    @Published var notes = ""

    @Published var isSaving = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var saveSuccess = false

    let gradeLevels: [(key: String, value: String)] = [
        ("pre_k", "Pre-Kindergarten"),
        ("kindergarten", "Kindergarten"),
        ("1st", "1st Grade"),
        ("2nd", "2nd Grade"),
        ("3rd", "3rd Grade"),
        ("4th", "4th Grade"),
        ("5th", "5th Grade"),
        ("6th", "6th Grade"),
        ("7th", "7th Grade"),
        ("8th", "8th Grade"),
        ("9th", "9th Grade (Freshman)"),
        ("10th", "10th Grade (Sophomore)"),
        ("11th", "11th Grade (Junior)"),
        ("12th", "12th Grade (Senior)"),
        ("college_freshman", "College Freshman"),
        ("college_sophomore", "College Sophomore"),
        ("college_junior", "College Junior"),
        ("college_senior", "College Senior"),
        ("graduate", "Graduate School"),
        ("other", "Other")
    ]

    func loadFromSchoolRecord(_ record: MemberSchoolInfo) {
        schoolName = record.schoolName ?? ""
        schoolYear = record.schoolYear ?? ""
        gradeLevel = record.gradeLevel ?? ""
        studentId = record.studentId ?? ""
        isCurrent = record.isCurrent ?? true
        schoolAddress = record.schoolAddress ?? ""
        schoolPhone = record.schoolPhone ?? ""
        schoolEmail = record.schoolEmail ?? ""
        teacherName = record.teacherName ?? ""
        teacherEmail = record.teacherEmail ?? ""
        counselorName = record.counselorName ?? ""
        counselorEmail = record.counselorEmail ?? ""
        busNumber = record.busNumber ?? ""
        busPickupTime = record.busPickupTime ?? ""
        busDropoffTime = record.busDropoffTime ?? ""
        notes = record.notes ?? ""
    }

    func updateSchoolRecord(circleId: Int, memberId: Int, schoolRecordId: Int) async {
        isSaving = true

        do {
            let request = CreateSchoolRecordRequest(
                schoolName: schoolName,
                schoolYear: schoolYear.isEmpty ? nil : schoolYear,
                gradeLevel: gradeLevel.isEmpty ? nil : gradeLevel,
                studentId: studentId.isEmpty ? nil : studentId,
                isCurrent: isCurrent,
                schoolAddress: schoolAddress.isEmpty ? nil : schoolAddress,
                schoolPhone: schoolPhone.isEmpty ? nil : schoolPhone,
                schoolEmail: schoolEmail.isEmpty ? nil : schoolEmail,
                teacherName: teacherName.isEmpty ? nil : teacherName,
                teacherEmail: teacherEmail.isEmpty ? nil : teacherEmail,
                counselorName: counselorName.isEmpty ? nil : counselorName,
                counselorEmail: counselorEmail.isEmpty ? nil : counselorEmail,
                busNumber: busNumber.isEmpty ? nil : busNumber,
                busPickupTime: busPickupTime.isEmpty ? nil : busPickupTime,
                busDropoffTime: busDropoffTime.isEmpty ? nil : busDropoffTime,
                notes: notes.isEmpty ? nil : notes
            )

            let _: CreateSchoolRecordResponse = try await APIClient.shared.request(
                APIEndpoint.updateSchoolRecord(circleId: circleId, memberId: memberId, schoolRecordId: schoolRecordId),
                body: request
            )

            saveSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isSaving = false
    }
}
