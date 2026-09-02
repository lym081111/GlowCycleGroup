# GlowCycle Group Project

This repository starts with a runnable Flutter integration shell maintained by
the team leader and the image OCR/Add Product feature maintained by Member 3.
The remaining features are intentionally represented by integration
placeholders so their owners can contribute them through separate branches and
pull requests.

## Included ownership

- Team Leader: app entry point, navigation shell, shared theme, Firebase
  bootstrap, Android/web scaffold, assets, and integration testing.
- Member 3: camera/gallery input, ML Kit OCR, Gemini structured extraction,
  scan review, editable product form, and the shared product result contract.

## Feature branches

- `feature/authentication`
- `feature/chatbot-inventory`
- `feature/ocr-product-scan`
- `feature/recycling-map`

Each member should commit only their assigned implementation and open a pull
request into `main`. Do not commit `.env`, service-account files, keystores, or
build output.

## Run

```powershell
flutter pub get
flutter run
```
