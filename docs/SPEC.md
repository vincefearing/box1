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
