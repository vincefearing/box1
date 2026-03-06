# Architecture

## Data Layer

### Supabase Backend

All Pokemon reference data lives in Supabase (PostgreSQL + auto-generated REST API). The iOS app fetches once and caches locally via SwiftData. Delta sync for new Pokemon only.

**Source pipeline:** Python ETL scripts scrape PokemonDB (primary), backfill from PokeAPI (descriptions, cries) and Bulbapedia (locations), then load into Supabase.

**Database tables:**

| Table | Rows | Purpose |
|---|---|---|
| `pokemon` | 1,025 | Core data: name, dex number, height, weight, generation, description, evolution chain, cry URL |
| `types` | 18 | Type name + color |
| `pokemon_types` | 1,551 | Many-to-many join (pokemon ↔ types) |
| `sprites` | 1,532 | Sprite URLs per form |
| `games` | 38 | Game name, generation, region |
| `locations` | 23,539 | Where to find each Pokemon per game |
| `regional_dex_numbers` | 10,370 | Per-game Pokedex numbers |

**Storage:** `pokemon-cries` bucket (public) with .ogg cry files for all 1,025 Pokemon.

**Sync strategy:**
```
App Launch
    │
    ▼
Query Supabase: count of pokemon table
    │
    ▼
Compare vs local SwiftData count
    │
    ├─ [same] ──→ Done (use local cache)
    │
    └─ [new Pokemon exist]
         │
         ▼
    Fetch only new entries
         │
         ▼
    Persist to SwiftData
```

### Authentication (Supabase Auth)

Every user creates an account via Supabase Auth. Required even for free tier — shareable profiles need a user identity.

**Methods:** Sign in with Apple (primary), Google/email (optional).

### User Data — Three Layers

**1. User Collection (SwiftData — on-device)**

Local-first collection tracking. Works offline, no network dependency for day-to-day use.

- `pokemonId: Int` — reference to cached Pokemon data
- `status: CollectionStatus` — enum: `.unseen`, `.seen`, `.caught`, `.favorite`
- `isVerified: Bool` — true if confirmed via Verified Collection feature
- `isShiny: Bool`
- `form: String?` — e.g., "Alolan", "Galarian"
- `gender: Gender?` — enum: `.male`, `.female`, `.unknown`
- `verifiedDate: Date?`
- `notes: String?`

**2. User Profile (Supabase — `profiles` table)**

Lightweight summary data powering shareable profiles. Available to all users (free and premium).

- `user_id` — foreign key to Supabase Auth user
- `username`
- `nintendo_id`
- `profile_picture_url`
- `total_caught` — aggregate count, computed from local collection
- `badges` — earned achievements
- `created_at`

**3. Full Collection Sync (Supabase — `user_collections` table) [Premium]**

Mirrors the local SwiftData collection to Supabase for cross-device sync (iOS/web/Android). Table designed now, sync logic built when web version launches.

- `user_id` — foreign key to Supabase Auth user
- Same fields as local SwiftData model
- Bi-directional sync with conflict resolution

**Data flow by tier:**

| Tier | Collection | Profile | Cross-device sync |
|---|---|---|---|
| Free | Local SwiftData only | Summary stats pushed to Supabase | No |
| Premium | Local SwiftData + Supabase `user_collections` | Summary stats pushed to Supabase | Yes — full collection available on all devices |

## AI Strategy

### On-Device: Core ML

**Purpose:** Instant Pokemon recognition from live camera feed.
**Model type:** Image classifier (MobileNet or ResNet architecture).
**Source:** Train via Apple Create ML with Kaggle Pokemon dataset, or source open-source .mlmodel from GitHub.
**Performance target:** <50ms inference, >85% confidence threshold.
**Scope:** Classification only — outputs a Pokemon name, not descriptions.

### Cloud: Claude API (Haiku 4.5)

**Purpose:** Contextual, intelligent descriptions that go beyond static Pokedex entries.
**Use cases:**
1. Ash Ketchum Mode — describe what a Pokemon is doing in context ("This Charizard appears to be a holographic trading card from the Base Set")
2. Future: any feature needing natural language understanding of Pokemon imagery

**Cost:** ~$0.002 per request. Negligible for personal use.

**API key management:**
- Store API key in iOS Keychain (not in source code, not in UserDefaults)
- User enters their own API key in app settings
- Key is never transmitted anywhere except Anthropic's API endpoint

### On-Device: Vision Framework (OCR)

**Purpose:** Read text from Pokemon Home detail screens for Verified Collection.
**Use cases:**
1. Extract Pokemon name from screen
2. Read form labels (Alolan, Galarian, Hisuian, etc.)
3. Detect shiny indicator
4. Read gender symbol

**Why OCR over image matching:** Pokemon Home's detail screen displays all metadata as text. Reading it is near-100% accurate and handles every edge case (forms, variants, shinies, gender) without training data.

### On-Device: Perceptual Hashing (pHash)

**Purpose:** Secondary visual confirmation for Verified Collection.
**How it works:**
1. Pre-compute hash of every official Pokemon sprite, store in local DB
2. At runtime, hash the sprite visible on the captured screen
3. Compare via Hamming distance — match if distance < 5
**Role:** Backup confirmation, not primary identification. OCR is primary.

## Data Flow Diagrams

### Ash Ketchum Mode
```
Camera Frame (60fps)
    │
    ▼
Core ML Classifier ──→ Pokemon ID + Confidence
    │                        │
    │                   [confidence > 85%]
    │                   [!= lastSpoken]
    │                        │
    │                        ▼
    │                  Speak Local Dex Entry
    │                  (AVSpeechSynthesizer)
    │
    ▼ (simultaneously)
Claude API (Haiku)
    │
    ▼
Append Contextual Description
    │
    ▼
Speak Smart Description
```

### Verified Collection
```
User Video (Pokemon Home detail screens)
    │
    ▼
Stable Frame Extraction
(pixel-diff < 5% between frames)
    │
    ▼
Vision OCR ──→ Name, Form, Gender, Shiny
    │
    ▼
Match to Local Pokemon DB
    │
    ▼
(Optional) pHash confirmation
    │
    ▼
Mark as Verified in SwiftData
```

## Dependencies (Swift Packages)

- **supabase-swift** — Supabase client (REST API, Auth, Storage)
- Phase 3+: Anthropic Swift SDK or raw URLSession for Claude API
- All other features use Apple frameworks (SwiftData, AVFoundation, Vision, Core ML)
