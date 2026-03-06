# Architecture

## Data Layer

### Supabase Backend

All Pokemon reference data lives in Supabase (PostgreSQL + auto-generated REST API). The iOS app fetches once and caches locally via SwiftData. Delta sync for new Pokemon only.

**Source pipeline:** Python ETL scripts scrape PokemonDB (primary), backfill from PokeAPI (descriptions, cries) and Bulbapedia (locations), then load into Supabase.

**Database tables:**

| Table | Rows | Purpose |
|---|---|---|
| `pokemon` | 1,025 | Core data: name, dex number, height, weight, generation, origin region, description, evolution chain, cry URL |
| `types` | 18 | Type name + color |
| `pokemon_types` | 1,551 | Many-to-many join (pokemon ↔ types) |
| `sprites` | 1,532 | Sprite URLs per form (source of truth for what cards exist) |
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

### User Data

**User Collection (SwiftData — on-device)**

Local-first collection tracking. Works offline. One row per card (form).

- `pokemonId: Int`
- `form: String`
- `isCaught: Bool`
- `isShinyCaught: Bool`
- `isOriginCaught: Bool`

**User Profile (Supabase — `profiles` table)**

Lightweight data powering shareable profiles. Available to all users.

- `user_id`, `display_name`, `user_tag` (unique), `nintendo_id`, `profile_picture_url`
- `total_caught`, `badges`, `team` (favorite 6 Pokemon)
- `created_at`

**Full Collection Sync (Supabase — `user_collections` table) [Premium, Future]**

Mirrors local collection to Supabase for cross-device sync. Table designed when web version launches.

**Data flow by tier:**

| Tier | Collection | Profile | Cross-device sync |
|---|---|---|---|
| Free | Local SwiftData only | Summary stats pushed to Supabase | No |
| Premium | Local SwiftData + Supabase `user_collections` | Summary stats pushed to Supabase | Yes |

## iOS Data Models

**Reference data (Codable structs, read-only):**
- `Pokemon` — flattened model with nested arrays for types, sprites, locations, regional dex numbers, evolution chain
- `Game` — standalone for filtering and region lookups

**User data:**
- `UserPokemon` — SwiftData @Model class, local collection tracking
- `UserProfile` — Codable struct for Supabase profiles table

See [SPEC.md](SPEC.md) for full field definitions.

## AI Strategy (Future — Phase 3+)

### On-Device: Core ML
Instant Pokemon recognition from live camera feed. Image classifier, <50ms inference, >85% confidence.

### Cloud: Claude API (Haiku 4.5)
Contextual descriptions in Ash Ketchum Mode. ~$0.002 per request. API key stored in iOS Keychain.

### On-Device: Vision Framework (OCR)
Read text from Pokemon Home detail screens for Verified Collection.

### On-Device: Perceptual Hashing (pHash)
Secondary visual confirmation for Verified Collection.

## Dependencies (Swift Packages)

- **supabase-swift** — Supabase client (REST API, Auth, Storage)
- Phase 3+: Anthropic Swift SDK or raw URLSession for Claude API
- All other features use Apple frameworks (SwiftData, AVFoundation, Vision, Core ML)
