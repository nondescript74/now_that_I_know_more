# Documentation Index

Welcome to the NowThatIKnowMore documentation! This guide will help you understand, set up, and use the recipe sharing and import features.

## 📚 Documentation Structure

### 🛠️ Setup Guides
For developers setting up the project:
- **[Recipe Import Setup](setup/recipe-import-setup.md)** - Configure Info.plist and enable recipe file handling

### 👤 User Guides
For end users of the app:
- **[Recipe Sharing Guide](guides/recipe-sharing.md)** - How to share recipes via email
- **[Recipe Import Guide](guides/recipe-import.md)** - How to import recipes you receive

### 🏗️ Architecture & Implementation
For developers understanding the codebase:
- **[Recipe Import Implementation](architecture/recipe-import-implementation.md)** - Technical details and architecture

## 🚀 Quick Start

### For Developers
1. Read [Recipe Import Setup](setup/recipe-import-setup.md)
2. Configure your Info.plist (5 minutes)
3. Build and test on a device

### For Users
1. Check out [Recipe Sharing Guide](guides/recipe-sharing.md) to send recipes
2. Check out [Recipe Import Guide](guides/recipe-import.md) to receive recipes

## ✨ Features Overview

### Recipe Sharing
- Email recipes with beautiful HTML formatting
- Attach `.recipe` files for easy import
- Include photos in emails
- Availability checking for Mail app

### Recipe Import
- Import from email attachments
- Import from Files app
- Manual import with file picker
- Beautiful preview before importing
- Duplicate detection
- Comprehensive error handling

## 🎯 Common Tasks

| I want to... | Go to... |
|--------------|----------|
| Set up the app for the first time | [Setup Guide](setup/recipe-import-setup.md) |
| Share a recipe with someone | [Sharing Guide](guides/recipe-sharing.md) |
| Import a recipe I received | [Import Guide](guides/recipe-import.md) |
| Understand how it works | [Implementation Guide](architecture/recipe-import-implementation.md) |
| Troubleshoot issues | Check the troubleshooting sections in user guides |

## 📝 File Format

Recipes are shared as `.recipe` files, which are JSON documents with a custom extension. This format:
- Contains all recipe data (ingredients, instructions, photos, etc.)
- Is human-readable
- Works cross-platform
- Can be backed up easily

## 🔒 Privacy & Security

- All sharing is done via standard email or file transfer
- No cloud services or third-party servers involved
- Data stays between sender and recipient
- Security-scoped resource access protects the file system
- No automatic code execution from recipe files

## 🆘 Getting Help

- **Setup issues?** See [Recipe Import Setup](setup/recipe-import-setup.md)
- **Can't share recipes?** See [Recipe Sharing Guide](guides/recipe-sharing.md)
- **Import not working?** See [Recipe Import Guide](guides/recipe-import.md)
- **Technical questions?** See [Implementation Guide](architecture/recipe-import-implementation.md)

## 📱 Requirements

- iOS 17.0+ / iPadOS 17.0+
- Mail app configured (for sending recipes)
- App installed (for receiving recipes)

---

**Last Updated**: November 2025
