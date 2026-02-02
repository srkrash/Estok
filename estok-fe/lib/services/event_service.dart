import 'dart:async';

class EventService {
  static final EventService _instance = EventService._internal();

  factory EventService() {
    return _instance;
  }

  EventService._internal();

  final _productUpdateController = StreamController<void>.broadcast();

  Stream<void> get productUpdatedStream => _productUpdateController.stream;

  void notifyProductUpdate() {
    _productUpdateController.add(null);
  }

  void dispose() {
    _productUpdateController.close();
  }
}
