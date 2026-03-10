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

## Feature 3: Badge System

### Concept
Six cumulative badges representing escalating collection milestones. Computed live from UserPokemon data. Displayed on the user's shareable profile as prestige bragging rights (like CoD prestige). No notifications or pop-ups — the Progress tab is a live dashboard you check when curious.

### Badges

Cumulative — each badge requires the ones above it.

| Name | Color | Requirement | Requires | Visible When |
|---|---|---|---|---|
| Trainer | Bronze | One of each Pokemon caught (1,025) | — | Always |
| Veteran | Silver | Every form caught | Trainer | Forms enabled |
| Champion | Gold | Every Pokemon caught in home region | Veteran | Origin enabled |
| Master | Platinum | Shiny of each Pokemon (1,025) | — | Shiny enabled |
| Grandmaster | Diamond | Shiny of every form | Master | Shiny + Forms enabled |
| Legend | Prismatic | Shiny + Origin + all forms | Grandmaster + Champion | Shiny + Forms + Origin enabled |

### Badge Behavior
- **Computed, not stored.** Progress derived from UserPokemon data on every catch/uncatch action.
- **Reflects current state.** Uncatching a Pokemon recalculates all affected badges. No permanent trophies.
- **No notifications.** No pop-ups, banners, or alerts. The Progress tab is a live dashboard.
- **Visibility controlled by Settings toggles.** Only badges relevant to your enabled tracking appear.

### Progress Tab
Top-level tab in the iOS tab bar (Pokedex | Progress | Settings | Search). Shows badge progress plus supporting stats:

- **Type completion** — progress per type (18 types)
- **Challenge completion** — thematic groups (Regional Birds, Legendaries, Starters, Fossils, Eeveelutions, etc.)
- **Form completion** — per-category (Megas, Gmax, regional variants) and per-Pokemon (Unown, Vivillon, Alcremie, etc.)
- **Milestones** — threshold markers (1, 50, 151, 500 caught)

Supporting stats are not profile badges — just detailed breakdowns on the Progress tab.

### Profile Display
Profile shows your highest earned badge with its color treatment. One badge, one flex.

See [Badge Registry](../01.%20Quick%20Notes/box1%20Achievement%20Registry.md) for full definitions.

---

## Feature 4: Premium Gating

| Feature | Free | Premium |
|---|---|---|
| Full Pokedex browsing | yes | yes |
| Collection tracking (caught) | yes | yes |
| National Pokedex | yes | yes |
| Latest gen games (Scarlet/Violet, Legends Z-A) | yes | yes |
| Filter by type | yes | yes |
| Show missing filter | yes | yes |
| Standard sorting (dex #, name, type, gen) | yes | yes |
| Stats: caught, forms, females progress | yes | yes |
| Older game Pokedex filters | no | yes |
| Generation filter | no | yes |
| Shiny tracking toggle | no | yes |
| Origin tracking toggle | no | yes |
| Nickname field | no | yes |
| Notes field | no | yes |
| Form tracking toggle | no | yes |
| Stats: shiny + origin progress | no | yes |
| Advanced sorting (custom order, caught status) | no | yes |
| Veteran/Champion/Master/Grandmaster/Legend badges | no | yes |
| Cross-device sync | no | yes |

Free tier = solid living dex tracker with National + latest gen, type filtering, and basic stats. Premium = full game library, shiny/origin/form tracking, nickname/notes, advanced filters and sorting, full stats, and cross-device sync.

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
