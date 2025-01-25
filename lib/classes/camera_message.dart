class CameraMessage {
  CameraMessage(this.message);
  final String message;
  bool _valid = true;

  void invalidate() {
    _valid = false;
  }

  isValid() {
    return _valid;
  }
}
