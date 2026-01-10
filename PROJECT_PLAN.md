# GitBook iOS App - Swift Native Project Plan

## Project Overview

A native Swift/SwiftUI iOS application for browsing and editing GitBook content, designed with iOS 26 Liquid Glass design language for a modern, premium experience.

---

## Tech Stack

| Component | Technology |
|-----------|------------|
| Language | Swift 6.0+ |
| UI Framework | SwiftUI (iOS 26+) |
| Design System | Liquid Glass |
| Minimum Target | iOS 26.0 |
| State Management | Observation framework (@Observable) |
| Networking | Swift Concurrency + URLSession / Alamofire |
| Local Storage | SwiftData |
| Secure Storage | Keychain Services |
| Markdown | swift-markdown + AttributedString |
| Code Highlighting | Highlightr (185+ languages) |
| Navigation | NavigationStack + NavigationSplitView |
| Dependency Injection | Swift Dependencies / Factory |
| Image Loading | SDWebImageSwiftUI / Kingfisher |

---

## Architecture

采用 Clean Architecture + MVVM 模式：

```
GitBookiOS/
├── App/
│   ├── GitBookApp.swift           # @main entry point
│   ├── AppDelegate.swift          # UIKit lifecycle (if needed)
│   └── Configuration/
│       ├── Environment.swift      # dev/staging/prod configs
│       └── AppSecrets.swift       # API keys (gitignored)
├── Core/
│   ├── Network/
│   │   ├── APIClient.swift        # Generic HTTP client
│   │   ├── APIEndpoint.swift      # Endpoint definitions
│   │   ├── APIError.swift         # Error types
│   │   └── Interceptors/
│   │       ├── AuthInterceptor.swift
│   │       ├── RetryInterceptor.swift
│   │       └── LoggingInterceptor.swift
│   ├── Storage/
│   │   ├── KeychainManager.swift  # Secure token storage
│   │   ├── SwiftDataStore.swift   # Local database
│   │   └── CacheManager.swift     # Content caching
│   ├── Extensions/
│   └── Utilities/
├── Data/
│   ├── DataSources/
│   │   ├── Remote/
│   │   │   └── GitBookAPIService.swift
│   │   └── Local/
│   │       └── ContentLocalDataSource.swift
│   ├── Models/                    # Codable DTOs
│   │   ├── TokenResponse.swift
│   │   ├── UserDTO.swift
│   │   ├── OrganizationDTO.swift
│   │   ├── SpaceDTO.swift
│   │   ├── ContentDTO.swift
│   │   └── ChangeRequestDTO.swift
│   └── Repositories/
│       ├── AuthRepositoryImpl.swift
│       ├── UserRepositoryImpl.swift
│       ├── SpaceRepositoryImpl.swift
│       └── ContentRepositoryImpl.swift
├── Domain/
│   ├── Entities/                  # Business models
│   │   ├── User.swift
│   │   ├── Organization.swift
│   │   ├── Space.swift
│   │   ├── Page.swift
│   │   └── ChangeRequest.swift
│   ├── Repositories/              # Protocols
│   │   ├── AuthRepository.swift
│   │   ├── UserRepository.swift
│   │   ├── SpaceRepository.swift
│   │   └── ContentRepository.swift
│   └── UseCases/
│       ├── Auth/
│       ├── User/
│       ├── Space/
│       └── Content/
├── Presentation/
│   ├── Design/
│   │   ├── Theme/
│   │   │   ├── AppColors.swift
│   │   │   ├── AppTypography.swift
│   │   │   └── AppSpacing.swift
│   │   ├── Components/            # Liquid Glass components
│   │   │   ├── GlassCard.swift
│   │   │   ├── GlassButton.swift
│   │   │   ├── GlassToolbar.swift
│   │   │   └── GlassSheet.swift
│   │   └── Modifiers/
│   │       └── LiquidGlassModifiers.swift
│   ├── ViewModels/
│   │   ├── AuthViewModel.swift
│   │   ├── HomeViewModel.swift
│   │   ├── SpaceViewModel.swift
│   │   ├── PageViewModel.swift
│   │   └── ProfileViewModel.swift
│   ├── Views/
│   │   ├── Auth/
│   │   │   ├── LoginView.swift
│   │   │   └── OAuthWebView.swift
│   │   ├── Home/
│   │   │   ├── HomeView.swift
│   │   │   ├── OrganizationListView.swift
│   │   │   └── RecentSpacesView.swift
│   │   ├── Spaces/
│   │   │   ├── SpaceListView.swift
│   │   │   ├── SpaceDetailView.swift
│   │   │   └── SpaceSettingsView.swift
│   │   ├── Pages/
│   │   │   ├── PageTreeView.swift
│   │   │   ├── PageDetailView.swift
│   │   │   └── PageEditorView.swift
│   │   ├── Profile/
│   │   │   ├── ProfileView.swift
│   │   │   └── SettingsView.swift
│   │   └── Search/
│   │       ├── SearchView.swift
│   │       └── SearchResultsView.swift
│   └── Navigation/
│       ├── AppRouter.swift
│       └── DeepLinkHandler.swift
└── Resources/
    ├── Assets.xcassets
    ├── Localizable.xcstrings
    └── Info.plist
```

