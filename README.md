# NowThatIKnowMore

A recipe manager for iOS and iPadOS. It was the forerunner of [Reczipes](https://github.com/nondescript74/reczipes): an earlier exploration of recipe import, parsing and sharing.

## What it does

- **Recipe library.** You can create, edit and organize recipes, with notes, photos and media.
- **Recipe books.** Recipes can be grouped into books.
- **Import from web pages.** It extracts a recipe from a web page URL using the Spoonacular API, with your own API key entered in the app.
- **Import from photos.** It reads recipe cards and cookbook pages with Apple Vision OCR and parses them into ingredients and steps. There are two parsers, a standard one and an advanced one.
- **Sharing.** You can email a recipe as formatted HTML with an importable `.recipe` file attached.
- **Import with preview.** You can open `.recipe` files from Mail or the Files app, review them, and have duplicates detected before import.
- **Meal planning and glossary.** It includes a simple meal planner and a cooking-terms glossary.

## Tech

- Swift / SwiftUI
- SwiftData for local storage
- Apple Vision (`VNRecognizeTextRequest`) for OCR
- Spoonacular recipe-extraction API for web pages
- A custom document type (`.recipe`) for sharing

## Project layout

| Path | Contents |
|---|---|
| `NowThatIKnowMore/Models/` | SwiftData models: recipes, books, media, notes |
| `NowThatIKnowMore/Views/` | SwiftUI views |
| `ImageParsing/` | OCR-based recipe parsers |
| `SomeDocs/` | Implementation notes |

## Status

This is a personal project that is no longer under active development. Its ideas continue in Reczipes. It is not published on the App Store.

## License

Copyright © 2025–2026 Zahirudeen Premji. All rights reserved. See [LICENSE](LICENSE).
