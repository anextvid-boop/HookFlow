import SwiftUI
import AVFoundation

public struct OnboardingView: View {
    @Environment(AppRouter.self) private var router
    @EnvironmentObject private var profileManager: ProfileManager
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @State private var currentStep: Int = 0
    
    // Focus enumeration for Profile Field natively decoupled
    private enum ProfileField: Hashable {
        case creatorName, businessName, industryNiche, targetAudience, customerPainPoint, coreOffer, brandTone, primaryCallToAction
    }
    @FocusState private var focusedField: ProfileField?
    
    public init() {}
    
    public var body: some View {
        ZStack {
            if currentStep == 0 {
                identityComponent
                    .transition(.opacity)
            } else if currentStep == 1 {
                featureOne
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            } else if currentStep == 2 {
                featureTwo
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            } else if currentStep == 3 {
                profileCapture
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            } else if currentStep == 4 {
                permissionsGateway
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentStep)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            HFAmbientAura()
        }
        .preferredColorScheme(.dark)
    }
    
    // Sub-Chunk 4.1: The Identity Component
    private var identityComponent: some View {
        ZStack {
            Text("HOOKFLOW")
                // Use strict generic V1 display structure
                .font(HFTypography.display(size: 56))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .tracking(8)
                .foregroundColor(.white)
                .shadow(color: .hfAccent.opacity(0.5), radius: 20)
        }
        .onAppear {
            Task {
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                await MainActor.run {
                    withAnimation {
                        currentStep = 1
                    }
                }
            }
        }
    }
    
    // Sub-Chunk Feature 1: Teleprompter Value Prop
    private var featureOne: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()
            
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("Shoot Faster")
                    .font(HFTypography.display(size: 40))
                    .foregroundColor(.white)
                
