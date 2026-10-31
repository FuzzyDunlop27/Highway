# Tech Findings: Highway Holdout stack check (verified 2026-10-31)

Primary sources only (Apple, swift.org, OpenAI Codex docs, Claude Code docs, tool GitHub repos). UNVERIFIED = I could not confirm it from a primary source.

## 1. Current versions and deployment target
- iOS 27.2 shipped Oct 26, 2026; iOS 27.0.1 shipped Sep 28, 2026. Source: https://developer.apple.com/news/releases/
- Xcode 27 (27A266a) shipped Sep 14, 2026. Xcode 27.1 (27A9275) shipped Oct 15. Xcode 27.2 RC came out Oct 19. Source: https://developer.apple.com/news/releases/ , https://developer.apple.com/news/releases/?id=09142026h
- Xcode 27.x: Swift 6.4 compiler (Swift 6 and Swift 5 language modes), needs macOS Tahoe 26.6+, deployment targets iOS/iPadOS 15–27. On-device debugging and Simulator need **iOS 17 or later**. Source: https://developer.apple.com/support/xcode/
- Swift 6.4 released Sep 15, 2026. Source: https://www.swift.org/blog/swift-6.4-released/
- App Store: starting **April 2027**, uploads must be built with the iOS/iPadOS 27 SDK or later. Source: https://developer.apple.com/news/?id=k1mtkt1k
- iPhone 15 shipped with iOS 17. Source: https://www.apple.com/newsroom/2023/09/apple-debuts-iphone-15-and-iphone-15-plus/
- iOS 27 runs on iPhone 15, 15 Plus, 15 Pro and 15 Pro Max. So iPhone 15 supports iOS 17 through 27. Source: https://www.apple.com/os/ios/
- iPadOS 27 runs on iPad Pro (4th gen+), iPad Air (4th gen+), iPad (9th gen+) and iPad mini (6th gen+). Source: https://www.apple.com/os/ipados/
- `@Observable` (Observation) needs iOS/iPadOS 17.0+. Source: https://developer.apple.com/documentation/observation/observable().md
- **Recommendation: minimum iOS/iPadOS 17.0.** It matches what iPhone 15 shipped with, it's the floor for Observation, and it's the lowest version Xcode 27 can debug on a device. Build with Xcode 27 / iOS 27 SDK.
  - Alternative: use iOS 26 as the minimum if you want iOS 26-only SwiftUI APIs (for example the Liquid Glass modifiers) without `#available` checks. Exact API availability: UNVERIFIED.

## 2. SpriteKit / SpriteView status
- SpriteKit's doc page shows no deprecation notice. Availability is listed as iOS 7.0 onward, and the page says: "SpriteKit is supported in iOS, macOS, tvOS, and watchOS". Source: https://developer.apple.com/documentation/spritekit.md
- `SpriteView` ("A SwiftUI view that renders a SpriteKit scene") is still listed under SpriteKit > Structures. Source: https://developer.apple.com/documentation/spritekit.md
- Contrast: Apple deprecated **SceneKit** (3D) in Xcode 26 ("no new features or optimizations... Apple recommends using RealityKit"). SpriteKit was not deprecated. Sources: https://developer.apple.com/videos/play/wwdc2025/288/ , https://developer.apple.com/documentation/xcode-release-notes/xcode-26-release-notes.md
- I found no newer Apple-recommended 2D framework. The WWDC26 Games guide covers Metal 4.1, MetalFX and Game Porting Toolkit, and doesn't mention 2D or SpriteKit at all. Source: https://developer.apple.com/wwdc26/guides/games/
  - "No new 2D path exists": UNVERIFIED (absence of evidence only).
- Honest risk: SpriteKit gets no new features in recent WWDCs (inferred; UNVERIFIED). Developers have reported issues on new OS versions, e.g. "SpriteKit framerate drop on iOS 26.0". Source: https://developer.apple.com/forums/topics/graphics-and-games-topic/graphics-and-games-topic-spritekit
  - Mitigation: keep the simulation in the pure-Swift package, and treat SpriteKit as a thin renderer you could swap out.
