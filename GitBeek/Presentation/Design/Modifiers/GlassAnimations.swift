//
//  GlassAnimations.swift
//  GitBeek
//
//  Liquid Glass animations and interaction effects
//

import SwiftUI

// MARK: - Interactive Effect Modifier

/// Applies interactive response effects (scale, bounce, shimmer) to views
struct InteractiveEffectModifier: ViewModifier {
    let scaleAmount: CGFloat
    let enableBounce: Bool
    let enableShimmer: Bool

    @State private var isPressed = false
    @State private var shimmerOffset: CGFloat = -1

    init(
        scaleAmount: CGFloat = 0.97,
        enableBounce: Bool = true,
        enableShimmer: Bool = false
    ) {
        self.scaleAmount = scaleAmount
        self.enableBounce = enableBounce
        self.enableShimmer = enableShimmer
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scaleAmount : 1.0)
            .animation(
                enableBounce
                    ? .interactiveSpring(response: 0.3, dampingFraction: 0.6)
                    : .easeInOut(duration: 0.15),
                value: isPressed
            )
            .overlay {
                if enableShimmer {
                    shimmerOverlay(for: content)
                }
            }
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity) { } onPressingChanged: { pressing in
                isPressed = pressing
            }
    }

    @ViewBuilder
    private func shimmerOverlay(for content: Content) -> some View {
        GeometryReader { geometry in
            LinearGradient(
                colors: [
                    Color.white.opacity(0),
                    Color.white.opacity(0.3),
                    Color.white.opacity(0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geometry.size.width * 0.5)
            .offset(x: shimmerOffset * geometry.size.width)
            .mask(content)
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                shimmerOffset = 1.5
            }
        }
    }
}

extension View {
    /// Apply interactive effect with customizable parameters
    func interactiveEffect(
        scale: CGFloat = 0.97,
        bounce: Bool = true,
        shimmer: Bool = false
    ) -> some View {
        modifier(InteractiveEffectModifier(
            scaleAmount: scale,
            enableBounce: bounce,
            enableShimmer: shimmer
        ))
    }

    /// Apply default interactive effect
    func interactive() -> some View {
        interactiveEffect()
    }
}

// MARK: - Press Effect Modifier

/// A simpler press effect without long press gesture detection
struct PressEffectModifier: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .brightness(isPressed ? -0.05 : 0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

extension View {
    /// Apply simple press effect
    func pressEffect() -> some View {
        modifier(PressEffectModifier())
    }
}

// MARK: - Haptic Feedback

/// Haptic feedback utilities
@MainActor
enum HapticFeedback {
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    static func soft() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }

    static func rigid() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
    }

    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Haptic Modifier

struct HapticModifier: ViewModifier {
    let style: HapticStyle
    let trigger: Bool

    enum HapticStyle {
        case light, medium, heavy, soft, rigid
        case success, warning, error
        case selection
    }

    func body(content: Content) -> some View {
        content
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    triggerHaptic()
                }
            }
    }

    private func triggerHaptic() {
        switch style {
        case .light: HapticFeedback.light()
        case .medium: HapticFeedback.medium()
        case .heavy: HapticFeedback.heavy()
        case .soft: HapticFeedback.soft()
        case .rigid: HapticFeedback.rigid()
        case .success: HapticFeedback.success()
        case .warning: HapticFeedback.warning()
        case .error: HapticFeedback.error()
        case .selection: HapticFeedback.selection()
        }
    }
}

extension View {
    /// Trigger haptic feedback when condition changes to true
    func haptic(_ style: HapticModifier.HapticStyle, trigger: Bool) -> some View {
        modifier(HapticModifier(style: style, trigger: trigger))
    }
}

// MARK: - Glass Morphing Transition

/// A custom transition for glass morphing effects
struct GlassMorphTransition: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isActive ? 1 : 0)
            .scaleEffect(isActive ? 1 : 0.8)
            .blur(radius: isActive ? 0 : 10)
    }
}

extension AnyTransition {
    /// Glass morphing transition
    static var glassMorph: AnyTransition {
        .modifier(
            active: GlassMorphTransition(isActive: false),
            identity: GlassMorphTransition(isActive: true)
        )
    }

