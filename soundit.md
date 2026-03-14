# SoundIt

An iPhone app that turns photos into soundtrack videos. Pick a photo, describe the vibe, choose a format, and get back a unique video with generated music.

## What it does

1. User adds a photo (camera or photo library)
2. User enters a text description (the "vibe")
3. User picks a video format — Reels/Stories (9:16) or Feed (16:9)
4. App sends image + text + format to the API, gets back a video URL, and downloads it
5. User can play the video and save to Photos or share

## Tech stack

- **SwiftUI** / iOS 17+
- **@Observable** for state management
- **AVKit** for video playback
- **AVFoundation** for local video rendering (mock service uses AVAssetWriter)
- Protocol-based service layer (swap mock for real API)

## Current state

### Done

- **Project structure** — Xcode project with all source files, compiles cleanly
- **Models** — `ImageEntry` with text, format, video file URL, and observable status tracking (idle/loading/ready/error)
- **Service layer** — `VideoServiceProtocol` with two implementations:
  - `MockVideoService` — 2s simulated delay, renders a real playable MP4 (image + sine-wave melody) via `VideoExporter`
  - `APIVideoService` — sends image + text + format as multipart/form-data, expects JSON with video URL back, downloads the video. Ready to plug in, needs a real endpoint.
- **Main screen** (`ContentView`) — grid of entries showing status. PhotosPicker for library, camera via UIImagePickerController wrapper. Tap idle/error entries to compose, tap ready entries to play. Context menu for edit/delete.
- **Compose sheet** (`ComposeView` in ExportVideoView.swift) — shows picked image, text field for description, segmented format picker (Reels/Stories vs Feed), Generate button
- **Video player** (`PlayerView`) — plays the downloaded video via AVKit `VideoPlayer`, Save to Photos, Share
- **Video renderer** (`VideoExporter`) — renders image + audio into MP4 (H.264/AAC), used by mock service
- **View model** (`SoundViewModel`) — manages entries, separate add/generate steps, handles delete with file cleanup
- **Camera support** (`CameraPicker`) — UIViewControllerRepresentable wrapping UIImagePickerController
- **Privacy descriptions** — camera, photo library, and photo library save usage strings configured

### Not done yet

- Real backend integration (mock service only)
- Persistence (entries are in-memory, lost on app restart)
- App icon artwork
- Tests
- Onboarding / empty state beyond the basic placeholder

## Files

```
SoundIt.xcodeproj/project.pbxproj   — Xcode project
SoundIt/
  SoundItApp.swift                   — App entry point
  ContentView.swift                  — Main screen: image grid + photo input
  CameraPicker.swift                 — UIKit camera wrapper
  ExportVideoView.swift              — Compose sheet (text + format picker)
  PlayerView.swift                   — Video player + save/share
  VideoExporter.swift                — MP4 rendering engine (AVAssetWriter), VideoFormat enum
  SoundViewModel.swift               — @Observable view model
  APIService.swift                   — Service protocol + mock + API stub
  Models.swift                       — ImageEntry model
  Assets.xcassets/                   — Asset catalog (icon, accent color)
```
