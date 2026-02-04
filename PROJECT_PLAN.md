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
- [x] ISO8601 日期解码支持（含小数秒）

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
  - [x] PATCH /collections/{collectionId} - 重命名集合
  - [x] DELETE /collections/{collectionId} - 删除集合
  - [x] POST /collections/{collectionId}/move - 移动集合
  - [x] POST /spaces/{spaceId}/move - 移动空间
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
- [x] iOS 18+ 兼容性优化（移除 GlassEffectContainer）
- [x] 按钮交互优化（视觉反馈、触摸区域）

#### 3.2 Spaces Management
- [x] SpaceListView (Grid/List 切换)
- [x] SpaceDetailView (Liquid Glass toolbar)
- [x] SpaceSettingsView
- [x] 创建新空间 (GlassSheet + Emoji Picker)
- [x] 删除空间 (confirmation dialog)
- [x] 空间搜索/过滤
- [x] Collection 层级视图
- [x] Space/Collection 上下文菜单 (Move to, Rename, Copy, Delete)

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

### ~~Phase 4: Content Editing~~ ❌ 已取消

> **原因**: GitBook API 不提供页面内容编辑端点。所有 content 端点（包括 Change Request 中的）均为只读 (GET only)。内容编辑只能通过 GitBook Web 编辑器或 Git Sync 完成。此 Phase 整体取消。

---

### Phase 5: Change Requests (Git-like Workflow)

#### 5.1 Change Request Management
- [x] Change Request 列表 (All Change Requests view with hierarchy)
- [x] 创建 Change Request 数据结构和 Repository
- [x] 实现分层展示 (Collections > Spaces 结构)
- [x] 实现 Liquid Glass 过滤栏 (iOS 26/18 兼容)
- [x] 实现缓存机制 (Singleton ViewModel)
- [x] 实现下拉刷新 (Pull-to-refresh with immediate feedback)
- [x] 实现过滤器自动滚动 (Auto-scroll to center)
- [x] 修复测试目标编译问题
- [x] 代码简化 (减少 ~94 行, 16%)
- [x] 创建测试文档 (19 个测试场景)
- [x] Change Request 详情视图
- [ ] 创建新 Change Request (POST /spaces/{spaceId}/change-requests，仅支持 subject)
- ~~在 Change Request 上下文中编辑~~ ❌ API 不支持内容编辑
- [x] 查看 diff/变更 (段落级 LCS diff，基于 revision API 获取前后内容)
- [x] 评论系统 (POST/GET/PUT/DELETE comments + replies，API 完整支持)
- [x] 合并 Change Request
- [x] 关闭/归档 Change Request (本地状态同步更新)

#### 5.2 Review Flow
- [x] 请求 review (POST /change-requests/{crId}/requested-reviewers，API 支持)
- [x] 批准变更
- [x] 请求修改
- [x] 评论与回复 (comments + replies CRUD，API 完整支持)

---

### Phase 6: Offline Reading Cache ✅

> **调整**: 由于 API 不支持内容编辑，Phase 6 从"Offline Support"简化为"Offline Reading Cache"，移除所有离线编辑相关功能。

#### 6.1 Content Caching
- [x] 缓存空间元数据 (SwiftData 持久化)
- [x] 缓存页面内容 (Stale-While-Revalidate 策略)
- [x] 本地缓存图片 (SDWebImage 自动处理)
- [x] 后台同步 (缓存过期时自动后台刷新)

#### ~~6.2 Offline Editing~~ ❌ 已取消（API 不支持内容编辑）

#### 6.3 Cache Management
- [x] 清除缓存选项 (见 Phase 8.1)
- [x] 存储使用量显示 (见 Phase 8.1)

---

### Phase 7: Search & Discovery ✅

#### 7.1 Search Features
- [x] SearchView (Liquid Glass design)
- [x] 全局搜索 (跨组织)
- [x] 空间特定搜索
- [x] 全文内容搜索
- [x] 搜索历史管理 (添加、删除、清空)
- [x] Search scope selection (All/This Space with space picker)
- [x] Debounced search with loading states (300ms)
- [x] Rich result display with excerpts
- [x] 搜索建议 (Search suggestions from history)
- [x] 完整的导航集成 (NavigationDestinationBuilder)
- [x] 错误处理和空状态展示
- [x] TabBar 可见性控制 (仅顶层显示)
- [x] 点击区域优化 (contentShape for full row)
- [ ] 按内容类型过滤 (Client-side filtering available)

