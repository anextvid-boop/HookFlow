import SwiftUI

/// A reusable global background mesh gradient component matching the HookFlow V2 brand physics.
public struct HFAmbientAura: View {
    @State private var isFloating: Bool = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color.hfBackground.ignoresSafeArea()
            
            // Primary Core Accent (High Impact Blue)
            Circle()
                .fill(Color.hfAccent.opacity(0.4))
                .blur(radius: 120)
                .frame(width: 400, height: 400)
                .offset(x: isFloating ? -150 : 150, y: isFloating ? -200 : -100)
            
            // Secondary Striking Red/Pink
            Circle()
                .fill(Color.red.opacity(0.35))
                .blur(radius: 130)
                .frame(width: 350, height: 350)
                .offset(x: isFloating ? 200 : -100, y: isFloating ? 50 : 250)
            
            // Tertiary Vibrant Teal/Green
            Circle()
                .fill(Color.teal.opacity(0.3))
                .blur(radius: 140)
                .frame(width: 450, height: 450)
                .offset(x: isFloating ? 0 : -50, y: isFloating ? 300 : -200)
        }
        .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: isFloating)
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                isFloating = true
            }
        }
    }
}
