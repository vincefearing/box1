# Feature Specifications

## Feature 1: Ash Ketchum Mode (Live Vision)

### Concept
Point the camera at any Pokemon — on a game screen, trading card, plushie, poster — and the app instantly identifies it and speaks a Pokedex entry like the anime. Then it goes further: Claude API analyzes the specific image and appends contextual commentary.

### User Flow
1. User opens Ash Ketchum Mode from the main tab bar
2. Live camera feed fills the screen
3. User points camera at a Pokemon
4. Within ~50ms, the app identifies the Pokemon and displays an overlay card (name, type, sprite)
5. The app immediately begins speaking the local Pokedex entry
6. Simultaneously, the captured frame is sent to Claude API (Haiku 4.5)
7. When the local entry finishes, the app seamlessly speaks Claude's contextual description
8. If the user points at a different Pokemon, the cycle restarts

### Technical Implementation

#### Camera Pipeline
- `AVCaptureSession` with `.builtInWideAngleCamera`
- Capture output: `AVCaptureVideoDataOutput` delivering `CMSampleBuffer` frames
- SwiftUI wrapper via `UIViewRepresentable`
- Frame processing: every Nth frame (tuned for performance vs responsiveness)

#### Core ML Classifier
- **Architecture:** MobileNetV2 or ResNet50 (balance of speed and accuracy)
- **Input:** 224x224 RGB image (standard for most classifiers)
- **Output:** Pokemon name + confidence score
- **Performance:** <50ms inference on iPhone 12+
- **Coverage:** All 1025 Pokemon (Gen 1-9)
- **Source options:**
  1. Open-source .mlmodel from GitHub (preferred if comprehensive)
  2. Train from scratch: Kaggle Pokemon dataset -> Apple Create ML -> .mlmodel
  3. Train from scratch: Python (TensorFlow/PyTorch) -> coremltools conversion

#### Debounce Logic
```
var lastSpokenPokemon: String? = nil
var lastPredictionTime: Date = .distantPast
let cooldownInterval: TimeInterval = 3.0

func handlePrediction(_ name: String, confidence: Float) {
    guard confidence > 0.85 else { return }
    guard name != lastSpokenPokemon else { return }
    guard Date().timeIntervalSince(lastPredictionTime) > cooldownInterval else { return }

    lastSpokenPokemon = name
    lastPredictionTime = Date()
    speakEntry(for: name)
    fetchClaudeDescription(for: name, image: currentFrame)
}
```

#### Text-to-Speech
- `AVSpeechSynthesizer`
- Voice: `com.apple.voice.premium.en-US.Zoe` (or similar premium identifier)
- Rate: slightly slower than default for dramatic effect
- Queue: local entry first, Claude description appended after

#### Claude API Call
- **Model:** claude-haiku-4-5-20251001
- **Input:** captured camera frame (JPEG, ~100KB) + text prompt
- **Prompt:** `"You are a Pokedex AI. The Pokemon in this image has been identified as [name]. Describe what this specific instance of [name] is — is it a trading card, a game screenshot, a plushie, artwork? Be brief (2-3 sentences). Speak as a Pokedex would."`
- **Expected latency:** 1-2 seconds (runs while local entry is being spoken)
- **Fallback:** If API fails or times out (5s), skip contextual description gracefully

#### Overlay UI
- Semi-transparent card at bottom of camera view
- Pokemon name (large), types (colored badges), Pokedex number
- Small sprite from bundled data
- Animates in from bottom on recognition, fades out when camera moves away
- Shows "Analyzing..." indicator while waiting for Claude response

---

## Feature 2: Verified Collection (Screen Scanner)

### Concept
Record yourself swiping through individual Pokemon detail screens in Pokemon Home. The app processes the video, reads each Pokemon's info via OCR, and awards "Verified" badges to your collection — proving you actually own these Pokemon.

### User Flow
1. User records a screen recording on their iPhone while swiping through Pokemon Home detail views, one Pokemon at a time
2. User opens Verified Collection scanner in box1
3. User selects the video from their Photo Library
4. App processes the video:
   - Extracts stable frames (when scrolling stops)
   - OCR reads Pokemon name, form, gender, shiny status from each frame
   - Matches to local database
