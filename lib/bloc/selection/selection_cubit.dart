import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'selection_state.dart';

class SelectionCubit extends Cubit<SelectionState> {
  SelectionCubit() : super(SelectionInactive());
  void unselectItem(index) {
    final newSelectedIndices = List<int>.from(state.indexes)..remove(index);

    if (newSelectedIndices.isEmpty) {
      emit(SelectionInactive());
    } else {
      emit(SelectionActive(newSelectedIndices));
    }
  }

  void selectItem(index) {
    if (state.indexes.contains(index)) {
      return;
    }

    final newSelectedIndices = List<int>.from(state.indexes)..add(index);
    emit(SelectionActive(newSelectedIndices));
  }

  void toggleSelection(index) {
    if (state.indexes.contains(index)) {
      unselectItem(index);
    } else {
      selectItem(index);
    }
  }

  void cancalSelection() {
    emit(SelectionInactive());
  }
}
