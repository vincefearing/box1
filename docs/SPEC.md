# Feature Specifications

## Feature 1: Pokedex & Collection Tracking

### Concept
One Pokedex with all 1,025 Pokemon. Powerful filtering and toggleable tracking layers make it adapt to any play style — from casual living dex to hardcore shiny origin collector. No creating multiple Pokedexes. Simple, focused, flexible. All tracking is honor-based.

### How It Works

1. Every user has one Pokedex containing all Pokemon
2. Users mark Pokemon as caught
3. Toggle tracking layers on/off (premium):
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
- Sort by game availability

### Tracking Toggles (Premium)
These add/remove rows on the cards globally:
- **Shiny:** shows shiny caught status row on every card
- **Origin:** shows origin region status row on every card (user self-reports)

---

## Feature 2: Pokedex Card Design

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

Three separate flags, not cumulative.

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

## Feature 3: Badges

### Concept
Badges are achievements with progress bars, computed from UserPokemon data. Displayed on a dedicated achievements screen and on the user's shareable profile. Badges ARE the overall progress tracker — there is no Master Collection view.

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

## Feature 4: Premium Gating

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
| Advanced sorting (custom order, caught status) | no | yes |
| Badge mastery tiers 2-6 | no | yes |
| Cross-device sync | no | yes |

Free tier = solid living dex tracker with filtering. Premium = shiny/origin/form tracking, advanced sorting, full badge system, and cross-device sync.

---

## Feature 5: Ash Ketchum Mode (Live Vision) — Future

Point the camera at any Pokemon and the app speaks its Pokedex entry. Claude API adds contextual commentary.

See [ARCHITECTURE.md](ARCHITECTURE.md) for data flow diagrams and technical details.

---

## Feature 6: Verified Collection (Screen Scanner) — Future

Scan Pokemon Home screens via OCR to verify your real collection. Awards verified badges.

---

## Data Models

### Pokemon (reference data, from Supabase, cached in SwiftData)

| Field | Swift Type | Purpose |
|---|---|---|
| dexNumber | Int | National dex number (primary key) |
| name | String | Pokemon name |
| generation | Int | When introduced (kept for future use) |
| originRegion | String | Home region (Kanto, Johto, etc.) — for origin badges |
| height | Double | Height |
| weight | Double | Weight |
| description | String? | Pokedex flavor text (nullable) |
| evolutionChain | EvolutionNode | Nested tree structure (recursive struct) |
| cryUrl | String | URL to cry audio in Supabase Storage |
| types | [PokemonType] | Nested array |
| sprites | [PokemonSprite] | Nested array |
| locations | [PokemonLocation] | Nested array |
| regionalDexNumbers | [RegionalDexEntry] | Nested array |

**EvolutionNode** (nested, recursive)

| Field | Swift Type |
|---|---|
| name | String |
| evolvesTo | [EvolutionNode] |

**PokemonType** (nested)

| Field | Swift Type |
|---|---|
| name | String |
| color | String |

**PokemonSprite** (nested)

| Field | Swift Type |
|---|---|
| form | String |
| normalUrl | String |
| shinyUrl | String? |

**PokemonLocation** (nested)

| Field | Swift Type |
|---|---|
| gameId | Int |
| locationInfo | String |

**RegionalDexEntry** (nested)

| Field | Swift Type |
|---|---|
| gameId | Int |
| regionalNumber | Int |

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
| badges | [Badge] | Earned achievements |
| team | [TeamMember] | Favorite 6 Pokemon displayed on profile |
| createdAt | Date | Account creation |

### Model Summary
- **Pokemon + nested types**: read-only reference data, fetched once from Supabase, cached locally
- **Game**: read-only reference data, standalone for filtering and region lookups
- **UserPokemon**: local collection tracking, one row per card (form), three independent status flags
- **UserProfile**: cloud-stored in Supabase, powers shareable profiles and achievements display
