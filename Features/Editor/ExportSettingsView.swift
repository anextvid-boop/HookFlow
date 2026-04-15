import SwiftUI

public struct ExportSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router

    @Binding var selectedQuality: RecordingQuality
    @Binding var selectedFrameRate: Int
    let estimatedSizeMB: Double
    let onExport: () -> Void
    
    // Real-time integration into RevenueCat logic
    private var isPremium: Bool {
        SubscriptionService.shared.isProActive
    }
    
    public init(selectedQuality: Binding<RecordingQuality>, selectedFrameRate: Binding<Int>, estimatedSizeMB: Double, onExport: @escaping () -> Void) {
        self._selectedQuality = selectedQuality
        self._selectedFrameRate = selectedFrameRate
        self.estimatedSizeMB = estimatedSizeMB
        self.onExport = onExport
    }
    
    public var body: some View {
        ZStack {
            Color.hfBackground.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: DesignTokens.Spacing.xl) {
                // Header
                HStack {
                    Text("Export Settings")
                        .font(HFTypography.title(size: 24))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.hfTextSecondary)
                    }
                }
                .padding(.top, DesignTokens.Spacing.lg)
                
                // Configuration Options
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Quality Picker
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        Text("Resolution")
                            .font(HFTypography.callout())
                            .foregroundColor(.hfTextTertiary)
                        
                        HStack(spacing: DesignTokens.Spacing.md) {
                            QualityOption(
                                title: "720p",
                                subtitle: "Low Size",
                                isSelected: selectedQuality == .hd720p
                            ) {
                                selectedQuality = .hd720p
                            }
                            
                            QualityOption(
                                title: "1080p",
                                subtitle: "Standard",
                                isSelected: selectedQuality == .hd1080p
                            ) {
                                selectedQuality = .hd1080p
                            }
                            
                            QualityOption(
                                title: "4K UHD",
                                subtitle: "Highest",
                                isSelected: selectedQuality == .uhd4k,
                                isPremium: true
                            ) {
                                selectedQuality = .uhd4k
                            }
                        }
                    }
                    
                    // Frame Rate Picker
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        Text("Frame Rate")
                            .font(HFTypography.callout())
                            .foregroundColor(.hfTextTertiary)
                        
                        HStack(spacing: DesignTokens.Spacing.md) {
                            FrameRateOption(title: "24", isSelected: selectedFrameRate == 24) { selectedFrameRate = 24 }
                            FrameRateOption(title: "30", isSelected: selectedFrameRate == 30) { selectedFrameRate = 30 }
                            FrameRateOption(title: "60", isSelected: selectedFrameRate == 60) { selectedFrameRate = 60 }
                        }
                    }
                    
                    // File Size Estimate
                    HStack {
                        Text("Est. Output Size:")
                            .font(HFTypography.caption())
                            .foregroundColor(.hfTextTertiary)
                        Spacer()
                        Text("~\(Int(estimatedSizeMB)) MB")
                            .font(HFTypography.body().bold())
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                // Action Trigger
                Button(action: handleExportTrigger) {
                    HStack {
                        Image(systemName: (selectedQuality == .uhd4k && !isPremium) ? "lock.fill" : "square.and.arrow.up")
                        Text(selectedQuality == .uhd4k && !isPremium ? "Unlock 4K Export" : "Render & Save")
                    }
                    .font(HFTypography.title(size: 18))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(DesignTokens.Spacing.lg)
                    // Visual state matches premium status
                    .background((selectedQuality == .uhd4k && !isPremium) ? Color.blue : Color.hfAccent)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                }
                .padding(.bottom, DesignTokens.Spacing.xl)
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.bottom, DesignTokens.Spacing.xl)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func handleExportTrigger() {
        if selectedQuality == .uhd4k && !isPremium {
            // Bridge to Phase 15 Paywall
            dismiss()
            // Using small dispatch to uncouple sheets
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                router.presentSheet(.paywall)
            }
        } else {
            dismiss()
            onExport()
        }
    }
}

private struct QualityOption: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    var isPremium: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                HStack {
                    Text(title)
                        .font(HFTypography.body())
                        .foregroundColor(isSelected ? .white : .hfTextSecondary)
                    
                    Spacer()
                    
                    if isPremium {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                    }
                }
                
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .hfTextSecondary : .hfTextTertiary)
            }
            .padding(DesignTokens.Spacing.sm)
            .background(isSelected ? Color.hfSurface : Color.black.opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .stroke(isSelected ? Color.hfAccent : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
        }
    }
}

private struct FrameRateOption: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(HFTypography.body().bold())
                .foregroundColor(isSelected ? .white : .hfTextTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background(isSelected ? Color.hfAccent : Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                        .stroke(isSelected ? Color.hfAccent : Color.clear, lineWidth: 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous))
        }
    }
}