---

## Features & Implementation Plan

### Phase 0: iOS 26 Liquid Glass Design System

#### 0.1 设计系统基础
- [x] 创建 Liquid Glass 主题配置
- [x] 实现 `glassEffect()` 封装修饰符
- [x] 创建 `GlassEffectContainer` 复用组件
- [x] 实现 `glassEffectID` 过渡动画工具
- [x] 定义颜色系统（适配 Liquid Glass vibrant colors）
- [x] 配置字体系统（SF Pro 适配）

#### 0.2 核心 UI 组件
- [x] GlassCard - 玻璃卡片组件
- [x] GlassButton - 玻璃按钮 (`.buttonStyle(.glass)`)
- [x] GlassToolbar - 浮动工具栏
- [x] GlassTabBar - 底部导航栏（支持 `.tabBarMinimizeBehavior`）
- [x] GlassSheet - 模态弹窗（Liquid Glass background）
- [x] GlassNavigationBar - 导航栏样式

#### 0.3 动画与交互
- [x] 实现 `.interactive()` 响应效果（缩放、弹跳、闪烁）
- [x] 配置 `.backgroundExtensionEffect()` 背景延伸
- [x] 实现 `.scrollEdgeEffectStyle()` 滚动边缘效果
- [x] 配置 corner concentricity (`.concentric(.container)`)
- [x] 实现 glass morphing 过渡动画

---

### Phase 1: Foundation (Core Infrastructure)

#### 1.1 Project Setup
- [x] 创建 Xcode 项目 (iOS 26+, SwiftUI App)
- [x] 配置项目结构（Clean Architecture）
- [ ] 配置 SwiftLint / SwiftFormat
- [x] 设置环境配置 (dev/staging/prod)
- [ ] 配置 Git hooks 和 CI/CD

#### 1.2 Network Layer
- [x] 实现 APIClient (async/await + URLSession)
- [x] 创建 APIEndpoint 协议和实现
- [x] 实现 APIError 错误类型
- [x] 实现 AuthInterceptor (Bearer token injection)
- [x] 实现 RetryInterceptor (指数退避重试)
- [x] 实现 LoggingInterceptor (DEBUG 模式日志)

#### 1.3 GitBook API Client
- [x] 定义 API 端点常量
- [x] 实现认证端点
  - [x] POST /oauth/token
  - [x] Token refresh 逻辑
- [x] 实现 Organizations API
  - [x] GET /orgs - 列出组织
  - [x] GET /orgs/{orgId} - 获取组织详情
  - [x] GET /orgs/{orgId}/members - 组织成员
- [x] 实现 Spaces API
  - [x] GET /orgs/{orgId}/spaces - 列出空间
  - [x] GET /spaces/{spaceId} - 获取空间详情
  - [x] POST /spaces - 创建空间
  - [x] PATCH /spaces/{spaceId} - 更新空间
  - [x] DELETE /spaces/{spaceId} - 删除空间
