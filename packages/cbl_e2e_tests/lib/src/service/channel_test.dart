// ignore: lines_longer_than_80_chars
// ignore_for_file: avoid_types_on_closure_parameters,prefer_constructors_over_static_methods,prefer_void_to_null

import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cbl/src/bindings.dart';
import 'package:cbl/src/service/channel.dart';
import 'package:cbl/src/support/isolate.dart';
import 'package:meta/meta.dart';
import 'package:stream_channel/isolate_channel.dart';
import 'package:stream_channel/stream_channel.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';
import '../utils/test_variant.dart';

void main() {
  setupTestBinding();

  group('Channel', () {
    channelTest('call with normal return', () async {
      final channel = await openTestChannel();

      expect(channel.call(EchoRequest('Hello')), completion('Input: Hello'));
    });

    channelTest('call with exceptional return', () async {
      final channel = await openTestChannel();

      expect(channel.call(ThrowTestError()), throwsA(const TestError('Oops')));
    });

    channelTest('call with data in request and response', () async {
      final channel = await openTestChannel();

      Future<void> expectData(Data input, Object output) => expectLater(
        channel
            .call(DataRequest(SendableData(input)))
            .then((value) => value.data.toTypedList()),
        completion(output),
      );
      final input = Uint8List.fromList([0, 1]).toData();

      // Send Dart typed data
      await expectData(input, [42, 1]);

      // Send `SliceResult`
      await expectData(input.toSliceResult().toData(), [42, 1]);
    });

    channelTest('call non-existent endpoint', () async {
      final channel = await openTestChannel();

      expect(
        channel.call(NonExistentEndpoint()),
        throwsA(
          isA<UnimplementedError>().having(
            (it) => it.message,
            'message',
            'No call handler registered for endpoint: NonExistentEndpoint',
          ),
        ),
      );
    });

    channelTest('stream emits event', () async {
      final channel = await openTestChannel();

      expect(
        channel.stream(EchoRequest('Hello')),
        emitsInOrder(<Object>['Input: Hello', emitsDone]),
      );
    });

    channelTest('stream emits error', () async {
      final channel = await openTestChannel();

      expect(
        channel.stream(ThrowTestError()),
        emitsInOrder(<Object>[emitsError(const TestError('Oops')), emitsDone]),
      );
    });

    channelTest('close infinite stream', () async {
      final channel = await openTestChannel();

      expect(channel.stream(InfiniteStream()), emits(null));
    });

    channelTest('list to stream of non-existente endpoint', () async {
      final channel = await openTestChannel();

      expect(
        channel.stream(NonExistentEndpoint()),
        emitsInOrder(<Object>[
          emitsError(
            isA<UnsupportedError>().having(
              (it) => it.message,
              'message',
              'No stream handler registered for endpoint: NonExistentEndpoint',
            ),
          ),
          emitsDone,
        ]),
      );
    });

    channelTest('pause and resume stream', () async {
      final channel = await openTestChannel();

      var isPaused = false;
      var events = 0;
      final sub = channel.stream(InfiniteStream()).listen((event) {
        expect(isPaused, isFalse);
        events++;
      });

      // Verify that the stream is emitting events.
      while (events <= 0) {
        await Future<void>.delayed(InfiniteStream.interval);
      }

      // Pause the stream.
      sub.pause();
      await Future<void>.delayed(InfiniteStream.interval * 2);
      isPaused = true;

      // Wait a view intervals while stream is paused to verify that the stream
      // is paused.
      await Future<void>.delayed(InfiniteStream.interval * 10);

      // Resume the stream
      isPaused = false;
      events = 0;
      sub.resume();

      // Verify that the stream is emitting events again.
      while (events <= 0) {
        await Future<void>.delayed(InfiniteStream.interval);
      }

      await sub.cancel();
    });
  });
}

@isTest
void channelTest(String description, Future Function() body) {
  variantTest(description, body, variants: [channelTransport]);
}

enum ChannelTransport { isolatePort, controller }

final channelTransport = EnumVariant<ChannelTransport>(
  ChannelTransport.values,
  order: 100,
);

Future<Channel> openTestChannel() async {
  StreamChannel<Object?> localTransport;

  switch (channelTransport.value) {
    case ChannelTransport.controller:
      final controller = StreamChannelController<Object?>();
      localTransport = controller.local;
      final remote = Channel(transport: controller.foreign);
      addTearDown(remote.close);
      registerTestHandlers(remote);
    case ChannelTransport.isolatePort:
      final receivePort = ReceivePort();
      localTransport = IsolateChannel.connectReceive(receivePort);
      final isolate = await Isolate.spawn(
        testIsolateMain,
        TestIsolateConfig(IsolateContext.instance, receivePort.sendPort),
      );
      addTearDown(isolate.kill);
  }

  final local = Channel(transport: localTransport);
  addTearDown(local.close);

  return local;
}

void registerTestHandlers(Channel channel) {
  channel
    ..addCallEndpoint((EchoRequest req) => 'Input: ${req.input}')
    ..addCallEndpoint((DataRequest req) {
      final result = req.input.data.toTypedList();
      result[0] = 42;
      return SendableData(result.toData());
    })
    ..addCallEndpoint(
      (ThrowTestError _) =>
          Future<void>.error(const TestError('Oops'), StackTrace.current),
    )
    ..addStreamEndpoint(
      (EchoRequest req) => Stream.value('Input: ${req.input}'),
    )
    ..addStreamEndpoint(
      (ThrowTestError _) =>
          Stream<void>.error(const TestError('Oops'), StackTrace.current),
    )
    ..addStreamEndpoint(
      (InfiniteStream _) => Stream<void>.periodic(InfiniteStream.interval),
    );
}

class TestIsolateConfig {
  TestIsolateConfig(this.context, this.sendPort);

  final IsolateContext context;
  final SendPort? sendPort;
}

void testIsolateMain(TestIsolateConfig config) {
  initSecondaryIsolate(config.context);

  final remote = Channel(
    transport: IsolateChannel.connectSend(config.sendPort!),
    autoOpen: false,
  );

  registerTestHandlers(remote);

  remote.open();
}

final class EchoRequest extends Request<String> {
  EchoRequest(this.input);

  final String input;
}

final class DataRequest extends Request<SendableData> implements SendAware {
  DataRequest(this.input);

  final SendableData input;

  @override
  void willSend() => input.willSend();

  @override
  void didReceive() => input.didReceive();
}

final class SendableData implements SendAware {
  SendableData(Data data) : _data = data;

  Data get data => _data!;
  Data? _data;

  TransferableData? _transferableData;

  @override
  void willSend() {
    _transferableData = TransferableData(_data!);
    _data = null;
  }

  @override
  void didReceive() {
    _data = _transferableData!.materialize();
    _transferableData = null;
  }
}

final class ThrowTestError extends Request<Null> {}

final class InfiniteStream extends Request<Null> {
  static const interval = Duration(milliseconds: 10);
}

final class NonExistentEndpoint extends Request<Null> {}

@immutable
final class TestError implements Exception {
  const TestError(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'TestError: $message';
}
