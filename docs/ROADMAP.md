# Roadmap

## Phase 1 — Data Pipeline & Foundation

Set up the ETL pipeline, database, and app structure.

- [x] Python scraper (`scripts/fetch_pokemon_data.py`) to pull all Pokemon from PokemonDB
  - All 1025 Pokemon: name, types, descriptions, sprite URLs, evolution chains, height/weight, locations, regional dex numbers
  - Use `uv` for dependency management
- [x] Supabase database schema
  - Tables: `pokemon`, `types`, `pokemon_types`, `sprites`, `games`, `locations`, `regional_dex_numbers`
  - Migrations managed via Supabase CLI
  - RLS enabled with public read policies
- [x] Load script to insert scraped data into Supabase
- [x] Run full scrape of all 1025 Pokemon and load into database
- [x] Backfill 31 missing descriptions from PokeAPI
- [x] Backfill 5,682 missing locations from Bulbapedia
- [x] `fetch_cries.py` — pull cries from PokeAPI, upload to Supabase Storage
- [ ] Define Swift data models
  - `Pokemon` — struct decoded from Supabase
  - `UserPokemon` — SwiftData model for collection tracking
  - `CollectionStatus` enum: `.unseen`, `.seen`, `.caught`, `.favorite`
- [ ] Project folder structure: Models/, Views/, Services/
- [ ] Supabase client integration in Swift

## Phase 2 — Core Tracker

The main app experience. Browse, search, and track Pokemon across games.

- [ ] Pokedex list view (scrollable grid or list of all Pokemon)
  - Sprite image, name, number, types
  - Search by name or number
  - Filter by type, generation, caught status
  - Filter by game/regional Pokedex
- [ ] Pokemon detail view
  - Full sprite, name, number, types
  - Height, weight
  - Pokedex description
  - Evolution chain
  - Location data per game
  - Cry playback
- [ ] Collection tracking
  - Mark Pokemon as seen, caught, or favorite
  - Collection progress stats (e.g., "342 / 1025 caught")
  - Filter Pokedex by collection status
  - Track per-game completion
- [ ] Tab-based navigation
  - Pokedex tab
  - Collection tab (shows only caught/seen/favorites)
  - Settings tab (future: preferences)

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
  - Debounce: only trigger when prediction changes
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
  - Capture frame when difference < 5%
- [ ] OCR processing via Vision framework
  - VNRecognizeTextRequest on each stable frame
  - Parse Pokemon name, form, gender, shiny status
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
- [ ] Sounds and haptics
- [ ] App icon and launch screen
- [ ] Error handling (network failures, permissions, invalid input)
- [ ] Accessibility (VoiceOver, Dynamic Type)
- [ ] Performance (lazy loading, image caching, background processing)

## Phase 6 — Multi-Platform

Expand beyond iOS.

- [ ] Web app (consuming same Supabase backend)
- [ ] Android app
- [ ] Cloud sync for user data across platforms