- [x] 实现 Pages/Content API
  - [x] GET /spaces/{spaceId}/content - 页面列表
  - [x] GET /spaces/{spaceId}/content/path/{path} - 按路径获取
  - [x] POST /spaces/{spaceId}/content - 创建页面
  - [x] PATCH /spaces/{spaceId}/content/{pageId} - 更新页面
  - [x] DELETE /spaces/{spaceId}/content/{pageId} - 删除页面
- [x] 实现 Change Requests API
  - [x] GET /spaces/{spaceId}/change-requests - 列表
  - [x] POST /spaces/{spaceId}/change-requests - 创建
  - [x] GET /spaces/{spaceId}/change-requests/{crId} - 获取
  - [x] POST /spaces/{spaceId}/change-requests/{crId}/merge - 合并
- [x] 实现 Search API
  - [x] GET /orgs/{orgId}/search - 全局搜索
  - [x] GET /spaces/{spaceId}/search - 空间搜索
- [x] 实现 Collections API
  - [x] GET /orgs/{orgId}/collections - 列出集合
  - [x] GET /collections/{collectionId} - 获取集合详情
- [x] 实现 Spaces Trash API
  - [x] DELETE /spaces/{spaceId} - 软删除空间
  - [x] POST /spaces/{spaceId}/restore - 恢复空间

#### 1.4 Local Storage
- [x] 配置 SwiftData 模型
- [x] 实现 KeychainManager (tokens 安全存储)
- [x] 实现 CacheManager (内容缓存策略)
- [x] 定义 SwiftData schema (Organizations, Spaces, Pages)
- [x] 实现缓存失效策略

---

### Phase 2: Authentication & User Management

#### 2.1 Authentication Flow
- [x] 实现 LoginView (Liquid Glass 设计)
- [x] API Token 输入选项 (GitBook 仅支持 Personal Access Token，无 OAuth)
- [x] Keychain token 存储
- [x] 登出功能
- [x] Session 过期处理 (401 错误时自动登出)
- [x] iOS 26 键盘初始化 Bug 修复 (Onboarding + Keyboard Warmup)
- [x] UIKit TextField 集成解决键盘响应问题
  - [x] NativeTextField 实现 (UIViewRepresentable)
  - [x] 布局约束修复 (防止长文本撑开布局)
  - [x] Auto Layout 优先级配置
- [x] 三页交互式 Onboarding 引导流程

#### 2.2 User Profile
- [x] 获取当前用户信息
- [x] ProfileView 界面
- [x] 组织切换器
- [x] 账户设置

---

### Phase 3: Content Browsing

#### 3.1 Home Screen
- [x] HomeView 主界面 (NavigationSplitView)
- [x] 组织列表 (Liquid Glass cards)
- [x] 最近访问空间快速入口
- [x] 搜索栏 (`.searchable` with Liquid Glass)
- [x] Pull-to-refresh (`.refreshable`)

#### 3.2 Spaces Management
- [x] SpaceListView (Grid/List 切换)
- [x] SpaceDetailView (Liquid Glass toolbar)
- [x] SpaceSettingsView
- [x] 创建新空间 (GlassSheet)
- [x] 删除空间 (confirmation dialog)
- [x] 空间搜索/过滤
- [x] Collection 层级视图

#### 3.3 Pages Navigation
- [x] 目录树视图 (OutlineGroup)
- [x] 页面列表视图
- [x] 面包屑导航 (Liquid Glass breadcrumbs)
- [x] 空间内页面搜索

#### 3.4 Markdown Rendering
- [x] 基础 Markdown 渲染 (swift-markdown + AttributedString)
- [x] 代码块语法高亮 (Highlightr - 185+ 语言支持)
- [x] HTML 代码块渲染 (`<pre><code>` 支持)
- [x] 列表渲染 (普通列表、Task list checkbox)
- [x] 表格渲染
- [x] 图片加载和缓存 (SDWebImageSwiftUI)
- [x] 链接处理 (内部/外部)
- [ ] LaTeX/数学公式渲染 (可选)
- [ ] Mermaid 图表渲染 (可选)
- [x] GitBook 自定义块渲染
  - [x] Hints (info, warning, danger, success)
  - [x] Tabs
  - [x] 可展开区块
  - [x] Embeds (YouTube, Vimeo, Twitter, GitHub, Loom, etc.)

