# GlowCycle

GlowCycle is a smart beauty inventory and waste reduction mobile application for the UCCD3223 Mobile Application Development group assignment.

Slogan: **Track beauty. Reduce waste. Glow responsibly.**

## Assignment Coverage

- Custom launcher icon with beauty bottle and circular economy arrow.
- Local mobile storage using `shared_preferences` for product inventory and eco action history.
- External endpoint integration using OpenStreetMap Overpass API for recycling point data.
- CRUD inventory flow: add, view, edit, delete beauty products.
- Expiry calculation from opening date and expiry duration.
- Product status classification: Unopened, Safe, Use Soon, Expired, Finished, Recycled.
- Duplicate purchase reminder through Wishlist Check.
- Eco points and achievement badges.

## Technologies Used

- Flutter 3.44.4
- Dart 3.12.2
- `shared_preferences` for local storage
- `http` for REST API integration
- `intl` for date formatting
- `flutter_launcher_icons` for launcher icon generation

## Main Screens

- Splash screen
- Home dashboard
- Add product
- Inventory
- Product detail
- Wishlist check
- Recycle points
- Eco points

## How to Run

From this project folder:

```bash
flutter pub get
flutter run
```

For Chrome demo:

```bash
flutter run -d chrome
```

For Android emulator or phone:

```bash
flutter devices
flutter run -d <device-id>
```

## Group Contribution Template

| Member | Responsibility |
|---|---|
| Member 1 | Documentation and project coordination |
| Member 2 | UI/UX and frontend |
| Member 3 | Local storage and inventory module |
| Member 4 | External API, recycle points, eco points |

## Notes

The Recycle Points screen first tries to fetch nearby recycling locations from OpenStreetMap Overpass API using a Kampar/UTAR reference location. If the endpoint is unavailable during a demo, the app falls back to curated mock recycling points so the feature remains demonstrable.
