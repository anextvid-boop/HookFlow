import SwiftUI

public struct ColorGradingSheet: View {
    @Binding var brightness: Double
    @Binding var contrast: Double
    @Binding var saturation: Double
    var onDismiss: () -> Void
    
    public var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Color Grading")
                    .font(HFTypography.title(size: 20))
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    withAnimation {
                        // Reset defaults
                        brightness = 0.0
                        contrast = 1.0
                        saturation = 1.0
                    }
                }) {
                    Text("Reset")
                        .font(HFTypography.callout())
                        .foregroundColor(.hfAccent)
                }
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)
            
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Maps core values nicely into UI-friendly percentages
                ColorSlider(title: "Brightness", value: $brightness, range: -1.0...1.0)
                ColorSlider(title: "Contrast", value: $contrast, range: 0.0...2.0)
                ColorSlider(title: "Saturation", value: $saturation, range: 0.0...2.0)
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .background(Color.hfBackground.ignoresSafeArea())
    }
}

fileprivate struct ColorSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    
    // Maps the actual logic domain values to a consistent visual range of -100 to 100
    private var displayValue: Int {
        if title == "Brightness" {
            return Int(value * 100)
        } else {
            return Int((value - 1.0) * 100)
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(HFTypography.caption())
                    .foregroundColor(.hfTextTertiary)
                Spacer()
                Text("\(displayValue)")
                    .font(HFTypography.caption())
                    .foregroundColor(displayValue == 0 ? .hfTextTertiary : .white)
                    .frame(width: 40, alignment: .trailing)
            }
            
            Slider(value: $value, in: range)
                .accentColor(.hfAccent)
        }
    }
}
