# Development Guide

## How to Add New Features

### Adding a New Use Case

1. **Create Entity** (if needed) in `lib/features/quran/domain/entities/`
2. **Update Repository Interface** in `lib/features/quran/domain/repositories/`
3. **Create Use Case** in `lib/features/quran/domain/usecases/`
4. **Create Model** in `lib/features/quran/data/models/`
5. **Update Data Source** in `lib/features/quran/data/datasources/`
6. **Update Repository Implementation** in `lib/features/quran/data/repositories/`
7. **Register in DI** in `lib/core/di/injection_container.dart`

### Example: Adding Search Feature

1. Create `SearchParams` and `SearchResults` entities
2. Add `search()` method to `QuranRepository`
3. Create `SearchQuran` use case
4. Create `SearchResultModel`
5. Add search endpoint to `QuranRemoteDataSource`
6. Implement in `QuranRepositoryImpl`
7. Create `SearchBloc` with events and states
8. Register bloc in injection container
9. Create UI screen for search

## Code Style

### Naming Conventions
- **Files**: `snake_case.dart`
- **Classes**: `PascalCase`
- **Variables/Functions**: `camelCase`
- **Constants**: `SCREAMING_SNAKE_CASE`
- **Private members**: `_prefixedWithUnderscore`

### Bloc Pattern
```dart
// Event
class GetDataEvent extends DataEvent {
  final String param;
  const GetDataEvent(this.param);
}

// State
class DataLoaded extends DataState {
  final Data data;
  const DataLoaded(this.data);
}

// Bloc
class DataBloc extends Bloc<DataEvent, DataState> {
  final GetData getData;
  
  DataBloc({required this.getData}) : super(DataInitial()) {
    on<GetDataEvent>(_onGetData);
  }
  
  Future<void> _onGetData(
    GetDataEvent event,
    Emitter<DataState> emit,
  ) async {
    emit(DataLoading());
    final result = await getData(Params(event.param));
    result.fold(
      (failure) => emit(DataError(failure.message)),
      (data) => emit(DataLoaded(data)),
    );
  }
}
```

## Testing

### Unit Tests
```dart
// Test Use Cases
test('should get data from repository', () async {
  // Arrange
  when(mockRepository.getData()).thenAnswer((_) async => Right(tData));
  
  // Act
  final result = await usecase(NoParams());
  
  // Assert
  expect(result, Right(tData));
  verify(mockRepository.getData());
});
```

### Widget Tests
```dart
testWidgets('should display loading indicator', (tester) async {
  // Arrange
  when(mockBloc.stream).thenAnswer((_) => Stream.value(DataLoading()));
  
  // Act
  await tester.pumpWidget(makeTestableWidget(DataScreen()));
  
  // Assert
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

## Common Issues & Solutions

### Issue: Bloc not updating UI
**Solution**: Ensure you're using `BlocBuilder` or `BlocListener` and that states are properly equatable.

### Issue: Network errors
**Solution**: Check internet connection using `NetworkInfo` before API calls.

### Issue: Dependency injection errors
**Solution**: Make sure all dependencies are registered in `injection_container.dart` in the correct order.

## Performance Tips

1. **Use const constructors** wherever possible
2. **Implement Equatable** for all entities, models, events, and states
3. **Avoid rebuilding widgets** unnecessarily by using `const` widgets
4. **Cache network responses** for offline support
5. **Use ListView.builder** for long lists

## Git Workflow

1. Create feature branch: `git checkout -b feature/feature-name`
2. Make changes and commit: `git commit -m "Add feature"`
3. Push to remote: `git push origin feature/feature-name`
4. Create Pull Request
5. Code review and merge

## Useful Commands

```bash
# Run app
flutter run

# Run tests
flutter test

# Generate code coverage
flutter test --coverage

# Analyze code
flutter analyze

# Format code
dart format .

# Clean build
flutter clean && flutter pub get

# Build APK
flutter build apk --release

# Build iOS
flutter build ios --release
```

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Bloc Documentation](https://bloclibrary.dev/)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [AlQuran.cloud API Docs](https://alquran.cloud/api)
