import SwiftUI
import PhotosUI

struct CreateFamilyCircleView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @State private var name = ""
    @State private var description = ""
    @State private var includeMe = true
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedImageData: Data?
    @State private var showingImagePicker = false

    var onCircleCreated: (() -> Void)?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Icon / Photo
                    Button {
                        showingImagePicker = true
                    } label: {
                        ZStack {
                            if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(AppColors.family, lineWidth: 3)
                                    )
                            } else {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [AppColors.family, AppColors.family.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Image(systemName: "person.3.fill")
                                            .font(.system(size: 36))
                                            .foregroundColor(.white)
                                    )
                            }

                            // Camera badge
                            Circle()
                                .fill(AppColors.primary)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                )
                                .offset(x: 35, y: 35)
                        }
                    }
                    .padding(.top, 20)

                    Text("Add Circle Photo")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)

                    // Form Fields
                    VStack(spacing: 20) {
                        // Circle Name
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Circle Name")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary)
                                Text("*")
                                    .foregroundColor(.red)
                            }

                            TextField("e.g., Johnson Family", text: $name)
                                .textContentType(.name)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        }

                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Description")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary)
                                Text("(Optional)")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(.systemGray))
                            }

                            TextField("A brief description of this family circle...", text: $description, axis: .vertical)
                                .lineLimit(3...6)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        }

                        // Include Me Toggle
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                Button {
                                    includeMe.toggle()
                                } label: {
                                    Image(systemName: includeMe ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 24))
                                        .foregroundColor(includeMe ? AppColors.family : Color(.systemGray4))
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    if let userName = appState.user?.name.components(separatedBy: " ").first {
                                        Text("\(userName), would you like to include yourself in this circle?")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(AppColors.textPrimary)
                                    } else {
                                        Text("Would you like to include yourself in this circle?")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(AppColors.textPrimary)
                                    }
                                }
                            }
                            .padding()
                            .background(AppColors.family.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Error Message
                    if let error = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal, 24)
                    }

                    Spacer()
                        .frame(height: 20)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Create Family Circle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await createCircle()
                        }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Create")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                FamilyCircleImagePicker(imageData: $selectedImageData)
            }
        }
    }

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func createCircle() async {
        isLoading = true
        errorMessage = nil

        do {
            // Convert image to base64 if selected
            var photoBase64: String? = nil
            if let imageData = selectedImageData {
                photoBase64 = "data:image/jpeg;base64," + imageData.base64EncodedString()
            }

            let request = CreateFamilyCircleRequest(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
                includeMe: includeMe,
                photo: photoBase64
            )

            let _: FamilyCircleDetailResponse = try await APIClient.shared.request(.createFamilyCircle, body: request)

            await MainActor.run {
                onCircleCreated?()
                dismiss()
            }
        } catch let error as APIError {
            print("DEBUG: API Error creating circle: \(error)")
            errorMessage = error.localizedDescription
        } catch {
            print("DEBUG: Unknown error creating circle: \(error)")
            errorMessage = "Failed to create family circle: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

// MARK: - Image Picker for Family Circle

struct FamilyCircleImagePicker: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: FamilyCircleImagePicker

        init(_ parent: FamilyCircleImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()

            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else {
                return
            }

            provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                guard let image = image as? UIImage else { return }

                // Compress and resize image
                let maxSize: CGFloat = 800
                var finalImage = image

                if image.size.width > maxSize || image.size.height > maxSize {
                    let ratio = min(maxSize / image.size.width, maxSize / image.size.height)
                    let newSize = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)

                    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
                    image.draw(in: CGRect(origin: .zero, size: newSize))
                    if let resized = UIGraphicsGetImageFromCurrentImageContext() {
                        finalImage = resized
                    }
                    UIGraphicsEndImageContext()
                }

                if let data = finalImage.jpegData(compressionQuality: 0.7) {
                    DispatchQueue.main.async {
                        self?.parent.imageData = data
                    }
                }
            }
        }
    }
}

#Preview {
    CreateFamilyCircleView()
        .environment(AppState())
}
