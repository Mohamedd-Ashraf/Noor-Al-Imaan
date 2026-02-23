import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/adhkar_data.dart';
import '../../data/adhkar_progress_service.dart';
import 'adhkar_progress_state.dart';

class AdhkarProgressCubit extends Cubit<AdhkarProgressState>
    with WidgetsBindingObserver {
  final AdhkarProgressService _service;

  AdhkarProgressCubit(this._service)
      : super(const AdhkarProgressState.empty()) {
    WidgetsBinding.instance.addObserver(this);
  }

  // ── App lifecycle ──────────────────────────────────────────────────────────

  /// Re-checks date & resets when the app comes back to the foreground,
  /// covering the edge-case where the app was open across midnight.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      load();
    }
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    return super.close();
  }

  // ── Bootstrap ──────────────────────────────────────────────────────────────

  /// Load all persisted progress. Called at startup and on each app resume.
  /// Daily reset is handled automatically inside the service.
  void load() {
    final categoryIds =
        AdhkarData.categories.map((c) => c.id).toList();
    final counters = _service.loadAll(categoryIds);
    emit(AdhkarProgressState(counters: counters));
  }

  // ── Counter operations ─────────────────────────────────────────────────────

  /// Increment the counter for [itemId] in [categoryId] up to [maxCount].
  Future<void> increment(
      String categoryId, String itemId, int maxCount) async {
    final current = state.countFor(categoryId, itemId);
    if (current >= maxCount) return;

    final updated = {
      ...state.categoryCounters(categoryId),
      itemId: current + 1,
    };
    final newState = state.copyWithCategory(categoryId, updated);
    emit(newState);
    await _service.saveCategory(categoryId, updated);
  }

  /// Reset the counter for a single item to zero.
  Future<void> resetItem(String categoryId, String itemId) async {
    final updated = Map<String, int>.from(state.categoryCounters(categoryId))
      ..remove(itemId);
    final newState = state.copyWithCategory(categoryId, updated);
    emit(newState);
    await _service.saveCategory(categoryId, updated);
  }

  /// Reset all counters for a single category.
  Future<void> resetCategory(String categoryId) async {
    final newState = state.copyWithCategory(categoryId, {});
    emit(newState);
    await _service.saveCategory(categoryId, {});
  }

  /// Reset every category (useful for manual full-reset from UI).
  Future<void> resetAll() async {
    final categoryIds =
        AdhkarData.categories.map((c) => c.id).toList();
    await _service.resetAll(categoryIds);
    load();
  }
}
