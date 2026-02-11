# Roadmap

## Phase 1 — Foundation

Set up the data pipeline and app structure. No UI yet.

- [ ] Python script (`scripts/fetch_pokemon_data.py`) to pull all Pokemon from PokeAPI
  - All 1025 Pokemon: name, types, stats, abilities, descriptions, sprite URLs, evolution chains
  - Output: `pokemon.json` bundled into Xcode project
  - Use `uv` for dependency management
- [ ] Define Swift data models
  - `Pokemon` — struct decoded from bundled JSON
  - `UserPokemon` — SwiftData model for collection tracking
  - `CollectionStatus` enum: `.unseen`, `.seen`, `.caught`, `.favorite`
- [ ] Project folder structure: Models/, Views/, Services/, Resources/
- [ ] Load and decode `pokemon.json` on app launch via a `PokemonDataService`

## Phase 2 — Core Pokedex

The main app experience. Browse, search, and track Pokemon.

- [ ] Pokedex list view (scrollable grid or list of all Pokemon)
  - Sprite image, name, number, types
  - Search by name or number
  - Filter by type, generation, caught status
- [ ] Pokemon detail view
  - Full sprite, name, number, types
  - Stats (HP, Attack, Defense, Sp.Atk, Sp.Def, Speed) with bar visualization
  - Abilities
  - Pokedex description
  - Evolution chain
- [ ] Collection tracking
  - Mark Pokemon as seen, caught, or favorite
  - Collection progress stats (e.g., "342 / 1025 caught")
  - Filter Pokedex by collection status
- [ ] Tab-based navigation
  - Pokedex tab
  - Collection tab (shows only caught/seen/favorites)
  - Settings tab (future: API key, preferences)

## Phase 3 — Ash Ketchum Mode (Live Vision)

Point the camera at a Pokemon and the app speaks its Pokedex entry.

- [ ] Source or train Core ML Pokemon classifier
  - Search GitHub for existing .mlmodel covering Gen 1-9
  - If none suitable: download Kaggle dataset, train via Apple Create ML
  - Target: all 1025 Pokemon, >85% accuracy
- [ ] Camera view using AVCaptureSession in SwiftUI
  - Live camera preview
  - Frame capture for ML inference
- [ ] Core ML integration
  - Run classifier on captured frames
  - Confidence threshold: 85%
  - Debounce: only trigger when prediction changes (`currentPrediction != lastSpokenPokemon`)
- [ ] Text-to-speech
  - AVSpeechSynthesizer with premium voice
  - Speak local Pokedex entry immediately on recognition
- [ ] Claude API integration
  - Send captured image + identified Pokemon name to Claude Haiku 4.5
  - Prompt: "What is this [Pokemon] doing? Be brief."
  - Append contextual response after local entry finishes speaking
- [ ] Overlay UI
  - Pokemon info card overlaid on camera feed
  - Name, type, brief description
  - Smooth entrance/exit animations

## Phase 4 — Verified Collection (Screen Scanner)

Scan Pokemon Home to verify your real collection.

- [ ] Video import from Photo Library (PHPickerViewController)
- [ ] Stable frame extraction
  - Iterate through video frames via AVAssetImageGenerator
  - Compare consecutive frames via pixel difference
  - Capture frame when difference < 5% (user has stopped swiping)
- [ ] OCR processing via Vision framework
  - VNRecognizeTextRequest on each stable frame
  - Parse Pokemon name, form, gender, shiny status from recognized text
  - Map parsed data to local Pokemon database
- [ ] pHash secondary confirmation (optional)
  - Pre-compute hashes for all official Pokemon Home sprites
  - Compare screen sprite hash to database via Hamming distance
  - Match threshold: distance < 5
- [ ] Verified badge system
  - Mark matched Pokemon as `isVerified = true` in SwiftData
  - Show verified badge on Pokedex list and detail views
  - Track verification date
- [ ] Processing UI
  - Progress indicator during video scan
  - Results summary: "Found 47 Pokemon. 3 new verifications."
  - Review screen before committing results

## Phase 5 — Polish

Production quality. This is a real app, not a demo.

- [ ] Pokedex-themed UI design
  - Color scheme, typography, visual identity
  - Type-colored badges and accents
- [ ] Animations and transitions
  - List/grid transitions
  - Pokemon detail entrance
  - Camera scan effects
- [ ] Sounds and haptics
  - Scan confirmation sounds
  - Haptic feedback on key interactions
- [ ] App icon and launch screen
- [ ] Error handling
  - Network failures (graceful offline behavior)
  - Camera permission denied states
  - Photo library permission denied states
  - Invalid/unrecognizable video input
- [ ] Accessibility
  - VoiceOver support
  - Dynamic Type
- [ ] Performance
  - Lazy loading for large lists
  - Image caching for sprites
  - Background processing for video scanning
