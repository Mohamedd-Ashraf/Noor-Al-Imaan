# Quran App - القرآن الكريم

A beautiful and feature-rich Quran application built with Flutter using Clean Architecture and Bloc state management.

## Features

- 📖 Browse all 114 Surahs of the Holy Quran
- 🔍 View detailed Surah information with all Ayahs
- 🌐 Online Quran text from AlQuran.cloud API
- 🎨 Beautiful and intuitive UI design
- 🏗️ Clean Architecture for maintainable codebase
- 🔄 Bloc state management for predictable state handling
- 🌍 Multi-language support ready
- 📱 Responsive design for all screen sizes

## Architecture

This app follows **Clean Architecture** principles with three main layers:

### 1. **Presentation Layer** (`lib/features/quran/presentation/`)
- **Bloc**: State management using flutter_bloc
  - `SurahBloc`: Handles Surah list and detail states
  - `AyahBloc`: Manages individual Ayah data
- **Screens**: UI components
  - `HomeScreen`: Displays list of all Surahs
  - `SurahDetailScreen`: Shows detailed view of a Surah with all Ayahs
- **Widgets**: Reusable UI components

### 2. **Domain Layer** (`lib/features/quran/domain/`)
- **Entities**: Core business objects
  - `Surah`: Represents a Surah with its properties
  - `Ayah`: Represents a verse (Ayah)
  - `Juz`: Represents a Juz section
- **Repositories**: Abstract definitions for data operations
- **Use Cases**: Business logic encapsulation
  - `GetAllSurahs`: Fetches list of all Surahs
  - `GetSurah`: Fetches a specific Surah with Ayahs
  - `GetAyah`: Fetches a specific Ayah
  - `GetJuz`: Fetches a specific Juz

### 3. **Data Layer** (`lib/features/quran/data/`)
- **Models**: Data transfer objects that extend entities
- **Data Sources**:
  - `QuranRemoteDataSource`: API communication
- **Repositories**: Concrete implementations of domain repositories

### Core (`lib/core/`)
- **Dependency Injection**: GetIt service locator
- **Error Handling**: Custom exceptions and failures
- **Network**: Internet connectivity checking
- **Theme**: App-wide theming
- **Constants**: API endpoints and app constants

## Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── api_constants.dart
│   │   └── app_colors.dart
│   ├── di/
│   │   └── injection_container.dart
│   ├── error/
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── network/
│   │   └── network_info.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── usecases/
│       └── usecase.dart
├── features/
│   └── quran/
│       ├── data/
│       │   ├── datasources/
│       │   │   └── quran_remote_data_source.dart
│       │   ├── models/
│       │   │   ├── surah_model.dart
│       │   │   └── juz_model.dart
│       │   └── repositories/
│       │       └── quran_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── surah.dart
│       │   │   └── juz.dart
│       │   ├── repositories/
│       │   │   └── quran_repository.dart
│       │   └── usecases/
│       │       ├── get_all_surahs.dart
│       │       ├── get_surah.dart
│       │       ├── get_ayah.dart
│       │       └── get_juz.dart
│       └── presentation/
│           ├── bloc/
│           │   ├── surah/
│           │   │   ├── surah_bloc.dart
│           │   │   ├── surah_event.dart
│           │   │   └── surah_state.dart
│           │   └── ayah/
│           │       ├── ayah_bloc.dart
│           │       ├── ayah_event.dart
│           │       └── ayah_state.dart
│           └── screens/
│               ├── home_screen.dart
│               └── surah_detail_screen.dart
└── main.dart
```

## Dependencies

- **flutter_bloc**: ^8.1.6 - State management
- **equatable**: ^2.0.5 - Value equality
- **dartz**: ^0.10.1 - Functional programming (Either type)
- **http**: ^1.2.1 - HTTP requests
- **get_it**: ^7.7.0 - Service locator for dependency injection
- **internet_connection_checker**: ^1.0.0+1 - Network connectivity
- **shared_preferences**: ^2.2.3 - Local storage
- **google_fonts**: ^6.2.1 - Beautiful fonts
- **flutter_svg**: ^2.0.10+1 - SVG support

## Getting Started

### Prerequisites

- Flutter SDK (3.10.4 or higher)
- Dart SDK
- Android Studio / VS Code
- Android/iOS emulator or physical device

### Installation

1. Clone the repository:
```bash
git clone <your-repo-url>
cd quraan
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Adhan reminders (sound + testing)

This app can schedule prayer-time reminders using local notifications.

### Quick test (no need to wait for prayer time)

- Open Settings → Prayer Notifications
- Use:
  - “Test now” (immediate)
  - “Test in 10s” (schedule, then try closing the app)

### Custom Adhan sound (optional)

Important: only use audio you have the rights to use.

Android:
- Add a file named exactly `adhan.mp3` into `android/app/src/main/res/raw/`
- In-app: Settings → Prayer Notifications → enable “Custom Adhan Sound”
- Press “Reset channels” (Android notification channel settings are cached by the OS)

iOS:
- Add a short notification sound file named `adhan.caf` to the Runner app bundle
- Enable “Custom Adhan Sound”

Notes:
- Android notification channel sound can be turned off by the user in system settings; the app cannot force it back on.
- Some Android OEMs aggressively kill alarms/notifications; if reminders don’t fire reliably, users may need to whitelist the app from battery optimizations.

## API Integration

This app uses the [AlQuran.cloud API](https://alquran.cloud/api) to fetch Quran data.

**Base URL**: `https://api.alquran.cloud/v1`

### Available Endpoints:
- `GET /surah` - Get list of all Surahs
- `GET /surah/{number}/{edition}` - Get specific Surah with Ayahs
- `GET /ayah/{reference}/{edition}` - Get specific Ayah
- `GET /juz/{number}/{edition}` - Get specific Juz

## State Management Flow

```
User Action → Event → Bloc → Use Case → Repository → Data Source → API
                                                                     ↓
User sees UI ← Widget ← State ← Bloc ← Either<Failure, Data> ← Response
```

## Key Features Implementation

### 1. **Surah List**
- Displays all 114 Surahs with Arabic and English names
- Shows number of Ayahs and revelation type
- Clean card-based UI with tap navigation

### 2. **Surah Detail**
- Beautiful header with gradient background
- Bismillah display (except for Surah 1 and 9)
- All Ayahs with Arabic text
- Metadata chips showing Juz, Page, and Sajda information

### 3. **Error Handling**
- Network error detection
- User-friendly error messages
- Retry functionality

### 4. **Offline Support Ready**
- Architecture supports local caching
- Network connectivity checking in place

## Customization

### Colors
Edit `lib/core/constants/app_colors.dart` to change the app's color scheme.

### Theme
Modify `lib/core/theme/app_theme.dart` to customize fonts, button styles, and more.

### API Edition
Change the default Quran edition in `lib/core/constants/api_constants.dart`:
- `defaultEdition`: Default Arabic text edition
- `defaultTranslation`: Default translation edition

## Future Enhancements

- [ ] Search functionality
- [ ] Bookmarking favorite Ayahs
- [ ] Audio recitation playback
- [ ] Multiple translations
- [ ] Offline mode with local database
- [ ] Prayer times integration
- [ ] Tafsir (interpretation) support
- [ ] Dark mode
- [ ] Reading progress tracking
- [ ] Share Ayahs functionality

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.

## Acknowledgments

- [AlQuran.cloud](https://alquran.cloud/) for providing the free Quran API
- Flutter team for the amazing framework
- All contributors and testers

## Contact

For questions or support, please open an issue in the repository.

---

**May Allah accept this work and make it beneficial for the Ummah. Ameen.**

بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ
