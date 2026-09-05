# GlowCycle

GlowCycle is a smart beauty inventory and waste reduction mobile application for
the UCCD3223 Mobile Application Development group assignment.

Slogan: **Track beauty. Reduce waste. Glow responsibly.**

## Assignment Coverage

### SDG 12 and Circular Economy Alignment

- **Behavioural transformation:** expiry priorities, a duplicate-purchase
  check, and a real seven-day no-buy challenge prompt users to use what they
  already own before purchasing more.
- **Closing the loop:** the Cycle Plan connects a finished cosmetic product to
  its empty-container log and live nearby recycling locations, so a user can
  move from use to handoff rather than treating disposal as an afterthought.
- **Data-driven utility:** product dates turn into Safe, Use Soon, Expired,
  Finished, and Recycled states, giving users a concrete next action for each
  stage of the beauty-product lifecycle.

Minimum requirements:

- **Custom launcher icon** — beauty bottle with a circular economy arrow,
  generated for Android through `flutter_launcher_icons`.
- **Stores, updates and retrieves data on the device** — every shelf and eco
  action is written to `shared_preferences`, which also serves as the offline
  fallback when Cloud Firestore is unreachable.
- **External endpoint** — recycling locations come live from the OpenStreetMap
  Overpass API, searched around the device's GPS position.

Beyond the minimum:

- Firebase Authentication, Cloud Firestore, and Firebase Storage, scoped per
  user by security rules in `firestore.rules`.
- Gemini 3.5 Flash through Firebase AI Logic for product extraction and
  skincare guidance, with no API key shipped in the app.
- On-device ML Kit OCR, so packaging text is read at the edge before anything
  reaches the network.

## Main Features

**Beauty shelf** — full create, read, update, and delete over products, each
with category, purchase and opening dates, PAO duration, status, notes, price,
ingredients, and photos.

**Expiry intelligence** — expiry is derived from the opening date plus the
Period After Opening, and products resolve to Safe, Unopened, Use Soon,
Expired, Finished, or Recycled. A product is flagged Use Soon within 60 days of
expiry.

**AI scan** — photograph the front of a package and the ingredient panel on the
back. ML Kit reads both on-device, then Gemini merges them into one record:
name, brand, category, ingredients, dates, PAO, and batch number. Every result
is shown for review before it touches the form, and the sheet says whether
Gemini or on-device OCR produced it.

**Glow Assistant** — skincare guidance grounded in the user's own shelf.
Answers are checked against the inventory before display, never recommend
expired or finished products, refuse unsafe suggestions for eye concerns, and
fall back to an offline rule engine that labels itself as such.

**Duplicate purchase check** — counts what the user already owns in a category
before they buy another one.

**Recycle points** — live OpenStreetMap data around the device's location. The
search widens from 25 km to 100 km to 400 km when nothing is mapped nearby, and
each point links out to Google Maps. There is deliberately no mock data: an area
with nothing mapped is reported as a finding, and the screen invites the user to
add real locations to OpenStreetMap.

**Cycle Plan and impact record** — turns shelf data into an explicit circular
workflow: use a product before it expires, mark it finished, take the empty
container to a live recycling location, and record the handoff. It also
supports a seven-day no-buy challenge and duplicate-purchase check to nudge
more sustainable decisions. The impact view shows total eco points, unlocked
badges, traceable actions, and a lifecycle-completion rate derived from real
product outcomes. Points follow the assignment rules: add product +1, finish
before expiry +10, recycle container +15, avoid a duplicate purchase +5, and
complete the seven-day no-buy challenge +20.

## Project Structure

```
lib/
  main.dart              entry point and root widget
  core/                  shared constants and parsing helpers
  theme/                 colour palette, Material 3 theme, status styles
  models/                BeautyProduct, EcoAction, RecyclePoint, ProductScanResult,
                         AssistantReply, InventoryStats, BadgeRule, NoBuyChallenge
  services/              FirebaseBootstrap, GlowStore, ProductScanService,
                         RecycleService
  widgets/               reusable cards, chips, form fields, navigation
  screens/               one file per screen
firestore.rules          per-user security rules
```

## Technologies Used

- Flutter 3.44 and Dart 3.12, Material 3
- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`,
  `firebase_app_check`
- `firebase_ai` for Gemini 3.5 Flash
- `google_mlkit_text_recognition` for on-device OCR
- `geolocator` for the recycle point search
- `url_launcher` to open a location in Google Maps
- `http` for the Overpass REST API
- `shared_preferences`, `intl`, `image_picker`, `flutter_launcher_icons`

## Running the Project

```bash
flutter pub get
flutter run
```

### Firebase setup

`lib/firebase_options.dart`, `android/app/google-services.json`, and
`firebase.json` are committed with the group's shared project. If you point the
app at your own Firebase project, keep those changes out of your commits:

```bash
git update-index --skip-worktree android/app/google-services.json \
  lib/firebase_options.dart firebase.json
flutterfire configure
```

Your project needs Email/Password authentication, a Cloud Firestore database,
and Firebase AI Logic enabled with the Gemini Developer API. Deploy the rules
with:

```bash
firebase deploy --only firestore:rules
```

### App Check on debug builds

Debug builds attest through the App Check debug provider, which mints a token
per installation. Until that token is allow-listed, Firestore and Gemini calls
are rejected. Find it in the launch log:

```
DebugAppCheckProvider: Enter this debug secret into the allow list ...
```

and add it under App Check → Apps → Manage debug tokens. The token changes
whenever the app is reinstalled or its data cleared.

## Notes on Live Data

OpenStreetMap coverage for `amenity=recycling` varies sharply across Malaysia.
Around Ipoh the search returns points within a few kilometres; other areas
return nothing within 25 km, which is why the search widens and why an empty
result is presented as a finding about open data rather than hidden behind
invented locations.

## Group Contribution

Each member should develop their assigned module on a feature branch and open
a pull request into `main`. This keeps every contribution visible in GitHub's
commit and pull-request history. Do not commit `.env`, service-account files,
keystores, debug tokens, or build output.

| Member | Student ID | Responsibility |
|---|---|---|
| Lam Chee Sin | 2106461 | |
| Lee Wen Qi | 2400409 | |
| Liew Yi Mei | 2205280 | |
| Wong Hao Yin | 2206517 | |

Practical group P1, Group 4. Tutor: Mr. Tan Chiang Kang.