---

### Phase 4: Content Editing

#### 4.1 Markdown Editor
- [ ] 富文本编辑器集成
- [ ] Markdown 工具栏 (Liquid Glass floating toolbar)
  - [ ] Bold, Italic, Strikethrough
  - [ ] Headings (H1-H6)
  - [ ] Lists (ordered, unordered, checklist)
  - [ ] Links
  - [ ] Code (inline and block)
  - [ ] Quotes
  - [ ] Tables
  - [ ] Horizontal rule
- [ ] 实时预览模式 (split view)
- [ ] 源码模式 (raw markdown)
- [ ] 自动保存草稿
- [ ] Undo/Redo 支持

#### 4.2 Media Management
- [ ] 图片选择器 (PHPicker)
- [ ] 图片上传到 GitBook
- [ ] 文件附件支持
- [ ] 图片压缩 (上传前)

#### 4.3 Page Management
- [ ] 创建新页面
- [ ] 编辑现有页面
- [ ] 删除页面 (confirmation)
- [ ] 页面重排序 (drag & drop)
- [ ] 移动页面到其他位置
- [ ] 复制页面

---

### Phase 5: Change Requests (Git-like Workflow)

#### 5.1 Change Request Management
- [ ] Change Request 列表
- [ ] Change Request 详情视图
- [ ] 创建新 Change Request
- [ ] 在 Change Request 上下文中编辑
- [ ] 查看 diff/变更
- [ ] 添加评论
- [ ] 合并 Change Request
- [ ] 关闭/丢弃 Change Request

#### 5.2 Review Flow
- [ ] 请求 review
- [ ] 批准变更
- [ ] 请求修改
- [ ] 针对具体内容评论

---

### Phase 6: Offline Support

#### 6.1 Content Caching
- [ ] 缓存空间元数据
- [ ] 缓存页面内容
- [ ] 本地缓存图片
- [ ] 后台同步 (在线时)

#### 6.2 Offline Editing
- [ ] 离线时编辑队列
- [ ] 同步状态 UI
- [ ] 冲突检测
- [ ] 冲突解决 UI
- [ ] 失败同步重试

#### 6.3 Sync Management
- [ ] 手动同步触发
- [ ] 每个空间的同步状态
- [ ] 清除缓存选项
- [ ] 存储使用量显示

---

### Phase 7: Search & Discovery

#### 7.1 Search Features
- [ ] SearchView (Liquid Glass with `.searchRole(.tab)`)
- [ ] 全局搜索 (跨组织)
- [ ] 空间特定搜索
- [ ] 全文内容搜索
- [ ] 搜索历史
- [ ] 搜索建议
- [ ] 按内容类型过滤

#### 7.2 Recent & Favorites
- [ ] 最近查看的页面
- [ ] 书签页面
- [ ] 快速访问快捷方式

---

### Phase 8: Settings & Preferences

#### 8.1 App Settings
- [ ] SettingsView (NavigationStack + Form with Liquid Glass)
- [ ] 主题选择 (自动跟随系统 - iOS 26 默认)
- [ ] 编辑器偏好
  - [ ] 默认编辑模式
  - [ ] 自动保存间隔
  - [ ] 字体大小
- [ ] 通知设置
- [ ] 语言选择
- [ ] 缓存管理

#### 8.2 About & Support
- [ ] App 版本信息
- [ ] 开源许可证 (Settings Bundle)
- [ ] 隐私政策链接
- [ ] 服务条款链接
- [ ] 反馈/支持链接

---

### Phase 9: Polish & Enhancement

#### 9.1 UI/UX Enhancement
- [ ] Skeleton loading states (Shimmer effect)
- [ ] 空状态设计 (ContentUnavailableView)
- [ ] 错误状态设计
- [ ] Haptic feedback (UIImpactFeedbackGenerator)
- [ ] 流畅动画 (matchedGeometryEffect + glassEffectID)
- [ ] 手势导航