5. App presents results: "Found 47 Pokemon. 12 new to your collection."
6. User reviews and confirms
7. Confirmed Pokemon are marked as Verified in their collection

### Technical Implementation

#### Video Import
- `PHPickerViewController` for video selection from Photo Library
- Filter: `.videos` only
- Copy video to temporary storage for processing

#### Stable Frame Extraction
```
Algorithm:
1. Step through video using AVAssetImageGenerator
2. Sample frames at ~0.5 second intervals
3. For each pair of consecutive frames:
   a. Convert to grayscale
   b. Resize to small comparison size (e.g., 64x64)
   c. Calculate mean absolute pixel difference
   d. If difference < threshold (5%), frame is "stable"
4. From stable regions, capture one high-resolution frame
5. Skip forward to next region of motion
```
- `AVAssetImageGenerator` with `appliesPreferredTrackTransform = true`
- Output: array of `CGImage` — one per stable Pokemon screen

#### OCR Processing (Vision Framework)
- `VNRecognizeTextRequest` with `.accurate` recognition level
- For each stable frame:
  1. Run text recognition
  2. Extract all recognized text strings with bounding boxes
  3. Parse for:
     - **Pokemon name:** largest/most prominent text, cross-reference with local database
     - **Form:** look for keywords: "Alolan", "Galarian", "Hisuian", "Paldean", "Mega", "Gigantamax"
     - **Shiny:** detect shiny icon/indicator in expected screen region
     - **Gender:** detect male/female symbol
     - **Level:** extract number following "Lv." pattern
  4. Match parsed name + form to local Pokemon database entry

#### pHash Secondary Confirmation (Optional)
- Pre-compute perceptual hash for every official Pokemon Home sprite
- Store in local SQLite or JSON alongside bundled Pokemon data
- At runtime:
  1. Crop the Pokemon model/sprite region from the stable frame
  2. Generate pHash of cropped region
  3. Compare to stored hashes via Hamming distance
  4. Match if distance < 5
- Purpose: backup verification, not primary ID

#### Verification Data Model
```swift
// Extension of UserPokemon (SwiftData)
var isVerified: Bool = false
var verifiedDate: Date?
var verifiedForm: String?
var verifiedShiny: Bool = false
var verifiedGender: Gender?
```

