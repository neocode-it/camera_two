import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'navigation_state.dart';

class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit() : super(NavigationCamera());

  void launchCamera() {
    emit(NavigationCamera());
  }

  void launchGallery() {
    emit(NavigationGallery());
  }
}
