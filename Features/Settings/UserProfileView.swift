import SwiftUI
import PhotosUI

enum ProfileField: Hashable {
    case creatorName
    case businessName
    case industryNiche
    case targetAudience
    case customerPainPoint
    case coreOffer
    case brandTone
    case primaryCallToAction
}

/// The Glassmorphic Right Tab rendering the Profile Intelligence engine bounds.
struct UserProfileView: View {
    
    @EnvironmentObject private var profileManager: ProfileManager
    @FocusState private var focusedField: ProfileField?
    
    // Auto-Scroll Anchoring
    @State private var scrollPosition: ProfileField?
    
    // Magic Import State
    @State private var importURL: String = ""
    @State private var showImportAlert: Bool = false
    @State private var isImporting: Bool = false
    
    // Avatar Interaction bounds
    @State private var selectedAvatarItem: PhotosPickerItem?
    @AppStorage("userAvatarPath") private var avatarFilePath: String = ""
    @State private var uiImage: UIImage? = nil
    
    var body: some View {
        ZStack {
            // Background is implicitly the MeshGradient defined globally in HomeHubView bounds.
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: DesignTokens.Spacing.xl) {
                    
                    // MARK: - Centered Header & Personas
                    buildCenteredHeaderSection()
                    
                    Divider().padding(.vertical, DesignTokens.Spacing.md)
                    
                    // MARK: - Foundational Identity
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        Text("Business Identity")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                        
                        buildInputField(
                            title: "Creator Name / Your Name",
                            placeholder: "e.g., Alex",
                            iconName: "person.fill",
                            text: $profileManager.creatorName,
                            field: .creatorName
                        )
                        .textInputAutocapitalization(.words)
                        
                        buildInputField(
                            title: "Business Name",
                            placeholder: "e.g., HookFlow Media",
                            iconName: "building.2.fill",
                            text: $profileManager.businessName,
                            field: .businessName
                        )
                        .textInputAutocapitalization(.words)
                    }
                    
                    // MARK: - Commercial Parameters
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        Text("Commercial Parameters")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                        
                        // Magic Import Button
                        Button(action: {
                            showImportAlert = true
                        }) {
                            HStack {
                                if isImporting {
                                    ProgressView()
                                        .tint(.black)
                                } else {
                                    Image(systemName: "wand.and.stars")
                                }
                                Text(isImporting ? "Analyzing URL..." : "Auto-Fill via URL")
                            }
                            .font(.system(.subheadline, weight: .bold))
                            .foregroundStyle(.black)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Color.hfAccent)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(isImporting)
                        .alert("Magic Import", isPresented: $showImportAlert) {
                            TextField("https://yourwebsite.com", text: $importURL)
                                .keyboardType(.URL)
                                .textInputAutocapitalization(.never)
                            Button("Cancel", role: .cancel) { importURL = "" }
                            Button("Auto-Fill") {
                                performMagicImport()
                            }
                        } message: {
                            Text("Enter your website or social link to automatically extract your brand profile using AI.")
                        }
                        
                        buildInputField(
                            title: "Industry / Niche",
                            placeholder: "e.g., B2B SaaS, Fitness",
                            iconName: "building.columns.fill",
                            text: $profileManager.industryNiche,
                            field: .industryNiche
                        )
                        .textInputAutocapitalization(.never)
                        
                        buildInputField(
                            title: "Target Audience",
                            placeholder: "e.g., software agencies",
                            iconName: "person.2.fill",
                            text: $profileManager.targetAudience,
                            field: .targetAudience
                        )
                        .textInputAutocapitalization(.never)
                        
                        Text("Use plural objects (e.g. 'designers' instead of 'a designer')")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.leading, DesignTokens.Spacing.sm)
                        
                        buildInputField(
                            title: "Customer Pain Point",
                            placeholder: "e.g., spending huge money on bad ads",
                            iconName: "exclamationmark.triangle.fill",
                            text: $profileManager.customerPainPoint,
                            field: .customerPainPoint
                        )
                        .textInputAutocapitalization(.never)
                        
                        buildInputField(
                            title: "Your Core Offer",
                            placeholder: "e.g., the Automated Editing App",
                            iconName: "star.circle.fill",
                            text: $profileManager.coreOffer,
                            field: .coreOffer
                        )
                        .textInputAutocapitalization(.never)
                        
                        buildInputField(
                            title: "Brand Tone",
                            placeholder: "e.g., Casual, Professional, Urgent",
                            iconName: "speaker.wave.3.fill",
                            text: $profileManager.brandTone,
                            field: .brandTone
                        )
                        .textInputAutocapitalization(.words)
                        