- `SpriteView` initializer parameters (isPaused, preferredFramesPerSecond, options, debugOptions): UNVERIFIED (doc page didn't render).

## 3. Local notifications ("horde spotted")
- **Limit is 64.** An Apple engineer wrote (Jan 2026): "there is a limit of 64 for how many simultaneous notification requests can be active/pending at one time per app. This is a system limit and there is no way around it." Source: https://developer.apple.com/forums/thread/811171
- Scheduling a request with the same identifier replaces the pending one with that identifier. Source: https://developer.apple.com/documentation/usernotifications/unnotificationrequest/identifier.md
  - Use one fixed id such as `horde-alert` so you never pile up requests.
- "Scheduled local notifications remain active until they are unscheduled by the system or until you cancel them explicitly." This means the system delivers them while the app is closed (archived 2018 guide). Source: https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/SchedulingandHandlingLocalNotifications.html
- The app can't run code while closed. iOS suspends apps shortly after they go to the background, there's "no general-purpose mechanism for... Running code periodically at a guaranteed interval", and background refresh timing is up to the system (Apple DTS). Source: https://developer.apple.com/forums/thread/685525
- **Design rule:**
  - Decide the alert time when the app goes to the background (`scenePhase == .background`), schedule it with `UNTimeIntervalNotificationTrigger`, and save that fire date in the save file.
  - On next launch, if `now >= fireDate`, spawn the frozen horde at the map edge.
  - Cancel or reschedule whenever the app comes back to the foreground.
  - This matches the design: no attacks while closed, and the horde waits.
- Rules I couldn't confirm (doc pages didn't render): UNVERIFIED
  - You must call `requestAuthorization` first.
  - A repeating time-interval trigger must be at least 60s apart.
  - Exact delivery time isn't guaranteed.

## 4. App icon
- iPhone, iPad and Mac icons use a shared **1024px canvas**; Watch uses 1088px. Source: https://developer.apple.com/videos/play/wwdc2025/361/
- Layers Icon Composer wants:
  - One background, plus foreground layers in **groups of 1–4 layers**.
  - SVG for flat art (convert text to outlines); PNG for gradients or raster art.
  - Export at canvas size, don't include the rounded mask, and keep art flat and opaque.
  - Add blur, shadow and specular effects in Icon Composer, not in the art.
  - Source: https://developer.apple.com/videos/play/wwdc2025/361/
- Simplest structure is a background plus one foreground layer. Apple recommends colored backgrounds. Source: https://developer.apple.com/videos/play/wwdc2025/220/
- Appearance modes are Default, Dark and Mono, which produce the clear and tinted variants. The standalone Icon Composer needs macOS Tahoe 26.4+. Source: https://developer.apple.com/icon-composer/
- Using the icon:
  - Drag the `.icon` file into the Xcode project.
  - The target's General > App Icon field must match the file name (without extension).
  - Source: https://developer.apple.com/forums/thread/813010 (Apple DTS)
- Icon Composer icons back-deploy to older iOS. Xcode 26 fixed "inconsistent rendering" when back-deploying. Source: https://developer.apple.com/documentation/xcode-release-notes/xcode-26-release-notes.md
- Fallback: a single 1024×1024 PNG in an asset catalog ("Single Size") still lets Xcode generate all sizes. Source: HIG quote in https://developer.apple.com/forums/thread/711027
  - Whether the App Store now *requires* a `.icon` file: UNVERIFIED (I found no such requirement).

## 5. AGENTS.md / CLAUDE.md
- **Codex reads AGENTS.md.**
  - Global file: `~/.codex/AGENTS.override.md` or `AGENTS.md`.
  - Project files: it walks from the project root (git root) down to the current directory, using one file per directory and checking `AGENTS.override.md` first. Files closer to the current directory win.
  - It stops at **32 KiB combined** (`project_doc_max_bytes`).
  - Source: https://learn.chatgpt.com/docs/agent-configuration/agents-md (redirect target of developers.openai.com/codex/guides/agents-md)
