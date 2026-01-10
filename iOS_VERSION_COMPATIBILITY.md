# iOS Version Compatibility Guide

## Overview

GitBeek is optimized for iOS 26 with Liquid Glass design, but fully compatible with iOS 18+ through intelligent fallback mechanisms.

## Minimum Requirements

- **Minimum iOS Version**: iOS 18.0
- **Recommended iOS Version**: iOS 26.0+
- **Target Devices**: iPhone, iPad

## Feature Matrix

| Feature | iOS 26 | iOS 18-25 | Implementation |
|---------|--------|-----------|----------------|
| **Liquid Glass Effects** | ✅ Native `.glassEffect()` | ⚠️ Fallback to `.ultraThinMaterial` | Auto-detected |
| **Glass Transitions** | ✅ `.glassEffectID()` | ⚠️ `.matchedGeometryEffect()` | Auto-detected |
| **Interactive Glass** | ✅ `.interactive()` | ✅ Custom implementation | Always available |
| **Background Extension** | ✅ `.backgroundExtensionEffect()` | ⚙️ No-op | Auto-detected |
| **Scroll Edge Effects** | ✅ `.scrollEdgeEffectStyle()` | ⚙️ No-op | Auto-detected |
| **Tab Bar Behavior** | ✅ `.tabBarMinimizeBehavior()` | ⚙️ Standard behavior | Auto-detected |
| **Core Features** | ✅ Full support | ✅ Full support | Always available |
| **Markdown Rendering** | ✅ Full support | ✅ Full support | Always available |
| **Code Highlighting** | ✅ 185+ languages | ✅ 185+ languages | Always available |
| **Offline Support** | ✅ Planned | ✅ Planned | Platform-agnostic |

## How It Works

### Automatic Version Detection

All Liquid Glass components use `@available(iOS 26.0, *)` checks to automatically provide the best experience for each iOS version:

```swift
if #available(iOS 26.0, *) {
    // Use native Liquid Glass effect
    content.glassEffect(in: .rect(cornerRadius: cornerRadius))
} else {
    // Fallback to material effect
    content.background(GlassFallbackBackground(...))
}
```

### iOS 18-25 Fallback Strategy

#### Glass Effects
**iOS 26**: Uses native `.glassEffect()` with adaptive blur and materials
**iOS 18-25**: Uses `.ultraThinMaterial` with:
- Enhanced gradient overlays for tint support
- Multi-layer borders for depth perception
- Inner highlights for premium feel

#### Glass Buttons
**iOS 26**: Native glass capsule style
**iOS 18-25**: Material-based capsule with gradient fill for prominent variants

#### Glass Transitions
**iOS 26**: Uses `.glassEffectID()` for smooth morphing
**iOS 18-25**: Uses `.matchedGeometryEffect()` for similar effect

## Component Compatibility

### Design System Components

| Component | iOS 26 Experience | iOS 18-25 Experience |
|-----------|-------------------|----------------------|
| `GlassCard` | Liquid Glass card with adaptive blur | Ultra-thin material card with gradient borders |
| `GlassButton` | Glass capsule button | Material capsule button |
| `GlassToolbar` | Floating glass toolbar | Material toolbar |
| `GlassSheet` | Glass bottom sheet | Material bottom sheet |
| `GlassNavigationBar` | Glass navigation bar | Material navigation bar |

### Interactive Effects

All interactive effects (`.interactive()`, `.pressEffect()`, `.haptic()`) are implemented as custom SwiftUI modifiers and work identically across all iOS versions.

## Visual Differences

### iOS 26 (Liquid Glass)
- **Adaptive blur**: Content-aware blur sampling
- **Glass morphing**: Smooth transitions between glass elements
- **Rich materials**: Enhanced depth and realism
- **Vibrant tints**: iOS 26-optimized color system

### iOS 18-25 (Material Fallback)
- **Ultra-thin material**: Native iOS material effect
- **Static blur**: Fixed blur radius
- **Standard transitions**: matchedGeometryEffect animations
- **Gradient borders**: Simulated glass edges
- **Tint overlays**: Color tinting with reduced opacity

## Testing on Different iOS Versions

### iOS 26
```bash
# Use iOS 26 simulator
xcodebuild -scheme GitBeek -destination 'platform=iOS Simulator,OS=26.1,name=iPhone 17 Pro Max'
```

### iOS 18
```bash
# Use iOS 18 simulator
xcodebuild -scheme GitBeek -destination 'platform=iOS Simulator,OS=18.6,name=iPhone 16 Pro Max'
```

### Real Device Testing
- iOS 26 beta devices will show full Liquid Glass experience
- iOS 18/19/20/21/22/23/24/25 devices will use material fallbacks

## Performance Considerations

### iOS 26
- **Optimized glass rendering**: Hardware-accelerated
- **Adaptive sampling**: Efficient blur calculations
- **Smooth animations**: 120Hz ProMotion support

### iOS 18-25
- **Material overhead**: Slightly higher than iOS 26 glass
- **Gradient layers**: Additional rendering passes
- **Still performant**: Optimized for 60-120Hz

## Migration Path

When iOS 26 becomes widely adopted:

1. **No code changes needed**: Version detection is automatic
2. **Users upgrade**: They automatically get Liquid Glass experience
3. **Backwards compatible**: App continues to work on iOS 18-25

## Recommended Testing

1. **Primary testing**: iOS 26 simulator (latest features)
2. **Compatibility testing**: iOS 18 simulator (fallback verification)
3. **Real device testing**: Test on actual devices when available

## Known Limitations

### iOS 18-25 Specific

❌ **Not Available**:
- Native `.glassEffect()` - uses material fallback
- `.backgroundExtensionEffect()` - no-op
- `.scrollEdgeEffectStyle()` - standard behavior
- `.tabBarMinimizeBehavior()` - standard behavior

✅ **Available**:
- All core app features
- Custom interactive effects
- Material-based UI components
- Full markdown rendering
- Complete offline support (when implemented)

## Code Examples

### Using Glass Effects

```swift
// This works on all iOS versions
VStack {
    Text("Hello, World!")
}
.glass()  // Automatically uses best available method
```

### Custom Tint

```swift
// Tinted glass card
GlassCard(tint: .blue) {
    Text("Tinted content")
}
```

### Version-Specific Features

```swift
// Use iOS 26 features when available
if #available(iOS 26.0, *) {
    // iOS 26-specific code
} else {
    // Fallback for older versions
}
```

## Troubleshooting

### Issue: UI looks different on iOS 18
**Solution**: This is expected. iOS 18 uses material fallbacks instead of Liquid Glass. The visual difference is intentional to provide the best experience for each platform version.

### Issue: Some animations don't work on iOS 18
**Solution**: Check if you're using iOS 26-specific APIs without version checks. All custom animations should work across versions.

### Issue: Compile errors on older Xcode
**Solution**: Ensure you're using Xcode 16+ which includes iOS 26 SDK. Older Xcode versions may not recognize `.glassEffect()` even within availability checks.

## Summary

✅ **GitBeek works great on iOS 18-25**
- All core features available
- Beautiful material-based UI
- Smooth performance

🌟 **GitBeek shines on iOS 26**
- Liquid Glass design language
- Enhanced visual effects
- Next-generation UI experience

The app automatically adapts to provide the best possible experience on every iOS version!
