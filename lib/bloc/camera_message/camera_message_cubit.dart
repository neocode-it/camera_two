import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import 'package:outtake/classes/camera_message.dart';

part 'camera_message_state.dart';

class CameraMessageCubit extends Cubit<CameraMessageState> {
  CameraMessageCubit() : super(NoCameraMessage());

  Future<void> newMessage(String message, {int? timeout_ms}) async {
    CameraMessage msg = CameraMessage(message);
    emit(NewCameraMessage(msg));
    await Future.delayed(Duration(milliseconds: timeout_ms ?? 1000));
    msg.invalidate();
    emit(NoCameraMessage());
  }
}