- Codex silently truncates past that limit. Source: https://github.com/openai/codex/issues/7138
- OpenAI says to keep AGENTS.md small: build/test commands, conventions, and directory-specific notes. Fix repeated mistakes there. Source: https://developers.openai.com/codex/codex-manual.md (search excerpt; page redirects)
- **Claude Code reads CLAUDE.md.** Since v2.1.277 it also reads `AGENTS.md` directly, but only if there's no CLAUDE.md or CLAUDE.local.md in the current directory or above it. Source: https://code.claude.com/docs/en/memory
- **`@AGENTS.md` import is supported and officially recommended.** Put `@AGENTS.md` in CLAUDE.md, then add Claude-specific notes below it. Imports can nest up to 4 hops, and the file is never read twice. Source: https://code.claude.com/docs/en/memory
- Size: "target under 200 lines per CLAUDE.md file". Imports don't reduce context cost. Move narrow rules into path-scoped `.claude/rules/*.md`, and subdirectory CLAUDE.md files load on demand. Source: https://code.claude.com/docs/en/memory
- Apple suggests adding Xcode and project hints to `AGENTS.md`/`CLAUDE.md`. Source: https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode.md
- **Recommendation:**
  - Make one shared `AGENTS.md` the source of truth, under ~150 lines and well under 32 KiB.
  - `CLAUDE.md` = `@AGENTS.md` plus a few Claude-only lines.
  - Put detail in `docs/` and link to it rather than inlining it.

## 6. Building from the CLI without hand-editing .pbxproj
- `xcodebuild` builds and tests from a scheme, e.g. `xcodebuild test -scheme X -destination 'platform=iOS Simulator,name=...'` (archived but valid TN). Source: https://developer.apple.com/library/archive/technotes/tn2339/_index.html
- Xcode needs macOS (see the support table in Q1), so Linux cloud agents can't run `xcodebuild`. Source: https://developer.apple.com/support/xcode/
  - The pure-Swift sim package can still be tested on Linux with `swift test`. SwiftPM's Swift Build works on Linux, macOS and Windows. Source: https://www.swift.org/blog/swift-6.4-released/
- **Xcode 16+ buildable folders**: "Buildable folders only record the folder path into the project file without enumerating the contained files... avoiding source control conflicts". Release-note text quoted in the forum thread; Apple engineer confirms they're the default for new projects. Source: https://developer.apple.com/forums/thread/759620
  - Agents can add, remove or rename `.swift` files without touching `.pbxproj`.
- **Xcode MCP (26.3+)**: Claude Code and Codex can drive Xcode over MCP.
  - Commands: `claude mcp add --transport stdio xcode -- xcrun mcpbridge` and `codex mcp add xcode -- xcrun mcpbridge`.
  - Needs Xcode open with the project, and Settings > Intelligence > "Allow external agents to use Xcode tools" turned on.
  - Sources: https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode.md , https://developer.apple.com/documentation/xcode-release-notes/xcode-26_3-release-notes.md
- **XcodeGen** (`project.yml` generates `.xcodeproj`): latest release 2.46.0 (Jul 16; page shows no year, likely 2026). It has supported synchronized folders since 2.44.0, with fixes in 2.45.x. Source: https://github.com/yonaskolb/XcodeGen/releases
- **Tuist**: Swift manifests (`Project.swift`), start with `tuist init`. Source: https://tuist.dev/en/docs/guides/features/projects/adoption/new-project
  - Tuist is heavier than this project needs (opinion).
- **Recommendation:**
  - Create the app project once in Xcode 27 with buildable folders (the default), plus a local Swift Package for the simulation.
  - Forbid agents from editing `.pbxproj` in AGENTS.md.
  - Add XcodeGen only if agents need to change targets or settings often.

## Other stack notes
- Swift 6.2 added an opt-in "default MainActor isolation" mode (`-default-isolation MainActor`), which fits UI/app targets. Source: https://www.swift.org/blog/swift-6.2-released/
  - Whether Xcode 27 templates turn it on by default: UNVERIFIED.
- Swift Testing ships in Xcode 26+ and works with xcodebuild (exit tests, attachments). Source: https://developer.apple.com/documentation/xcode-release-notes/xcode-26-release-notes.md
- Swift 6.4 lets you mix `XCTAssert` and `#expect` in the same tests. Source: https://www.swift.org/blog/swift-6.4-released/
