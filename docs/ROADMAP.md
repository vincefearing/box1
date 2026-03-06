# Roadmap

## Phase 1 — Data Pipeline & Foundation

Set up the ETL pipeline, database, and app structure.

- [x] Python scraper (`scripts/fetch_pokemon_data.py`) to pull all Pokemon from PokemonDB
- [x] Supabase database schema (pokemon, types, pokemon_types, sprites, games, locations, regional_dex_numbers)
- [x] Load script to insert scraped data into Supabase
- [x] Run full scrape of all 1025 Pokemon and load into database
- [x] Backfill 31 missing descriptions from PokeAPI
- [x] Backfill 5,682 missing locations from Bulbapedia
- [x] `fetch_cries.py` — pull cries from PokeAPI, upload to Supabase Storage
- [x] Backfill `origin_region` column on pokemon table
- [x] Define Swift data models
  - `Pokemon` — Codable struct with nested types (types, sprites, locations, regional dex, evolution chain)
  - `Game` — standalone Codable struct
  - `UserPokemon` — SwiftData model (pokemonId, form, isCaught, isShinyCaught, isOriginCaught)
  - `UserProfile` — Codable struct for Supabase profiles table
- [x] Project folder structure: Models/, Views/, Services/
- [ ] Supabase client integration in Swift
  - Add supabase-swift package
  - Configure client with project URL and publishable key
  - Fetch Pokemon data and decode into models

## Phase 2 — Core Tracker

The main app experience. Browse, search, and track Pokemon.

- [ ] Pokedex list view (scrollable grid of cards)
  - Sprite, name, dex number, type-colored cards
  - Greyed out = uncaught, colored = caught
  - Search by name or number
  - Filter by type, generation, game, region, caught status
  - Sort by dex number, name, type, generation
- [ ] Pokemon detail view
  - Full sprite, name, number, types
  - Height, weight, description
  - Evolution chain
  - Location data per game
  - Cry playback
  - Bulbapedia link
- [ ] Collection tracking
  - Mark Pokemon as caught (single tap)
  - Shiny/origin toggles (premium, hidden for free)
  - Form cards visible when form toggle on (premium)
- [ ] Tab-based navigation
  - Pokedex tab
  - Achievements tab (badges with progress bars)
  - Profile tab
- [ ] Supabase Auth integration
  - Sign in with Apple
  - User profile creation
- [ ] Achievements screen
  - Regional badges with progress bars
  - Mastery tiers (tier 1 free, tiers 2-6 premium)

## Phase 3 — Ash Ketchum Mode (Live Vision)

Point the camera at a Pokemon and the app speaks its Pokedex entry.

- [ ] Source or train Core ML Pokemon classifier
- [ ] Camera view using AVCaptureSession in SwiftUI
- [ ] Core ML integration with confidence threshold
- [ ] Text-to-speech (AVSpeechSynthesizer)
- [ ] Claude API integration for contextual descriptions
- [ ] Overlay UI on camera feed

## Phase 4 — Verified Collection (Screen Scanner)

Scan Pokemon Home to verify your real collection.

- [ ] Video import from Photo Library
- [ ] Stable frame extraction
- [ ] OCR processing via Vision framework
- [ ] pHash secondary confirmation (optional)
- [ ] Verified badge system
- [ ] Processing UI with results review

## Phase 5 — Polish

Production quality.

- [ ] Pokedex-themed UI design
- [ ] Animations and transitions
- [ ] Sounds and haptics
- [ ] App icon and launch screen
- [ ] Error handling
- [ ] Accessibility (VoiceOver, Dynamic Type)
- [ ] Performance (lazy loading, image caching)

## Phase 6 — Multi-Platform & Premium

Expand beyond iOS.

- [ ] Premium subscription (StoreKit)
- [ ] Cross-device sync (Supabase user_collections table)
- [ ] Web app (consuming same Supabase backend)
- [ ] Android app
- [ ] Custom sort ordering (premium)
