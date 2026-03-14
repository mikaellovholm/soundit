# SoundIt iOS — API Integration Plan

Connect the iOS app to the soundit-root GCP backend.

## Decisions made

- **Auth:** Firebase Auth with Sign in with Apple (only provider)
- **Package manager:** Swift Package Manager (first external dependency)
- **Images:** Multi-image support (slideshow)
- **Format:** Keep Reels/Feed picker, send to API
- **Mood:** Not added to iOS — API derives from text
- **History:** Add job history screen

---

## Phase 1: Firebase SDK & Auth ✅

- Added firebase-ios-sdk via SPM (FirebaseAuth product)
- Created `AuthManager.swift` — @Observable @MainActor, Sign in with Apple + Firebase credential exchange
- Created `SignInView.swift` — SignInWithAppleButton with nonce flow
- `SoundItApp.swift` calls `FirebaseApp.configure()` and gates on `authManager.isSignedIn`

## Phase 2: Multi-Image Support ✅

- `ImageEntry.image` → `ImageEntry.images: [UIImage]` with `thumbnail` computed property
- PhotosPicker changed to multi-selection (maxSelectionCount: 20)
- Camera still creates single-image entries
- ComposeView shows horizontal carousel for multi-image entries
- EntryCell shows image count badge

## Phase 3: Rewrite APIVideoService ✅

- Protocol: `generateVideo(images:text:format:)` + `listJobs()` with default empty impl
- APIVideoService: POST `/api/v1/jobs` → poll with exponential backoff → download video
- Bearer token from AuthManager on every request
- New errors: unauthorized, jobFailed, jobTimeout
- MockVideoService: uses first image from array

## Phase 4: Job History ✅

- `JobSummary` struct in Models.swift (Decodable)
- `HistoryView.swift` with pull-to-refresh, status badges
- Accessible from ContentView toolbar menu (person.circle icon)
- `SoundViewModel.loadJobs()` calls `service.listJobs()`

## Phase 5: Configuration & Wiring ✅

- `APIConfig` enum with #if DEBUG localhost:8080 / prod Cloud Run URL
- SoundItApp wires APIVideoService with authManager when signed in
- Sign out button in ContentView toolbar menu

---

## Manual steps required before building

1. **Firebase project:** Create (or reuse) a Firebase project, enable Authentication with Apple provider
2. **GoogleService-Info.plist:** Download from Firebase Console, add to SoundIt target in Xcode
3. **Sign in with Apple capability:** Add in Xcode → Target → Signing & Capabilities
4. **Production URL:** Replace `https://soundit-CHANGEME.run.app` in `APIConfig` with actual Cloud Run URL
5. **SPM resolution:** Open project in Xcode, let it resolve the firebase-ios-sdk package
