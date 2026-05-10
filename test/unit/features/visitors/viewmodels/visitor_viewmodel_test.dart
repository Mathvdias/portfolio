import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/core/result/result.dart';
import 'package:portifolio/features/visitors/domain/repositories/visitor_repository.dart';
import 'package:portifolio/features/visitors/presentation/viewmodels/visitor_viewmodel.dart';

class _FakeVisitorRepository implements VisitorRepository {
  final _controller = StreamController<int>.broadcast();
  bool recordCalled = false;

  void emit(int count) => _controller.add(count);

  @override
  Future<Result<void>> recordVisit() async {
    recordCalled = true;
    return const Success(null);
  }

  @override
  Stream<int> watchVisitorCount() => _controller.stream;

  void dispose() => _controller.close();
}

void main() {
  group('VisitorViewModel', () {
    late _FakeVisitorRepository repo;
    late VisitorViewModel vm;

    setUp(() {
      repo = _FakeVisitorRepository();
      vm = VisitorViewModel(repo);
    });

    tearDown(() {
      vm.dispose();
      repo.dispose();
    });

    test('starts with count 0', () {
      expect(vm.count, 0);
    });

    test('init calls recordVisit', () async {
      vm.init();
      await Future<void>.delayed(Duration.zero);
      expect(repo.recordCalled, isTrue);
    });

    test('updates count when stream emits', () async {
      vm.init();
      var notified = false;
      vm.addListener(() => notified = true);

      repo.emit(42);
      await Future<void>.delayed(Duration.zero);

      expect(vm.count, 42);
      expect(notified, isTrue);
    });

    test('updates count multiple times', () async {
      vm.init();
      repo.emit(10);
      await Future<void>.delayed(Duration.zero);
      repo.emit(11);
      await Future<void>.delayed(Duration.zero);
      expect(vm.count, 11);
    });
  });
}