                        buildInputField(
                            title: "Primary Call To Action",
                            placeholder: "e.g., Click the link in bio",
                            iconName: "link.circle.fill",
                            text: $profileManager.primaryCallToAction,
                            field: .primaryCallToAction
                        )
                        .textInputAutocapitalization(.none)
                    }
                    
                    // MARK: - Live Preview Component
                    buildLivePreviewBox()
                    
                    // Extra safe padding for the keyboard and the navigation pill
                    Spacer(minLength: 160)
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.top, DesignTokens.Spacing.xl)
            }
            .scrollPosition(id: $scrollPosition)
            .onChange(of: focusedField) { oldValue, newValue in
                if let safeFocus = newValue {
                    withAnimation(.spring()) {
                        scrollPosition = safeFocus
                    }
                } else {
                    // Focus lost, clean up strings
                    cleanWhitespaceParams()
                }
            }
        }
        .onAppear { loadAvatarImage() }
        .onChange(of: selectedAvatarItem) { _, newItem in
            Task { await saveAvatar(item: newItem) }
        }
    }
    
    // MARK: - Helper Components
    
    @ViewBuilder
    private func buildCenteredHeaderSection() -> some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            PhotosPicker(selection: $selectedAvatarItem, matching: .images) {
                if let uiImage = uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.hfAccent, lineWidth: 2))
                } else {
                    // Default Empty State
                    ZStack {
                        Circle()
                            .fill(Material.ultraThinMaterial)
                            .frame(width: 100, height: 100)
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 30))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .overlay(Circle().stroke(Color.hfAccent.opacity(0.5), lineWidth: 2))
                }
            }
            
            VStack(spacing: 4) {
                Text(profileManager.businessName.isEmpty ? "Welcome back" : "Hi, \(profileManager.businessName)")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                Text("Intelligence Engine")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.hfAccent)
                    .textCase(.uppercase)
            }
            
            // Centered Persona Pills
            HStack(spacing: DesignTokens.Spacing.md) {
                ForEach(profileManager.personas) { persona in
                    Button(action: {
                        withAnimation(.spring) {
                                profileManager.setActivePersona(id: persona.id)
                            }
                        }) {
                            Text(persona.businessName.isEmpty ? "New Profile" : persona.businessName)
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .padding(.horizontal, DesignTokens.Spacing.md)
                                .padding(.vertical, DesignTokens.Spacing.sm)
                                .background(profileManager.activePersonaID == persona.id ? Color.hfAccent : Color.white.opacity(0.1))
                                .foregroundStyle(profileManager.activePersonaID == persona.id ? .black : .white)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Button(action: {
                        let newPersona = CreatorPersona()
                        profileManager.personas.append(newPersona)
                        profileManager.setActivePersona(id: newPersona.id)
                    }) {
                        Image(systemName: "plus")
                            .font(.system(.subheadline, weight: .bold))
                            .padding(.all, DesignTokens.Spacing.sm)
                            .background(Color.white.opacity(0.1))
                            .foregroundStyle(.white)
                            .clipShape(Circle())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, DesignTokens.Spacing.md)
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private func buildInputField(title: String, placeholder: String, iconName: String, text: Binding<String>, field: ProfileField) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
            
            HStack {
                Image(systemName: iconName)
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 24)
                
                TextField(placeholder, text: text)
                    .focused($focusedField, equals: field)
                    .foregroundStyle(.white)
            }
            .padding()
            .background(Material.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(focusedField == field ? Color.hfAccent : Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .id(field)
    }
    
    @ViewBuilder
    private func buildLivePreviewBox() -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(Color.hfAccent)
                Text("Live Substitution Preview")
                    .font(.caption)
                    .textCase(.uppercase)
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
            }
            
            let demoString = "Hey [TARGET_AUDIENCE], if you're sick of [PAIN_POINT], keep watching."
            Text(demoString.hydrate(with: profileManager))
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .padding(.bottom, 60) // Extra pad over nav
    }
    
    // MARK: - Computational Physics
    
    private func cleanWhitespaceParams() {
        profileManager.industryNiche = profileManager.industryNiche.trimmingCharacters(in: .whitespacesAndNewlines)
        profileManager.targetAudience = profileManager.targetAudience.trimmingCharacters(in: .whitespacesAndNewlines)
        profileManager.customerPainPoint = profileManager.customerPainPoint.trimmingCharacters(in: .whitespacesAndNewlines)
        profileManager.coreOffer = profileManager.coreOffer.trimmingCharacters(in: .whitespacesAndNewlines)
        profileManager.brandTone = profileManager.brandTone.trimmingCharacters(in: .whitespacesAndNewlines)
        profileManager.primaryCallToAction = profileManager.primaryCallToAction.trimmingCharacters(in: .whitespacesAndNewlines)
        profileManager.businessName = profileManager.businessName.trimmingCharacters(in: .whitespacesAndNewlines)
        profileManager.creatorName = profileManager.creatorName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Phase 7: Magic Import Pipeline
    
    private func performMagicImport() {
        let trimmedURL = importURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURL.isEmpty, let url = URL(string: trimmedURL), url.scheme != nil else {
            importURL = ""
            return
        }
        
        isImporting = true
        importURL = ""
        
        // Simulating Backend AI Scraping + JSON Response
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.8)) {
                profileManager.businessName = "Simulated Brand Co"
                profileManager.industryNiche = "AI Content Solutions"
                profileManager.targetAudience = "content creators and agencies"
                profileManager.customerPainPoint = "wasting hours editing videos manually"
                profileManager.coreOffer = "the Instant AI Video Editor"
                profileManager.brandTone = "Innovative & Professional"
                profileManager.primaryCallToAction = "Start free trial from link in bio"
            }
            isImporting = false
        }
    }
    
    // Storage File Saving
    private func saveAvatar(item: PhotosPickerItem?) async {
        guard let item = item,
              let data = try? await item.loadTransferable(type: Data.self),
              let originalImage = UIImage(data: data) else { return }
        
        let fileManager = FileManager.default
        let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("userAvatar.jpg")
        
        if let compressedData = originalImage.jpegData(compressionQuality: 0.8) {
            try? compressedData.write(to: url)
            DispatchQueue.main.async {
                self.avatarFilePath = url.path
                self.uiImage = UIImage(data: compressedData)
            }
        }
    }
    
    private func loadAvatarImage() {
        if !avatarFilePath.isEmpty {
            self.uiImage = UIImage(contentsOfFile: avatarFilePath)
        }
    }
}
