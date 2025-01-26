part of 'selection_cubit.dart';

@immutable
abstract class SelectionState {
  const SelectionState(this.indexes);
  final List<int> indexes;
}

class SelectionInactive extends SelectionState {
  SelectionInactive() : super([]);
}

class SelectionActive extends SelectionState {
  const SelectionActive(super.indexes);
}
