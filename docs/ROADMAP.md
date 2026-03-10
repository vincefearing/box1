# Roadmap

## Phase 1 — Data Pipeline & Foundation ✓

Set up the ETL pipeline, database, and app structure.

- [x] Python scraper (`scripts/fetch_pokemon_data.py`) to pull all Pokemon from PokemonDB
- [x] Supabase database schema (pokemon, types, pokemon_types, sprites, games, locations, regional_dex_numbers)
- [x] Load script to insert scraped data into Supabase
- [x] Run full scrape of all 1025 Pokemon and load into database
- [x] Backfill 31 missing descriptions from PokeAPI
- [x] Backfill 5,682 missing locations from Bulbapedia
- [x] `fetch_cries.py` — pull cries from PokeAPI, upload to Supabase Storage
- [x] Convert cries from OGG to M4A for iOS compatibility (`convert_cries.py`)
- [x] Backfill `origin_region` column on pokemon table
- [x] Define Swift data models
  - `Pokemon` — Codable struct with nested types (types, sprites, locations, regional dex, evolution chain)
  - `Game` — standalone Codable struct
  - `UserPokemon` — SwiftData model (pokemonId, form, isCaught, isShinyCaught, isOriginCaught, nickname, notes)
  - `UserProfile` — Codable struct for Supabase profiles table
- [x] Project folder structure: Models/, Views/, Services/
- [x] Supabase client integration in Swift
  - Add supabase-swift package
  - Configure client with project URL and publishable key
  - Fetch Pokemon data and decode into models

## Phase 2 — Core Tracker (in progress)

The main app experience. Browse, search, and track Pokemon.

### Done
- [x] Pokedex grid view (3-column LazyVGrid)
  - Sprite, name, dex number, type-colored cards
  - Greyed out = uncaught, colored = caught
  - Search via `Tab(role: .search)` (iOS 26)
  - Filter by type (multi-select sheet), generation, show missing
  - Sort by dex number asc/desc, name A-Z/Z-A
  - Game selector (persistent via @AppStorage) with regional dex numbers
  - Pinned stats header with caught count + progress bar
  - Scroll-to-top button
- [x] Pokemon detail view
  - Full sprite (lazy-loaded), name, number, types
  - Height, weight, generation, region
  - Description (with proper casing)
  - Location data per game (filtered by selected game, collapsed)
  - Cry playback (M4A via AVPlayer)
  - Nickname and notes fields
  - Caught/shiny/origin toggle buttons
- [x] Collection tracking
  - Context menu (long press): mark caught, shiny, origin
  - Select mode for bulk catch/uncatch
  - Form-independent tracking (each form is its own entry)
  - Shiny/origin auto-mark as caught
- [x] Form support
  - Mega, Gigantamax, Female, Other form categories
  - Custom SVG form icons as card badges
  - Form availability filtering by game (Megas only in Gen 6-7 + Z-A, Gmax only Sword/Shield, regional variants per game, etc.)
  - Settings toggles for each form category
- [x] Shiny tracking: sprite swaps to shiny version + sparkle indicator
- [x] Origin tracking: type-colored border on card
- [x] Lazy sprite loading (on-demand with local caching)
- [x] Tab-based navigation (Pokedex, Settings, Search)
- [x] Settings view (form toggles, tracking toggles)

### Not Done
- [ ] UI tweaks
  - Game selector label → "Pokedex", app title → "box1"
  - "National Pokedex" renamed to "National"
- [ ] Uncatch warning dialog (notes + nickname will be deleted, "Don't show me this again" checkbox)
- [ ] Stats view (tab/page/dropdown — TBD)
  - Caught progress
  - Forms completion
  - Females completion
  - Shiny completion (premium gated)
  - Origin completion (premium gated)
- [ ] Evolution chain display in detail view
- [ ] Supabase Auth (Sign in with Apple)
- [ ] Premium gating (StoreKit + feature gates)
  - Shiny tracking toggle
  - Origin tracking toggle
  - Nickname and notes fields
  - All Pokedex/game filters except National and latest gen (Scarlet/Violet, Legends Z-A)
  - Filters beyond type and show missing (e.g., generation filter)
  - Shiny and origin stats
- [ ] Fix `origin_region` backfill (separate Hisui from Galar, Unknown for Meltan/Melmetal)

### Deferred
- Badge system (6 cumulative badges, Progress tab, milestones)
- Profile view (shareable profile, badge display)
- Cross-device sync

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
- [ ] Performance optimization

## Phase 6 — Multi-Platform & Premium

Expand beyond iOS.

- [ ] Premium subscription (StoreKit)
- [ ] Cross-device sync (Supabase user_collections table)
- [ ] Web app (consuming same Supabase backend)
- [ ] Android app
- [ ] Custom sort ordering (premium)
