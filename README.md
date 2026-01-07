# GitBeek iOS

A native Swift/SwiftUI iOS application for browsing and editing GitBook content, designed with iOS 26 Liquid Glass design language.

## Requirements

- iOS 26.0+ (iOS 18.0 for development/fallback)
- Xcode 16.0+
- Swift 6.0+

## Project Structure

```
gitbeek/
├── Package.swift                    # Swift Package Manager configuration
├── GitBeek/
│   ├── App/
│   │   ├── GitBeekApp.swift         # @main entry point
│   │   └── Configuration/
│   │       └── Environment.swift    # Environment configurations
│   ├── Core/
│   │   ├── Network/                 # API client (Phase 1)
│   │   ├── Storage/                 # Local storage (Phase 1)
│   │   ├── Extensions/
│   │   └── Utilities/
│   ├── Data/
│   │   ├── DataSources/            # Remote & Local data sources
│   │   ├── Models/                 # Codable DTOs
│   │   └── Repositories/           # Repository implementations
│   ├── Domain/
│   │   ├── Entities/               # Business models
│   │   ├── Repositories/           # Repository protocols
│   │   └── UseCases/               # Business logic
│   ├── Presentation/
│   │   ├── Design/
│   │   │   ├── Theme/
│   │   │   │   ├── AppColors.swift
│   │   │   │   ├── AppTypography.swift
│   │   │   │   └── AppSpacing.swift
│   │   │   ├── Components/          # Liquid Glass components
│   │   │   │   ├── GlassCard.swift
│   │   │   │   ├── GlassButton.swift
│   │   │   │   ├── GlassToolbar.swift
│   │   │   │   ├── GlassTabBar.swift
│   │   │   │   ├── GlassSheet.swift
│   │   │   │   └── GlassNavigationBar.swift
│   │   │   ├── Modifiers/
│   │   │   │   ├── LiquidGlassModifiers.swift
│   │   │   │   └── GlassAnimations.swift
│   │   │   └── DesignSystemPreviewView.swift
│   │   ├── ViewModels/
│   │   ├── Views/
│   │   └── Navigation/
│   └── Resources/
│       ├── Assets.xcassets
│       └── Info.plist
└── GitBeekTests/
    └── GitBeekTests.swift
```

## Phase 0: Liquid Glass Design System ✅

### Implemented Components

#### Theme
- **AppColors**: Color palette with primary, semantic, and glass-specific colors
- **AppTypography**: SF Pro font system with display, headline, body, and code styles
- **AppSpacing**: Consistent spacing scale (4pt base) and corner radius system

#### Glass Components
- **GlassCard**: Glass-effect cards with various sizes (compact, standard, large)
- **GlassButton**: Glass button styles (.glass, .glassProminent) and variants
- **GlassToolbar**: Floating toolbars with segmented and formatting presets
- **GlassTabBar**: Bottom navigation with minimizable and accessory variants
- **GlassSheet**: Modal sheets with glass background and action sheets
- **GlassNavigationBar**: Navigation headers, search bars, breadcrumbs

#### Modifiers & Animations
- **LiquidGlassModifiers**: Core `.glass()`, `.interactiveGlass()`, `.tintedGlass()`
- **GlassAnimations**: Interactive effects, haptics, shimmer, pulse, bounce, rotate

### Usage Examples

```swift
// Glass Card
GlassCard {
    Text("Hello, World!")
}

// Glass Button
GlassButton("Save", systemImage: "checkmark", isProminent: true) {
    // action
}

// Glass Toolbar
GlassToolbar {
    GlassToolbarItem(systemImage: "bold") { }
    GlassToolbarItem(systemImage: "italic") { }
}

// Interactive Effect
Text("Tap me")
    .padding()
    .glass()
    .interactive()
```

## Building

### Using Swift Package Manager

```bash
cd gitbeek
swift build
```

### Using Xcode

1. Open `Package.swift` in Xcode
2. Wait for dependencies to resolve
3. Select iOS Simulator or device
4. Build and run (⌘R)

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| Alamofire | 5.9+ | HTTP networking |
| SDWebImageSwiftUI | 3.0+ | Image loading and caching |
| swift-markdown | 0.4+ | Markdown parsing |
| Splash | 0.16+ | Code syntax highlighting |
| swift-dependencies | 1.0+ | Dependency injection |

## Development Phases

- [x] **Phase 0**: Liquid Glass Design System
- [ ] **Phase 1**: Foundation (Network, Storage)
- [ ] **Phase 2**: Authentication
- [ ] **Phase 3**: Content Browsing
- [ ] **Phase 4**: Content Editing
- [ ] **Phase 5**: Change Requests
- [ ] **Phase 6**: Offline Support
- [ ] **Phase 7**: Search
- [ ] **Phase 8**: Settings
- [ ] **Phase 9**: Polish
- [ ] **Phase 10**: Platform Specific

## License

Private - GitBook
