import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_ayah.dart';
import 'ayah_event.dart';
import 'ayah_state.dart';

class AyahBloc extends Bloc<AyahEvent, AyahState> {
  final GetAyah getAyah;

  AyahBloc({
    required this.getAyah,
  }) : super(AyahInitial()) {
    on<GetAyahDetailEvent>(_onGetAyahDetail);
  }

  Future<void> _onGetAyahDetail(
    GetAyahDetailEvent event,
    Emitter<AyahState> emit,
  ) async {
    emit(AyahLoading());
    final result = await getAyah(
      GetAyahParams(reference: event.reference, edition: event.edition),
    );
    result.fold(
      (failure) => emit(AyahError(failure.message)),
      (ayah) => emit(AyahLoaded(ayah)),
    );
  }
}