#### 9.2 Accessibility
- [ ] VoiceOver 支持
- [ ] Dynamic Type 支持
- [ ] 色彩对比度合规
- [ ] 键盘导航 (iPad)

#### 9.3 Performance Optimization
- [ ] 列表懒加载 (LazyVStack/LazyVGrid)
- [ ] 图片懒加载
- [ ] 内存优化
- [ ] 启动时间优化

---

### Phase 10: Platform Specific

#### 10.1 iOS Specific
- [ ] App Icons (iOS 26 tinted icon support)
- [ ] Launch Screen (Liquid Glass style)
- [ ] Deep linking 配置 (Universal Links)
- [ ] Share extension (可选)
- [ ] Widget 支持 (可选 - Liquid Glass widgets)
- [ ] Live Activities (可选)

#### 10.2 iPad Specific
- [ ] NavigationSplitView 适配
- [ ] 多窗口支持
- [ ] 键盘快捷键
- [ ] Pointer/trackpad 支持
- [ ] Stage Manager 适配

#### 10.3 visionOS Ready (可选)
- [ ] 3D glass material 适配
- [ ] Spatial UI 布局

---

## API Endpoints Reference

Base URL: `https://api.gitbook.com/v1`

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /oauth/token | Get access token |

### Organizations
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /orgs | List organizations |
| GET | /orgs/{orgId} | Get organization |
| GET | /orgs/{orgId}/members | List members |

### Spaces
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /orgs/{orgId}/spaces | List spaces |
| POST | /orgs/{orgId}/spaces | Create space |
| GET | /spaces/{spaceId} | Get space |
| PATCH | /spaces/{spaceId} | Update space |
| DELETE | /spaces/{spaceId} | Delete space |

### Content
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /spaces/{spaceId}/content | List content |
| GET | /spaces/{spaceId}/content/path/{path} | Get by path |
| POST | /spaces/{spaceId}/content | Create page |
| PUT | /spaces/{spaceId}/content/{pageId} | Update page |
| DELETE | /spaces/{spaceId}/content/{pageId} | Delete page |

### Change Requests
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /spaces/{spaceId}/change-requests | List CRs |
| POST | /spaces/{spaceId}/change-requests | Create CR |
| GET | /spaces/{spaceId}/change-requests/{id} | Get CR |
| POST | /spaces/{spaceId}/change-requests/{id}/merge | Merge CR |

---

## iOS 26 Liquid Glass 关键 API 参考

### Core Modifiers
```swift
// 基础玻璃效果
view.glassEffect()
view.glassEffect(shape: .rect(cornerRadius: 12))
view.glassEffect().interactive()  // 交互响应

// 玻璃容器（多个玻璃元素必须包裹）
GlassEffectContainer {
    // glass elements
}

// 玻璃过渡动画
view.glassEffectID("identifier", in: namespace)

// 工具栏
Toolbar {
    ToolbarItemGroup(placement: .primaryAction) { }
    ToolbarSpacer()
}

// TabBar 行为
TabView { }
    .tabBarMinimizeBehavior(.onScrollDown)
    .tabViewBottomAccessory { PlaybackView() }

// 搜索
.searchable(text: $searchText)
.searchRole(.tab)

// Sheet
.sheet(isPresented: $show) { }  // 自动 Liquid Glass 背景

// 按钮样式
Button("Action") { }
    .buttonStyle(.glass)
    .buttonStyle(.glassProminent)
```

### 设计原则
1. **Glass 用于导航层**：内容在底层，玻璃控件浮动在顶层
2. **避免过度使用**：只在需要层次感时使用玻璃效果
3. **使用 GlassEffectContainer**：多个玻璃元素必须包裹以确保一致的采样
4. **Tint 传达语义**：颜色应该传达含义，而非纯装饰

---

## Milestones

### MVP (Minimum Viable Product)
- [x] Phase 0: Liquid Glass Design System
- [x] Phase 1: Core Infrastructure
- [x] Phase 2: Authentication (login/logout)
- [x] Phase 3.1-3.2: View organizations and spaces
- [x] Phase 3.3: Basic page navigation
- [x] Phase 3.4: Basic markdown rendering

