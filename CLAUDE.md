# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build

```bash
# Build for device
xcodebuild -project SoundIt.xcodeproj -scheme SoundIt -destination 'generic/platform=iOS' build

# Build for simulator
xcodebuild -project SoundIt.xcodeproj -scheme SoundIt -destination 'platform=iOS Simulator,name=iPhone 16' build
```

External dependency: Firebase iOS SDK (FirebaseAuth) via SPM. No tests yet.

Bundle ID: `se.lovholm.soundit.app`, Team: `APN2E86BRE`, iOS 17+.

Requires `GoogleService-Info.plist` from Firebase Console (project `soundit-d22f4`).

## Architecture

**Auth:** `AuthManager` (@Observable @MainActor) manages Firebase Anonymous Auth. Signs in automatically on launch — no user interaction needed. Provides ID tokens for API requests via `idToken()`. `SoundItApp` shows a `ProgressView` while auth loads, then presents `ContentView`.

**Protocol-injection service layer:** `VideoServiceProtocol` defines two methods: `generateVideo(images:text:format:)` and `listJobs()`. `MockVideoService` renders a real MP4 locally via `VideoExporter` (AVAssetWriter). `APIVideoService` sends multipart (images[] + text + format) to the backend's `/api/v1/jobs`, polls until complete, then downloads the video. Swap implementations in `SoundViewModel`'s initializer.

**Data flow:** Photos picked (multi-select, up to 20) → `ImageEntry` created with `[UIImage]` (idle) → user enters text + format in `ComposeView` → `SoundViewModel.generate()` calls service → entry updates reactively (`@Observable`) → grid reflects status → tap ready entry to play/save/share.

**API integration:** `APIVideoService` creates a job (POST), polls with exponential backoff (1s→10s cap, 600s timeout), and downloads the video from a signed URL. Auth tokens are fetched from `AuthManager.idToken()` before each request. `APIConfig` base URL: `https://soundit-275672990515.europe-west1.run.app`. Backend is Cloud Run in `europe-west1`, GCP project `soundit-d22f4`.

**State:** `SoundViewModel` is `@Observable @MainActor`. `ImageEntry` is `@Observable` with computed `status` (idle/loading/ready/error). No persistence — entries live in memory only. `JobSummary` (Decodable) represents past jobs from the API.

**Views:** `ContentView` (grid + photo input + account menu) presents `ComposeView` (text + format + image carousel), `PlayerView` (AVKit video player + save/share), or `HistoryView` (past jobs with status badges) as sheets. `CameraPicker` wraps UIImagePickerController.

## MCP Servers

Two project-scoped MCP servers are configured (in `~/.claude.json` under this project):

- **apple-docs** — Apple Developer Documentation search (SwiftUI, UIKit, HIG, WWDC). Use to look up current Apple APIs and patterns. `npx @kimsungwhee/apple-docs-mcp@latest`
- **ios-simulator** — Interact with iOS simulators: inspect UI, take screenshots, control elements. Requires Facebook IDB (`pip3 install fb-idb`). `npx ios-simulator-mcp`

## Key quirks

- `ComposeView` lives in `ExportVideoView.swift` (file kept to avoid pbxproj churn).
- `VideoFormat` enum is in `VideoExporter.swift` and referenced by Models and APIService.
- `VideoExporter` class is only used by `MockVideoService` — the real API returns finished videos.
- Swift strict concurrency is set to `complete`.
- Adding/removing source files requires editing `SoundIt.xcodeproj/project.pbxproj` (PBXBuildFile, PBXFileReference, PBXGroup children, and Sources build phase).
- `listJobs()` has a default empty implementation in a protocol extension so MockVideoService doesn't need it.
