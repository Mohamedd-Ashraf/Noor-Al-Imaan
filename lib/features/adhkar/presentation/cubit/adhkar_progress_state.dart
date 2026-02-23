import 'package:equatable/equatable.dart';

class AdhkarProgressState extends Equatable {
  /// categoryId → { itemId → count }
  final Map<String, Map<String, int>> counters;

  const AdhkarProgressState({required this.counters});

  const AdhkarProgressState.empty() : counters = const {};

  /// Return the counter for a specific item.
  int countFor(String categoryId, String itemId) =>
      counters[categoryId]?[itemId] ?? 0;

  /// Return the counters map for a single category.
  Map<String, int> categoryCounters(String categoryId) =>
      counters[categoryId] ?? const {};

  AdhkarProgressState copyWithCategory(
      String categoryId, Map<String, int> updated) {
    return AdhkarProgressState(
      counters: {
        ...counters,
        categoryId: Map<String, int>.from(updated),
      },
    );
  }

  @override
  List<Object?> get props => [counters];
}