    /// Slide and fade transition
    static var slideAndFade: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    /// Scale and fade transition
    static var scaleAndFade: AnyTransition {
        .scale.combined(with: .opacity)
    }
}

// MARK: - Shimmer Loading Effect

/// A shimmer effect for loading states
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.5),
                            Color.white.opacity(0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + phase * geometry.size.width * 2)
                }
                .mask(content)
            }
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    /// Apply shimmer loading effect
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton Loading View

/// A placeholder view for loading states
struct SkeletonView: View {
    let cornerRadius: CGFloat

    init(cornerRadius: CGFloat = AppSpacing.cornerRadiusMedium) {
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.gray.opacity(0.2))
            .shimmer()
    }
}

// MARK: - Pulse Animation

/// A pulsing animation effect
struct PulseModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? 0.5 : 1.0)
            .animation(
                .easeInOut(duration: 1).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

extension View {
    /// Apply pulse animation
    func pulse() -> some View {
        modifier(PulseModifier())
    }
}

// MARK: - Bounce Animation

/// A bouncing animation effect
struct BounceModifier: ViewModifier {
    @State private var isBouncing = false
    let height: CGFloat

    func body(content: Content) -> some View {
        content
            .offset(y: isBouncing ? -height : 0)
            .animation(
                .interpolatingSpring(stiffness: 200, damping: 10)
                    .repeatForever(autoreverses: true),
                value: isBouncing
            )
            .onAppear {
                isBouncing = true
            }
    }
}

extension View {
    /// Apply bounce animation
    func bounce(height: CGFloat = 10) -> some View {
        modifier(BounceModifier(height: height))
    }
}

// MARK: - Rotation Animation

/// A continuous rotation animation
struct RotationModifier: ViewModifier {
    @State private var rotation: Double = 0
    let duration: Double

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotation))
            .animation(
                .linear(duration: duration).repeatForever(autoreverses: false),
                value: rotation
            )
            .onAppear {
                rotation = 360
            }
    }
}

extension View {
    /// Apply continuous rotation
    func rotate(duration: Double = 2) -> some View {
        modifier(RotationModifier(duration: duration))
    }
}

// MARK: - Spring Appear Animation

/// Animate view appearance with spring effect
struct SpringAppearModifier: ViewModifier {
    @State private var hasAppeared = false
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .scaleEffect(hasAppeared ? 1 : 0.5)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.6).delay(delay),
                value: hasAppeared
            )
            .onAppear {
                hasAppeared = true
            }
    }
}

extension View {
    /// Animate appearance with spring effect
    func springAppear(delay: Double = 0) -> some View {
        modifier(SpringAppearModifier(delay: delay))
    }
}

// MARK: - Preview

#Preview("Animations") {
    ZStack {
        LinearGradient(
            colors: [.blue, .purple, .pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        GlassEffectContainer {
            ScrollView {
                VStack(spacing: 30) {
                    // Interactive
                    Text("Interactive Effect")
                        .padding()
                        .glass()
                        .interactive()

                    // Press effect
                    Text("Press Effect")
                        .padding()
                        .glass()
                        .pressEffect()

                    // Shimmer
                    SkeletonView()
                        .frame(height: 60)
                        .padding(.horizontal)

                    // Pulse
                    Circle()
                        .fill(AppColors.primaryFallback)
                        .frame(width: 40, height: 40)
                        .pulse()

                    // Bounce
                    Image(systemName: "arrow.down")
                        .font(.title)
                        .foregroundStyle(.white)
                        .bounce()

                    // Rotation
                    Image(systemName: "gear")
                        .font(.largeTitle)
                        .foregroundStyle(.white)
                        .rotate()

                    // Spring appear (staggered)
                    HStack(spacing: 10) {
                        ForEach(0..<4) { index in
                            Circle()
                                .fill(Color.white)
                                .frame(width: 30, height: 30)
                                .springAppear(delay: Double(index) * 0.1)
                        }
                    }
                }
                .padding()
            }
        }
    }
}