### V1.0
- [ ] Phase 4: Full content editing
- [ ] Phase 5: Change Request workflow
- [ ] Phase 6: Offline content viewing
- [ ] Phase 7: Search functionality

### V1.1+
- [ ] Offline editing with sync
- [ ] Advanced search with filters
- [ ] Widgets and extensions
- [ ] iPad optimization
- [ ] visionOS support (optional)

---

## Testing Strategy

### Unit Tests
- [x] API client tests
- [x] Network interceptor tests (SessionExpiredInterceptor)
- [ ] Model serialization tests (Codable)
- [x] Keychain storage tests
- [ ] SwiftData tests
- [x] Repository tests (SpaceRepositoryImpl)
- [x] ViewModel tests (AuthViewModel, ProfileViewModel, SpaceListViewModel)

### UI Tests
- [ ] Login flow tests
- [ ] Navigation tests
- [ ] Content browsing tests

### Snapshot Tests
- [ ] Liquid Glass components
- [ ] Screen layouts

---

## Dependencies (Swift Package Manager)

```swift
// Package.swift 或 Xcode SPM
dependencies: [
    // Networking
    .package(url: "https://github.com/Alamofire/Alamofire", from: "5.9.0"),

    // Image Loading
    .package(url: "https://github.com/SDWebImage/SDWebImageSwiftUI", from: "3.0.0"),

    // Markdown
    .package(url: "https://github.com/apple/swift-markdown", from: "0.4.0"),

    // Code Highlighting
    .package(url: "https://github.com/raspu/Highlightr", from: "2.2.1"),

    // Dependency Injection
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0"),

    // Testing
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.15.0"),
]
```

---

## Notes

- 所有 API 调用需要 Bearer token 认证
- 注意 API 速率限制
- GitBook 内部使用自定义 JSON 格式，markdown 作为导出格式
- 离线冲突处理：实现 last-write-wins 或手动合并
- iOS 26 最低版本要求：确保用户群体覆盖（考虑 iOS 17+ 降级方案）

---

## Flutter 项目迁移参考

以下功能在 Flutter 版本中已实现，可作为 Swift 实现的参考：

### 已实现的功能 (Flutter)
1. ✅ 项目初始化和核心基础设施
2. ✅ 网络层和 GitBook API 客户端
3. ✅ 本地存储层 (Hive + Drift)
4. ✅ 认证流程和用户资料管理
5. ✅ 主屏幕和空间管理
6. ✅ Collection 层级视图和创建
7. ✅ 垃圾箱功能
8. ✅ 页面导航（目录树、面包屑）
9. ✅ Markdown 渲染（语法高亮、GitBook 自定义块）
10. ✅ 主题切换、字体大小控制
11. ✅ API 分页支持

### Git Commits 参考
```
feat: Add API pagination support and optimize display mode switching
feat: Add theme switching, font size control, and fix profile integration
feat: Improve breadcrumb navigation and add child pages display
feat: Implement Phase 3.4 Markdown rendering with syntax highlighting
feat: Implement Phase 3.3 Pages Navigation and fix iOS real device deployment
refactor: Redesign space detail screen with inline dialogs
feat: Implement trash feature and collection detail screen
feat: Add collection creation and parent collection selection
feat: Add collection hierarchy view and fix emoji display
fix: Resolve app initialization and provider timing issues
fix: Connect app.dart to auth flow and show LoginScreen/HomeScreen
feat: Implement Home Screen and Spaces Management (Phase 3.1/3.2)
feat: Implement authentication flow and user profile management
feat: Implement local storage layer with Hive and Drift
test: Add comprehensive unit tests for core infrastructure
feat: Implement network layer and GitBook API client
feat: Initialize GitBook Mobile project with core infrastructure
```

---

## 资源链接

- [WWDC25: Build a SwiftUI app with the new design](https://developer.apple.com/videos/play/wwdc2025/323/)
- [Adopting Liquid Glass - Apple Developer](https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass)
- [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views)
- [GitBook API Documentation](https://developer.gitbook.com/)
