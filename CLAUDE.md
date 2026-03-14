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

Requires `GoogleService-Info.plist` from Firebase Console and "Sign in with Apple" capability.

## Architecture

**Auth:** `AuthManager` (@Observable @MainActor) manages Firebase Auth with Sign in with Apple. `SignInView` presents the Apple sign-in button. `SoundItApp` gates the app behind `authManager.isSignedIn`.

**Protocol-injection service layer:** `VideoServiceProtocol` defines two methods: `generateVideo(images:text:format:)` and `listJobs()`. `MockVideoService` renders a real MP4 locally via `VideoExporter` (AVAssetWriter). `APIVideoService` sends multipart (images[] + text + format) to the backend's `/api/v1/jobs`, polls until complete, then downloads the video. Swap implementations in `SoundViewModel`'s initializer.

**Data flow:** Photos picked (multi-select) → `ImageEntry` created with `[UIImage]` (idle) → user enters text + format in `ComposeView` → `SoundViewModel.generate()` calls service → entry updates reactively (`@Observable`) → grid reflects status → tap ready entry to play/save/share.

**API integration:** `APIVideoService` creates a job (POST), polls with exponential backoff (GET), and downloads the video from a signed URL. Auth tokens are fetched from `AuthManager.idToken()` before each request. `APIConfig` provides base URL (#if DEBUG localhost / prod Cloud Run).

**State:** `SoundViewModel` is `@Observable @MainActor`. `ImageEntry` is `@Observable` with computed `status` (idle/loading/ready/error). No persistence — entries live in memory only. `JobSummary` (Decodable) represents past jobs from the API.

**Views:** `ContentView` (grid + photo input + account menu) presents `ComposeView` (text + format + image carousel), `PlayerView` (AVKit video player + save/share), or `HistoryView` (past jobs with status badges) as sheets. `CameraPicker` wraps UIImagePickerController. `SignInView` is shown when not authenticated.

## Key quirks

- `ComposeView` lives in `ExportVideoView.swift` (file kept to avoid pbxproj churn).
- `VideoFormat` enum is in `VideoExporter.swift` and referenced by Models and APIService.
- `VideoExporter` class is only used by `MockVideoService` — the real API returns finished videos.
- Swift strict concurrency is set to `complete`.
- Adding/removing source files requires editing `SoundIt.xcodeproj/project.pbxproj` (PBXBuildFile, PBXFileReference, PBXGroup children, and Sources build phase).
- `listJobs()` has a default empty implementation in a protocol extension so MockVideoService doesn't need it.