#### 7.2 Recent & Favorites
- [x] 最近查看的页面 (Automatic tracking with RecentPagesManager)
- [x] RecentPagesManager 单例存储 (UserDefaults持久化)
- [x] 去重和时间戳更新逻辑
- [x] 书签/收藏功能 (Toggle favorite with persistence)
- [x] 快速访问快捷方式 (Preview in SearchView + dedicated views)
- [x] RecentPagesView 完整列表展示
- [x] FavoritesView 完整列表展示
- [x] 相对时间格式化显示

#### 7.3 Code Quality
- [x] 代码简化 (NavigationDestinationBuilder 减少重复)
- [x] API DTO 修复 (OrganizationSearchDTO 匹配实际响应)
- [x] 测试覆盖 (Phase7Tests with 14 test cases, 160 total tests passing)
- [x] flatMap 优化搜索结果处理
- [x] iOS 18.6 导航兼容性修复 (NavigationStack 架构优化，消除嵌套问题)

---

### Phase 8: Settings & Preferences

#### 8.1 App Settings
- [x] SettingsView (NavigationStack + Form with Liquid Glass)
- [x] 主题选择 (System / Light / Dark 三选一)
- ~~编辑器偏好~~ ❌ 已取消（无编辑功能）
- [x] 阅读偏好
  - [x] 字体大小 (Small / Default / Large / Extra Large)
  - [x] 代码高亮主题 (9 themes: Xcode, GitHub, Atom One, Dracula, etc.)
- [x] 缓存管理
  - [x] 存储使用量显示 (总量 + 分类: 图片/内容/其他)
  - [x] 清除所有缓存
  - [x] 清除图片缓存
  - [x] 清除内容缓存
  - [x] 清除过期数据 (>24h)

#### 8.2 About & Support
- [ ] App 版本信息
- [ ] 开源许可证 (Settings Bundle)
- [ ] 隐私政策链接
- [ ] 服务条款链接
- [ ] 反馈/支持链接

---

### Phase 9: Polish & Enhancement

#### 9.0 Export Features
- [x] PDF 导出功能
  - [x] 将 Page 渲染为 PDF 文件
  - [x] 保留 markdown 格式（标题、代码块、表格、图片等）
  - [x] 分页处理（长文档自动分页）
  - [x] 分享/保存 PDF (UIActivityViewController)
  - [x] 代码主题支持（浅色/深色跟随用户设置）
  - [x] 图片预加载转 Base64（离线 PDF 支持）

#### 9.1 UI/UX Enhancement
- [x] Skeleton loading states (Shimmer effect)
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

### Content (Read-Only)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /spaces/{spaceId}/content | List content |
| GET | /spaces/{spaceId}/content/path/{path} | Get by path |
| GET | /spaces/{spaceId}/content/page/{pageId} | Get page by ID |

> **注意**: GitBook API 不提供 POST/PUT/DELETE content 端点，页面内容无法通过 API 编辑。

### Change Requests
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /spaces/{spaceId}/change-requests | List CRs |
| POST | /spaces/{spaceId}/change-requests | Create CR (subject only) |
| GET | /spaces/{spaceId}/change-requests/{id} | Get CR |
| POST | /spaces/{spaceId}/change-requests/{id}/merge | Merge CR |

### Comments
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /spaces/{spaceId}/change-requests/{crId}/comments | List comments |
| POST | /spaces/{spaceId}/change-requests/{crId}/comments | Create comment |
| PUT | /spaces/{spaceId}/change-requests/{crId}/comments/{id} | Update comment |
| DELETE | /spaces/{spaceId}/change-requests/{crId}/comments/{id} | Delete comment |
| POST | /spaces/{spaceId}/change-requests/{crId}/comments/{id}/replies | Add reply |

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
- ~~Phase 4: Full content editing~~ ❌ 已取消（API 不支持）
- [x] Phase 5.1: Change Request management (completed)
- [x] Phase 5.2: Review Flow (approve/request changes)
- [ ] Phase 5: 评论系统 + 创建 CR + 请求 review
- [x] Phase 6: Offline reading cache (Stale-While-Revalidate)
- [x] Phase 7: Search & Discovery (completed)

### V1.1+
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
- **GitBook API 限制**: 页面内容端点全部只读，无法通过 API 编辑页面内容。编辑只能通过 Web 编辑器或 Git Sync
- iOS 26 最低版本要求：确保用户群体覆盖（考虑 iOS 17+ 降级方案）
- **iOS 18-25 兼容性**: 应用已完全适配 iOS 18+，通过 `.ultraThinMaterial` fallback 提供一致体验
- **GitBook API 日期格式**: 支持 ISO8601 标准格式及带小数秒的扩展格式

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
