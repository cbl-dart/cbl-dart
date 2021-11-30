// ignore_for_file: close_sinks

import 'dart:async';

import 'package:cbl/src/support/listener_token.dart';
import 'package:cbl/src/support/resource.dart';
import 'package:cbl/src/support/streams.dart';
import 'package:test/test.dart';

void main() {
  group('ResourceStream', () {
    test('behaves like normal stream', () {
      expect(
        ResourceStream(
          parent: TestResource(),
          stream: Stream.fromIterable([0, 1, 2]),
        ),
        emitsInOrder(<Object>[0, 1, 2, emitsDone]),
      );
    });

    test('closes resource when stream ends', () async {
      final stream = ResourceStream(
        parent: TestResource(),
        stream: const Stream<void>.empty(),
      );
      expect(stream.isClosed, isFalse);
      await stream.toList();
      expect(stream.isClosed, isTrue);
    });

    test('closes resource when subscription is canceled', () async {
      final stream = ResourceStream(
        parent: TestResource(),
        stream: nullSteam(),
      );
      expect(stream.isClosed, isFalse);
      final sub = stream.listen(null);
      expect(stream.isClosed, isFalse);
      await sub.cancel();
      expect(stream.isClosed, isTrue);
    });

    test('throws when parent is closed when being listened to', () async {
      final parent = TestResource();
      final stream = ResourceStream(parent: parent, stream: nullSteam());
      await parent.close();
      expect(() => stream.listen(null), throwsStateError);
    });

    test('cleans up stream when resources is closed', () async {
      final controller = StreamController<void>(onCancel: expectAsync0(() {}));
      final stream = ResourceStream(
        parent: TestResource(),
        stream: controller.stream,
      )..listen(null, onDone: expectAsync0(() {}));
      await stream.close();
    });

    group('blocking', () {
      test('returns from finalizer when stream ends', () async {
        final controller = StreamController<void>();
        final stream = ResourceStream(
          parent: TestResource(),
          stream: controller.stream,
          blocking: true,
        )..listen(null);

        var finishedClosing = false;
        // ignore: unawaited_futures
        stream.close().then(expectAsync1((_) => finishedClosing = true));

        await Future(() async {
          expect(finishedClosing, isFalse);
          await controller.close();
        });
      });

      test('return from finalizer when subscription in canceled', () async {
        final controller = StreamController<void>();
        final stream = ResourceStream(
          parent: TestResource(),
          stream: controller.stream,
          blocking: true,
        );
        final sub = stream.listen(null);

        var finishedClosing = false;
        // ignore: unawaited_futures
        stream.close().then(expectAsync1((_) => finishedClosing = true));

        await Future(() async {
          expect(finishedClosing, isFalse);
          await sub.cancel();
        });
      });
    });
  });

  group('ListenerStream', () {
    test('resolves listening future when addListener future resolves',
        () async {
      final addListenerCompleter = Completer<AbstractListenerToken>();
      final stream = ListenerStream(
        parent: TestResource(),
        addListener: (_) => addListenerCompleter.future,
      );

      expect(stream.listening, completes);

      stream.listen(null);
      addListenerCompleter.complete(TestToken());
    });

    test('closes down stream when addListener future rejects', () async {
      final addListenerCompleter = Completer<AbstractListenerToken>();
      final stream = ListenerStream(
        parent: TestResource(),
        addListener: (_) => addListenerCompleter.future,
      );

      expect(stream.listening, throwsStateError);
      expect(
        stream,
        emitsInOrder(<Object>[
          emitsError(isA<StateError>()),
          emitsDone,
        ]),
      );

      addListenerCompleter.completeError(StateError(''));
    });

    test('emits event when listener is called', () async {
      late void Function(String) listener;
      final addListenerCompleter = Completer<AbstractListenerToken>();
      final stream = ListenerStream<String>(
        parent: TestResource(),
        addListener: (it) {
          listener = it;
          return addListenerCompleter.future;
        },
      );

      expect(stream, emits('A'));

      addListenerCompleter.complete(TestToken());
      listener('A');
    });

    test('immediately ignores listener events once canceled', () {
      late void Function(String) listener;
      final addListenerCompleter = Completer<AbstractListenerToken>();
      final stream = ListenerStream<String>(
        parent: TestResource(),
        addListener: (it) {
          listener = it;
          return addListenerCompleter.future;
        },
      );

      final sub = stream.listen(expectAsync1((_) {}, count: 0));

      addListenerCompleter.complete(TestToken());

      sub.cancel();

      listener('A');
    });

    test('removes listener when being canceled', () async {
      final token = TestToken();
      final addListenerCompleter = Completer<AbstractListenerToken>();
      final stream = ListenerStream<String>(
        parent: TestResource(),
        addListener: (it) => addListenerCompleter.future,
      );

      final sub = stream.listen(null);

      addListenerCompleter.complete(token);

      await sub.cancel();

      expect(token.isRemoved, isTrue);
    });
  });

  group('RepeatableStream', () {
    test('sends events to parallel subscribers', () async {
      final stream = RepeatableStream(Stream.value('A'));
      expect(stream, emitsInOrder(<Object>['A', emitsDone]));
      expect(stream, emitsInOrder(<Object>['A', emitsDone]));
    });

    test('replay error to parallel subscribers', () async {
      final stream = RepeatableStream(Stream<void>.error('A'));
      expect(stream, emitsInOrder(<Object>[emitsError('A'), emitsDone]));
      expect(stream, emitsInOrder(<Object>[emitsError('A'), emitsDone]));
    });

    test('replay done to parallel subscriber', () async {
      final stream = RepeatableStream(const Stream<void>.empty());
      expect(stream, emitsInOrder(<Object>[emitsDone]));
      expect(stream, emitsInOrder(<Object>[emitsDone]));
    });

    test('replay events to late subscribers', () async {
      final stream = RepeatableStream(Stream.value('A'));
      await expectLater(
        stream,
        emitsInOrder(<Object>['A', emitsDone]),
      );
      await expectLater(
        stream,
        emitsInOrder(<Object>['A', emitsDone]),
      );
    });

    test('replay error to late subscribers', () async {
      final stream = RepeatableStream(Stream<void>.error('A'));
      await expectLater(
        stream,
        emitsInOrder(<Object>[emitsError('A'), emitsDone]),
      );
      await expectLater(
        stream,
        emitsInOrder(<Object>[emitsError('A'), emitsDone]),
      );
    });

    test('replay done to late subscriber', () async {
      final stream = RepeatableStream(const Stream<void>.empty());
      await expectLater(
        stream,
        emitsInOrder(<Object>[emitsDone]),
      );
      await expectLater(
        stream,
        emitsInOrder(<Object>[emitsDone]),
      );
    });
  });
}

Stream<void> nullSteam() => StreamController<void>().stream;

class TestResource with ClosableResourceMixin {}

class TestToken extends AbstractListenerToken {}
