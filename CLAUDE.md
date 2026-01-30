# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test

```bash
# Build
xcodebuild build -project GitBeek.xcodeproj -scheme GitBeek -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max'

# Run all tests (146+)
xcodebuild test -project GitBeek.xcodeproj -scheme GitBeek -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max'

# Project is generated via XcodeGen from project.yml
# After modifying project.yml, regenerate with: xcodegen generate
```

## Architecture

**Clean Architecture + MVVM** with four layers:

- **Domain** (`GitBeek/Domain/`): Entity models and repository protocols. No dependencies on other layers.
- **Data** (`GitBeek/Data/`): Repository implementations, Codable DTOs, and remote data sources (`GitBookAPIService`, `GitBookEndpoints`). Depends on Domain.
- **Core** (`GitBeek/Core/`): Network client (`APIClient` with interceptor chain for auth/retry/logging/session-expiry), `KeychainManager`, `CacheManager`, `SwiftDataStore`.
- **Presentation** (`GitBeek/Presentation/`): SwiftUI views, `@Observable` ViewModels, navigation (`AppRouter` with `NavigationPath`), design system, and markdown rendering.

**Dependency injection** via singleton `DependencyContainer` (`GitBeek/App/DependencyContainer.swift`).

## Key Conventions

- **Swift 6.0** with **strict concurrency** (`SWIFT_STRICT_CONCURRENCY: complete`). All ViewModels are `@MainActor @Observable`.
- **SwiftUI-only** — no UIViewController usage except `NativeTextField` (UIViewRepresentable).
- **iOS 18.0+ deployment target** with iOS 26 Liquid Glass design. Use `@available(iOS 26.0, *)` checks with `.ultraThinMaterial` fallbacks for glass effects.
- **async/await** throughout — no Combine or completion handlers.
- **Repository pattern**: protocols in `Domain/Repositories/`, implementations in `Data/Repositories/`. All async throwing.
- **Design system**: use `GlassCard`, `GlassButton`, `GlassToolbar`, etc. from `Presentation/Design/Components/`. Design tokens in `AppColors`, `AppTypography`, `AppSpacing`.
- **Markdown rendering**: custom pipeline in `Presentation/Markdown/` using swift-markdown + Splash for syntax highlighting. Supports GitBook-specific blocks (hints, tabs, embeds, expandables).
- **Tests**: unit tests in `GitBeekTests/` covering Core, Data, Domain, and ViewModel layers. Mock repositories as structs conforming to protocols.

## SPM Dependencies

Alamofire (networking), SDWebImageSwiftUI (images), swift-markdown (parsing), Splash (syntax highlighting), swift-dependencies (DI framework).
