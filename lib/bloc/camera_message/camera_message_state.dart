part of 'camera_message_cubit.dart';

@immutable
abstract class CameraMessageState {}

class NoCameraMessage extends CameraMessageState {}

class NewCameraMessage extends CameraMessageState {
  final CameraMessage message;
  NewCameraMessage(this.message);
}
