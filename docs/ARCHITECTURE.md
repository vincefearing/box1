# Architecture

## Data Layer

### Bundled Pokemon Data

All Pokemon data is shipped with the app as a single `pokemon.json` file in the app bundle.

**Source:** PokeAPI (https://pokeapi.co/)
**Generation:** Python script (`scripts/fetch_pokemon_data.py`) pulls all data once and outputs structured JSON.
**Update strategy:** On app launch, check PokeAPI for total Pokemon count. If count > local count, fetch only new entries and persist via SwiftData.

**Schema per Pokemon:**
```json
{
  "id": 25,
  "name": "Pikachu",
  "types": ["Electric"],
  "stats": {
    "hp": 35, "attack": 55, "defense": 40,
    "sp_attack": 50, "sp_defense": 50, "speed": 90
  },
  "height": 4,
  "weight": 60,
  "abilities": ["Static", "Lightning Rod"],
  "description": "When several of these Pokemon gather, their electricity can build and cause lightning storms.",
  "sprite_url": "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png",
  "generation": 1,
  "evolution_chain_id": 10,
  "forms": ["default"],
  "is_legendary": false,
  "is_mythical": false
}
```

### User Data (SwiftData)

Stored on-device. Never leaves the phone.

**UserPokemon model:**
- `pokemonId: Int` — reference to bundled data
- `status: CollectionStatus` — enum: `.unseen`, `.seen`, `.caught`, `.favorite`
- `isVerified: Bool` — true if confirmed via Verified Collection feature
- `isShiny: Bool`
- `form: String?` — e.g., "Alolan", "Galarian"
- `gender: Gender?` — enum: `.male`, `.female`, `.unknown`
- `verifiedDate: Date?`
- `notes: String?`

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

### Data Sync
```
App Launch
    │
    ▼
Check PokeAPI: GET /api/v2/pokemon?limit=1
    │
    ▼
Compare count vs local JSON count
    │
    ├─ [same] ──→ Done
    │
    └─ [new Pokemon exist]
         │
         ▼
    Fetch only new entries
         │
         ▼
    Persist to SwiftData
```

## Future: Supabase Backend

When a web app version is built, Supabase will handle cloud sync across platforms.

- **SwiftData stays** as the local cache on iOS (offline support)
- **Supabase** becomes the source of truth for user collection data
- Sync strategy: local-first, push changes to Supabase when online, pull on launch
- Web app reads/writes directly to Supabase
- Keep all data models serializable and clean to make migration straightforward

## Dependencies (Swift Packages)

TBD — will be added as we build each phase. Likely candidates:
- None for Phase 1-2 (all Apple frameworks)
- Anthropic Swift SDK or raw URLSession for Claude API in Phase 3
- supabase-swift for future backend integration