                Text("Speak naturally with a dynamic teleprompter that stays perfectly synced with your pace.")
                    .font(HFTypography.body())
                    .foregroundColor(.hfTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignTokens.Spacing.xl)
            }
            
            Spacer()
            
            Button(action: { withAnimation { currentStep = 2 } }) {
                Text("Continue")
                    .font(HFTypography.callout())
                    .foregroundColor(.white)
                    .padding(.vertical, DesignTokens.Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(Color.hfAccent)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                    .shadow(color: Color.hfAccent.opacity(0.3), radius: 10, y: 5)
                    .padding(.horizontal, DesignTokens.Spacing.xl)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 48)
        }
    }

    // Sub-Chunk Feature 2: Editor Value Prop
    private var featureTwo: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()
            
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("Pro Editing")
                    .font(HFTypography.display(size: 40))
                    .foregroundColor(.white)
                
                Text("Instantly stitch, crop, and drop cinematic AI auto-captions onto your footage.")
                    .font(HFTypography.body())
                    .foregroundColor(.hfTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignTokens.Spacing.xl)
            }
            
            Spacer()
            
            Button(action: { withAnimation { currentStep = 3 } }) {
                Text("Continue")
                    .font(HFTypography.callout())
                    .foregroundColor(.white)
                    .padding(.vertical, DesignTokens.Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(Color.hfAccent)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                    .shadow(color: Color.hfAccent.opacity(0.3), radius: 10, y: 5)
                    .padding(.horizontal, DesignTokens.Spacing.xl)
            }
            .buttonStyle(HFScaleButtonStyle())
            .padding(.bottom, 48)
        }
    }
    
    // Sub-Chunk Feature 3: AI Context Profile
    private var profileCapture: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Build Your Brand")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.top, 40)
                
                Text("We use this to auto-write viral hooks for you.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, DesignTokens.Spacing.md)
            
            // Form Stack
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        buildInputField(title: "Your Name / Creator Name", placeholder: "e.g., Alex", iconName: "person.fill", text: $profileManager.creatorName, field: .creatorName)
                            .textInputAutocapitalization(.words)
                        
                        buildInputField(title: "Business / Brand Name", placeholder: "e.g., HookFlow Media", iconName: "building.2.fill", text: $profileManager.businessName, field: .businessName)
                            .textInputAutocapitalization(.words)
                        
                        buildInputField(title: "Industry / Niche", placeholder: "e.g., B2B SaaS", iconName: "building.columns.fill", text: $profileManager.industryNiche, field: .industryNiche)
                            .textInputAutocapitalization(.never)
                        
                        buildInputField(title: "Target Audience", placeholder: "e.g., software agencies", iconName: "person.2.fill", text: $profileManager.targetAudience, field: .targetAudience)
                            .textInputAutocapitalization(.never)
                        
                        buildInputField(title: "Customer Pain Point", placeholder: "e.g., spending huge money on bad ads", iconName: "exclamationmark.triangle.fill", text: $profileManager.customerPainPoint, field: .customerPainPoint)
                            .textInputAutocapitalization(.never)
                        
                        buildInputField(title: "Your Core Offer", placeholder: "e.g., the Automated Editing App", iconName: "star.circle.fill", text: $profileManager.coreOffer, field: .coreOffer)
                            .textInputAutocapitalization(.never)
                        
                        buildInputField(title: "Brand Tone", placeholder: "e.g., Casual, Direct", iconName: "speaker.wave.3.fill", text: $profileManager.brandTone, field: .brandTone)
                            .textInputAutocapitalization(.words)
                        
                        buildInputField(title: "Primary Call To Action", placeholder: "e.g., Link in bio", iconName: "link.circle.fill", text: $profileManager.primaryCallToAction, field: .primaryCallToAction)
                            .textInputAutocapitalization(.none)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.bottom, 20)
            }
            // Dismiss keyboard overlay when tapping outside
            .onTapGesture {
                focusedField = nil
            }
            
            // Bottom Fixed CTA Block
            VStack(spacing: DesignTokens.Spacing.md) {
                Button(action: {
                    withAnimation { currentStep = 4 }
                }) {
                    Text(isFormComplete ? "Continue" : "Skip for now")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormComplete ? Color.hfAccent : Color.white.opacity(0.1))
                        .foregroundStyle(isFormComplete ? .black : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: isFormComplete ? Color.hfAccent.opacity(0.3) : .clear, radius: 10, y: 5)
                }
                .buttonStyle(HFScaleButtonStyle())
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.bottom, 40)
            .padding(.top, DesignTokens.Spacing.md)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
    }
    
    private var isFormComplete: Bool {
        !profileManager.creatorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !profileManager.businessName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !profileManager.industryNiche.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !profileManager.targetAudience.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !profileManager.customerPainPoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !profileManager.coreOffer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !profileManager.brandTone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !profileManager.primaryCallToAction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
    }
    
    // Sub-Chunk: Permissions Gateway
    private var permissionsGateway: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()
            
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("Enable Hardware")
                    .font(HFTypography.title(size: 32))
                    .foregroundColor(.white)
                
                Text("We need access to your camera and microphone to capture cinematic masterpieces.")
                    .font(HFTypography.body())
                    .foregroundColor(.hfTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignTokens.Spacing.xl)
            }
            
            HStack(spacing: DesignTokens.Spacing.xl) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.hfAccent)
                Image(systemName: "mic.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.hfAccent)
            }
            .padding(.top, DesignTokens.Spacing.md)
            
            Spacer()
            
            Button(action: requestPermissions) {
                Text("Continue")
                    .font(HFTypography.callout())
                    .foregroundColor(.white)
                    .padding(.vertical, DesignTokens.Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(Color.hfAccent)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                    .shadow(color: Color.hfAccent.opacity(0.3), radius: 10, y: 5)
                    .padding(.horizontal, DesignTokens.Spacing.xl)
            }
            .buttonStyle(HFScaleButtonStyle())
            .padding(.bottom, 48)
        }
    }
    
    private func requestPermissions() {
        let videoStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let audioStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        if videoStatus == .denied || audioStatus == .denied {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
            return
        }
        
        Task.detached {
            let videoWait = await AVCaptureDevice.requestAccess(for: .video)
            let audioWait = await AVCaptureDevice.requestAccess(for: .audio)
            
            if videoWait && audioWait {
                await MainActor.run {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    withAnimation {
                        // High-Conversion direct routing path exactly as ordered
                        router.activeSheet = .paywall
                        hasCompletedOnboarding = true
                    }
                }
            }
        }
    }
}

#Preview("Onboarding Flow") {
    // A robust, standard wrapper to ensure Preview dependencies don't drop
    struct PreviewHarness: View {
        @StateObject private var pm = ProfileManager()
        @State private var router = AppRouter()
        
        var body: some View {
            OnboardingView()
                .environmentObject(pm)
                .environment(router)
                .preferredColorScheme(.dark)
        }
    }
    
    return PreviewHarness()
}
