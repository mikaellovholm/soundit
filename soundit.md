# SoundIt

An iPhone app that turns photos into soundtracks. Take or pick a photo, send it off, and get back a unique audio track for each image.

## What it does

1. User adds a photo (camera or photo library)
2. Photo is sent to a soundtrack generation service
3. A soundtrack comes back — user can play it with full audio controls

## Tech stack

- **SwiftUI** / iOS 17+
- **@Observable** for state management
- **AVFoundation** for audio playback
- Protocol-based service layer (swap mock for real API)

## Current state

### Done

- **Project structure** — Xcode project with all source files, compiles cleanly
- **Models** — `ImageEntry` with observable status tracking (idle/loading/ready/error)
- **Service layer** — `SoundtrackServiceProtocol` with two implementations:
  - `MockSoundtrackService` — 2s simulated delay, returns a real playable 8-second WAV (sine-wave melody), random track title
  - `APISoundtrackService` — sends image as multipart/form-data, expects JSON with base64 audio back. Ready to plug in, needs a real endpoint.
- **Main screen** (`ContentView`) — grid of added images showing soundtrack status. PhotosPicker for library, camera via UIImagePickerController wrapper. Context menu for retry/delete.
- **Player sheet** (`PlayerView`) — displays image, track title, play/pause, skip ±10s, seek slider with timestamps
- **View model** (`SoundViewModel`) — manages the list of entries, triggers generation, handles retry/delete
- **Camera support** (`CameraPicker`) — UIViewControllerRepresentable wrapping UIImagePickerController
- **Privacy descriptions** — camera and photo library usage strings configured

### Not done yet

- Real backend integration (mock service only)
- Persistence (entries are in-memory, lost on app restart)
- App icon artwork
- Error retry UI beyond context menu
- Tests
- Onboarding / empty state beyond the basic placeholder

## Files

```
SoundIt.xcodeproj/project.pbxproj   — Xcode project
SoundIt/
  SoundItApp.swift                   — App entry point
  ContentView.swift                  — Main screen: image grid + photo input
  CameraPicker.swift                 — UIKit camera wrapper
  PlayerView.swift                   — Audio player sheet
  SoundViewModel.swift               — @Observable view model
  APIService.swift                   — Service protocol + mock + API stub
  Models.swift                       — ImageEntry model
  Assets.xcassets/                   — Asset catalog (icon, accent color)
```
