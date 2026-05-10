import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/repositories/visitor_repository.dart';

class VisitorViewModel extends ChangeNotifier {
  VisitorViewModel(this._repository);

  final VisitorRepository _repository;
  StreamSubscription<int>? _sub;

  int _count = 0;
  int get count => _count;

  void init() {
    _repository.recordVisit();
    _sub = _repository.watchVisitorCount().listen((count) {
      _count = count;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