#### Results UI
- Processing screen with progress bar and live count
- Results summary screen:
  - Total Pokemon found in video
  - New verifications (not previously verified)
  - Already verified (duplicates)
  - Unrecognized frames (couldn't parse)
- Detail list: each found Pokemon with parsed data, tap to review
- "Confirm All" and individual confirm/reject per Pokemon
- After confirmation, Pokedex list shows verified badges

### Pokemon Home Screen Layout Notes
- Detail view shows: Pokemon model (center), name (top), type(s), level, nature, ability, OT, moves
- Text is consistently positioned — OCR should reliably extract from known regions
- Different iPhone screen sizes may shift text positions slightly — use relative positioning or full-frame OCR
- Dark mode vs light mode in Pokemon Home may affect OCR accuracy — test both

---

## Feature 3: Pokedex & Collection Tracking

### Concept
One Pokedex with all 1,025 Pokemon. Powerful filtering and toggleable tracking layers make it adapt to any play style — from casual living dex to hardcore shiny origin collector. No creating multiple Pokedexes. Simple, focused, flexible.

### How It Works

1. Every user has one Pokedex containing all Pokemon
2. Users mark Pokemon as caught (honor system)
3. Toggle tracking layers on/off:
   - **Shiny tracking:** adds shiny row to each card
   - **Origin tracking:** adds origin row to each card (user marks if caught in home region)
   - **Forms:** show/hide alternate form cards (Mega, Gigantamax, Alolan, gender variants, etc.)
4. Filter the view by: game, region, type, generation, caught status
5. Badges are computed from collection data as achievements

### Filters
- **Game:** show only Pokemon available in a specific game (Red/Blue, Scarlet/Violet, etc.)
- **Region:** show only Pokemon from a specific region (Kanto, Johto, etc.)
- **Type:** filter by Pokemon type (Fire, Water, etc.)
- **Generation:** filter by generation
- **Caught status:** all / caught / uncaught
- **Forms:** show/hide alternate forms and gender variants

### Sorting

**Free:**
- Dex number (default)
- Name (A-Z, Z-A)
- Type
- Generation

**Premium:**
- Custom ordering (drag to reorder)
- Sort by caught status (uncaught first)
- Sort by recently caught
- Sort by game availability

### Tracking Toggles
These add/remove rows on the cards globally:
- **Shiny:** shows shiny caught status row on every card
- **Origin:** shows origin region status row on every card (user self-reports)

### Premium Gating

| Feature | Free | Premium |
|---|---|---|
| Full Pokedex browsing | yes | yes |
| Collection tracking (caught) | yes | yes |
| Shareable profile | yes | yes |
| Filter by game/region/type/gen | yes | yes |
| Standard sorting (dex #, name, type, gen) | yes | yes |
| Shiny tracking toggle | no | yes |
| Origin tracking toggle | no | yes |
| Form tracking toggle | no | yes |
| Advanced sorting (custom order, caught status, recent) | no | yes |
| Badge mastery tiers 2-6 | no | yes |
| Cross-device sync | no | yes |

Free tier = solid living dex tracker with filtering. Premium = shiny/origin/form tracking, advanced sorting, full badge system, and cross-device sync.

---

## Feature 4: Pokedex Card Design

### Card Variants
Every form gets its own card. Gender differences (where the Pokemon has a visually distinct male/female sprite) are treated as separate forms and get their own cards.

Examples:
- **Ivysaur** (no gender difference, no forms): 1 card
- **Venusaur** (gender difference + mega + gigantamax): 4 cards (default, female, mega, gigantamax)
- **Charizard** (no gender difference, mega-x, mega-y, gigantamax): 4 cards
- **Pikachu** (gender difference + gigantamax + 8 cap variants): 11 cards

The sprites table in Supabase is the source of truth for what cards exist. Every row in the sprites table = one card.

### Card Layout
Each card has a sprite area and up to three status rows below it. Shiny and origin rows only appear when those tracking toggles are enabled (premium).

```
┌─────────────────┐
│                  │
│    [sprite]      │
│                  │
├─────────────────┤  ← always visible
│ #1 Bulbasaur     │  colored = caught, greyed = uncaught
├─────────────────┤  ← only if shiny tracking on (premium)
│ SHINY ✦          │  colored = shiny caught, greyed = not caught
├─────────────────┤  ← only if origin tracking on (premium)
│ Origin           │  colored = caught in home region, greyed = not yet
└─────────────────┘
```

Each row is independent:
- Name row: colored with primary type color when caught
- Shiny row: colored (gold/yellow) when shiny variant caught
- Origin row: colored when user marks it as caught in home region

A Pokemon can have shiny caught without origin, origin without shiny, etc. They are three separate flags, not cumulative. All tracking is honor-based.

### Card States
- **Fully uncaught:** all rows greyed out
- **Caught only:** name row colored, shiny + origin greyed
- **Caught + shiny:** name + shiny colored, origin greyed
- **Caught + origin:** name + origin colored, shiny greyed
- **Everything:** all rows colored

### List View
- Sprite image
- Dex number + name
- Card background color based on primary (first) type color
- Caught = full color card, uncaught = greyed out card
- Shiny and origin rows visible based on tracking toggles

### Detail View
- Everything from list view
- Locations per game
- Type names (text)
- Evolution chain
- Height, weight
- Pokedex description
- Cry playback
- Link to Bulbapedia page

---

## Feature 5: Badges

### Concept
Badges are achievements with progress bars, computed from UserPokemon data. Displayed on a dedicated achievements screen and on the user's shareable profile. Badges ARE the overall progress tracker — there is no separate Master Collection view.

### Badge Types

**Regional badges:** earned by catching all Pokemon from a specific region (e.g., all 151 Kanto Pokemon → "Kanto Badge"). Each regional badge has mastery tiers.

**Global badges:** total collection milestones (e.g., "Catch 500 Pokemon", "Complete the National Dex").

### Mastery Tiers (Premium — tiers 2-6)
Cumulative — each tier includes everything from the previous:

| Tier | Name | Requirement |
|---|---|---|
| 1 | Living Dex | One of each Pokemon (free) |
| 2 | Form Dex | Tier 1 + all forms |
| 3 | Origin Dex (Mastery) | Tier 2 + all caught in home region |
| 4 | Shiny Living Dex | Shiny of each Pokemon |
| 5 | Shiny Form Dex | Tier 4 + shiny of all forms |
| 6 | Shiny Origin Dex (Shiny Mastery) | Tier 5 + all shiny caught in home region |

### Badge Display
- Dedicated achievements screen with progress bars
- Each badge shows: name, description (e.g., "Complete the Kanto Pokedex"), progress bar, current tier
- Shareable profile shows earned badges

---

## Feature 6: Data Models

### Pokemon (reference data, from Supabase, cached in SwiftData)

| Field | Type | Purpose |
|---|---|---|
| dexNumber | Int | National dex number (primary key) |
| name | String | Pokemon name |
| generation | Int | When introduced (kept for future use) |
| originRegion | String | Home region (Kanto, Johto, etc.) — for origin badges |
| height | Decimal | Height |
| weight | Decimal | Weight |
| description | String | Pokedex flavor text |
| evolutionChain | JSON | Nested tree structure |
| cryUrl | String | URL to cry audio in Supabase Storage |
| types | [PokemonType] | Nested array |
| sprites | [PokemonSprite] | Nested array |
| locations | [PokemonLocation] | Nested array |
| regionalDexNumbers | [RegionalDexEntry] | Nested array |

**PokemonType** (nested)

| Field | Type |
|---|---|
| name | String |
| color | String |

**PokemonSprite** (nested)

| Field | Type |
|---|---|
| form | String |
| normalUrl | String |
| shinyUrl | String? |

**PokemonLocation** (nested)

| Field | Type |
|---|---|
| game | String |
| region | String |
| locationInfo | JSON |

**RegionalDexEntry** (nested)

| Field | Type |
|---|---|
| game | String |
| number | Int |

### Game (reference data, standalone)

| Field | Type | Purpose |
|---|---|---|
| id | Int | Primary key |
| name | String | Game name |
| generation | Int | Which gen |
| region | String | Kanto, Johto, etc. |

### UserPokemon (local, SwiftData)

| Field | Type | Purpose |
|---|---|---|
| id | UUID | Unique identifier |
| pokemonId | Int | Dex number |
| form | String | "default", "female", "mega", etc. |
| isCaught | Bool | Caught status |
| isShinyCaught | Bool | Shiny caught status |
| isOriginCaught | Bool | Caught in home region (honor-based) |

Future (premium): add `sortOrder: Int?` for custom drag-to-reorder sorting.

### UserProfile (Supabase)

| Field | Type | Purpose |
|---|---|---|
| userId | UUID | Foreign key to Supabase Auth |
| displayName | String | Anything the user wants, not unique |
| userTag | String | Unique identifier for sharing (e.g., "ash#4721") |
| nintendoId | String? | Nintendo account ID |
| profilePictureUrl | String? | Avatar |
| totalCaught | Int | Computed from UserPokemon |
| badges | JSON | Earned achievements |
| team | [{ pokemonId, form }] | Favorite 6 Pokemon displayed on profile |
| createdAt | Date | Account creation |

### Model Summary
- **Pokemon + nested types**: read-only reference data, fetched once from Supabase, cached locally
- **Game**: read-only reference data, standalone for filtering and region lookups
- **UserPokemon**: local collection tracking, one row per card (form), three independent status flags
- **UserProfile**: cloud-stored in Supabase, powers shareable profiles and achievements display
