# Quick Start Guide

## Running the App

1. **Connect a device or start an emulator**
2. **Run the app:**
   ```bash
   flutter run
   ```

## Project Overview

### 📁 Clean Architecture Layers

```
┌─────────────────────────────────────┐
│      Presentation Layer             │
│  (UI, Bloc, Screens, Widgets)       │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│       Domain Layer                  │
│  (Entities, Use Cases, Repositories)│
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│        Data Layer                   │
│  (Models, Data Sources, Repo Impl)  │
└─────────────────────────────────────┘
```

### 🎯 Main Features

1. **Home Screen** (`lib/features/quran/presentation/screens/home_screen.dart`)
   - Lists all 114 Surahs
   - Shows Arabic and English names
   - Displays number of Ayahs

2. **Surah Detail Screen** (`lib/features/quran/presentation/screens/surah_detail_screen.dart`)
   - Beautiful gradient header
   - Bismillah display
   - All Ayahs with Arabic text
   - Metadata (Juz, Page, Sajda)

### 🔌 API Integration

**Base URL:** `https://api.alquran.cloud/v1`

**Endpoints Used:**
- `/surah` - List all Surahs
- `/surah/{number}/{edition}` - Get Surah details with Ayahs

### 🎨 Customization Points

**Colors** → `lib/core/constants/app_colors.dart`
**Theme** → `lib/core/theme/app_theme.dart`
**API Config** → `lib/core/constants/api_constants.dart`

### 📦 Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_bloc` | State management |
| `get_it` | Dependency injection |
| `http` | API calls |
| `dartz` | Functional programming |
| `equatable` | Value equality |
| `google_fonts` | Beautiful typography |

### 🔥 Key Commands

```bash
# Install dependencies
flutter pub get

# Run app
flutter run

# Analyze code
flutter analyze

# Format code
dart format .

# Clean build
flutter clean
```

### 🏗️ Adding New Features

1. **Create Entity** in `domain/entities/`
2. **Create Use Case** in `domain/usecases/`
3. **Create Bloc** in `presentation/bloc/`
4. **Create Screen** in `presentation/screens/`
5. **Register in DI** in `core/di/injection_container.dart`

### 📱 Screens Flow

```
HomeScreen (Surah List)
    │
    ├─ Tap on Surah
    │
    └─> SurahDetailScreen (Ayahs List)
```

### 🧪 Testing (To Implement)

```dart
// Unit Test Example
test('should get all surahs from repository', () async {
  // Arrange
  when(mockRepository.getAllSurahs())
      .thenAnswer((_) async => Right(tSurahList));
  
  // Act
  final result = await usecase(NoParams());
  
  // Assert
  expect(result, Right(tSurahList));
});
```

### 🐛 Troubleshooting

**Issue:** App won't start
- Run `flutter clean && flutter pub get`
- Check device/emulator is connected

**Issue:** Network error
- Check internet connection
- Verify API endpoint in `api_constants.dart`

**Issue:** Dependency injection error
- Check `injection_container.dart` registration order
- Ensure all dependencies are registered

### 📚 Learn More

- [Flutter Bloc Documentation](https://bloclibrary.dev/)
- [Clean Architecture Guide](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [AlQuran Cloud API](https://alquran.cloud/api)

---

## Next Steps

- [ ] Add search functionality
- [ ] Implement bookmarks
- [ ] Add audio recitation
- [ ] Support multiple translations
- [ ] Implement offline mode
- [ ] Add dark theme
- [ ] Prayer times integration

**May this app be beneficial for the Ummah! 🤲**
