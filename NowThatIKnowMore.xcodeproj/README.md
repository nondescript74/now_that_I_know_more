# NowThatIKnowMore

A recipe management app for iOS and iPadOS with powerful sharing and import features.

---

## Features

- 📖 **Recipe Management** - Create, edit, and organize your favorite recipes
- 📧 **Email Sharing** - Share recipes with beautiful HTML emails and importable `.recipe` files
- 📥 **Easy Import** - Import recipes from email attachments or the Files app
- 🔍 **Smart Preview** - Review recipes before importing with duplicate detection
- 📸 **Photo Support** - Add your own photos to recipes
- 🍽️ **Meal Planning** - Plan your meals and grocery shopping

---

## Quick Start

### For Users

1. **Download and install** the app
2. **Browse or create** recipes
3. **Share with friends** using the Email Recipe button
4. **Import recipes** received via email

See the [documentation](docs/README.md) for detailed guides.

### For Developers

1. **Clone this repository**
2. **Open in Xcode 15+**
3. **Configure Info.plist** - See [setup guide](docs/setup/recipe-import-setup.md)
4. **Build and run** on iOS 17.0+

---

## Documentation

Comprehensive documentation is available in the [`docs/`](docs/) directory:

### 📚 All Guides
- **[Documentation Index](docs/README.md)** - Start here for an overview

### 🛠️ Setup
- **[Recipe Import Setup](docs/setup/recipe-import-setup.md)** - Configure your project for recipe import

### 👤 User Guides
- **[Recipe Sharing Guide](docs/guides/recipe-sharing.md)** - How to share recipes via email
- **[Recipe Import Guide](docs/guides/recipe-import.md)** - How to import recipes you receive

### 🏗️ Technical Documentation
- **[Recipe Import Implementation](docs/architecture/recipe-import-implementation.md)** - Architecture and implementation details

---

## Requirements

- **iOS/iPadOS**: 17.0 or later
- **Xcode**: 15.0 or later (for development)
- **Swift**: 5.9 or later

---

## Key Features in Detail

### Recipe Sharing
Share recipes with anyone via email:
- Beautiful HTML email formatting
- Includes all recipe details (ingredients, instructions, photos)
- Attaches a `.recipe` file for easy importing
- Up to 3 photos included in email
- Works with any email app

### Recipe Import
Import recipes from multiple sources:
- **From Email**: Tap `.recipe` attachments to import
- **From Files**: Browse and open `.recipe` files
- **Manual Import**: Use the in-app import button

### Import Preview
Before importing, you can:
- View recipe image and details
- Check ingredients and instructions
- See cooking time and servings
- Detect duplicate recipes
- Review the full recipe

### Smart Duplicate Detection
The app automatically detects if you already have a recipe:
- Warns you before importing duplicates
- Lets you choose to replace or keep existing version
- Uses unique recipe identifiers

---

## Architecture

Built with modern Swift and SwiftUI:
- **SwiftUI** for declarative UI
- **Swift Concurrency** (async/await) for smooth performance
- **Codable** for reliable JSON serialization
- **UIKit Integration** for Mail composition
- **Security-scoped resources** for safe file access

See [technical documentation](docs/architecture/recipe-import-implementation.md) for details.

---

## Project Structure

```
NowThatIKnowMore/
├── docs/                           # Documentation
│   ├── README.md                   # Documentation index
│   ├── setup/                      # Setup guides
│   ├── guides/                     # User guides
│   └── architecture/               # Technical docs
├── NowThatIKnowMore/              # Main app source
│   ├── Models/                     # Data models
│   ├── Views/                      # SwiftUI views
│   ├── ViewModels/                 # View models
│   └── Resources/                  # Assets, etc.
├── Info.plist                      # App configuration
└── README.md                       # This file
```

---

## Contributing

Contributions are welcome! Please:
1. Read the [architecture documentation](docs/architecture/recipe-import-implementation.md)
2. Follow existing code style
3. Add tests for new features
4. Update documentation as needed

---

## Testing

### Running Tests
```bash
# In Xcode
Cmd + U
```

### Test Coverage
- Unit tests for data models
- Integration tests for import/export
- UI tests for critical user flows

See the [implementation guide](docs/architecture/recipe-import-implementation.md#testing-strategy) for testing details.

---

## Troubleshooting

### Common Issues

**Recipe import not working?**
- Check [setup guide](docs/setup/recipe-import-setup.md) for Info.plist configuration
- Verify file extension is `.recipe`
- Make sure app is reinstalled after configuration changes

**Email sharing not available?**
- Configure Mail app in iOS Settings
- Test on a real device (not simulator)

**Need more help?**
- Check the [user guides](docs/guides/)
- Review the [troubleshooting sections](docs/guides/recipe-import.md#troubleshooting)

---

## Privacy

- ✅ All data stored locally on device
- ✅ No cloud services or third-party servers
- ✅ Recipes shared directly via email
- ✅ No tracking or analytics
- ✅ Your data stays yours

---

## License

[Add your license here]

---

## Contact

[Add your contact information here]

---

## Acknowledgments

Built with:
- Swift and SwiftUI
- MessageUI framework for email composition
- SF Symbols for beautiful icons

---

**Ready to start cooking?** 🍳

Check out the [documentation](docs/README.md) to learn more!
