// ignore: lines_longer_than_80_chars
// ignore_for_file: avoid_types_on_closure_parameters,prefer_constructors_over_static_methods,prefer_void_to_null

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cbl/src/bindings.dart';
import 'package:cbl/src/service/channel.dart';
import 'package:cbl/src/service/serialization/isolate_packet_codec.dart';
import 'package:cbl/src/service/serialization/json_packet_codec.dart';
import 'package:cbl/src/service/serialization/serialization.dart';
import 'package:cbl/src/service/serialization/serialization_codec.dart';
import 'package:cbl/src/support/isolate.dart';
import 'package:cbl/src/support/utils.dart';
import 'package:meta/meta.dart';
import 'package:stream_channel/isolate_channel.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/io.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';
import '../utils/test_variant.dart';

void main() {
  setupTestBinding();

  group('Channel', () {
    channelTest('call with normal return', () async {
      final channel = await openTestChannel();

      expect(
        channel.call(EchoRequest('Hello')),
        completion('Input: Hello'),
      );
    });

    channelTest('call with exceptional return', () async {
      final channel = await openTestChannel();

      expect(
        channel.call(ThrowTestError()),
        throwsA(const TestError('Oops')),
      );
    });

    channelTest('call with data in request and response', () async {
      final channel = await openTestChannel();

      Future<void> expectData(Data input, Object output) => expectLater(
            channel
                .call(DataRequest(MessageData(input)))
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
        throwsA(isA<UnimplementedError>().having(
          (it) => it.message,
          'message',
          'No call handler registered for endpoint: NonExistentEndpoint',
        )),
      );
    });

    channelTest('stream emits event', () async {
      final channel = await openTestChannel();

      expect(
        channel.stream(EchoRequest('Hello')),
        emitsInOrder(<Object>[
          'Input: Hello',
          emitsDone,
        ]),
      );
    });

    channelTest('stream emits error', () async {
      final channel = await openTestChannel();

      expect(
        channel.stream(ThrowTestError()),
        emitsInOrder(<Object>[
          emitsError(const TestError('Oops')),
          emitsDone,
        ]),
      );
    });

    channelTest('close infinite stream', () async {
      final channel = await openTestChannel();

      expect(
        channel.stream(InfiniteStream()),
        emits(null),
      );
    });

    channelTest('list to stream of non-existente endpoint', () async {
      final channel = await openTestChannel();

      expect(
        channel.stream(NonExistentEndpoint()),
        emitsInOrder(<Object>[
          emitsError(isA<UnsupportedError>().having(
            (it) => it.message,
            'message',
            'No stream handler registered for endpoint: NonExistentEndpoint',
          )),
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
  variantTest(description, body, variants: [
    channelTransport,
    serializationTarget,
  ]);
}

enum ChannelTransport {
  isolatePort,
  webSocket,
  controller,
}

final channelTransport = EnumVariant<ChannelTransport>(
  ChannelTransport.values,
  isCompatible: (value, other, otherValue) {
    if (value == ChannelTransport.webSocket) {
      if (other == serializationTarget) {
        return otherValue == SerializationTarget.json;
      }
    }

    return true;
  },
  order: 100,
);

final serializationTarget = EnumVariant(SerializationTarget.values, order: 90);

Future<Channel> openTestChannel() async {
  StreamChannel<Object?> localTransport;

  switch (channelTransport.value) {
    case ChannelTransport.controller:
      final controller = StreamChannelController<Object?>();
      localTransport = controller.local;
      final remote = Channel(
        transport: controller.foreign,
        packetCodec: packetCoded(serializationTarget.value),
        serializationRegistry: testSerializationRegistry(),
      );
      addTearDown(remote.close);
      registerTestHandlers(remote);
      break;
    case ChannelTransport.isolatePort:
      final receivePort = ReceivePort();
      localTransport = IsolateChannel.connectReceive(receivePort);
      final isolate = await Isolate.spawn(
        testIsolateMain,
        TestIsolateConfig(
          IsolateContext.instance,
          receivePort.sendPort,
          serializationTarget.value,
        ),
      );
      addTearDown(isolate.kill);
      break;
    case ChannelTransport.webSocket:
      final httpServer = await HttpServer.bind('127.0.0.1', 0);
      addTearDown(() => httpServer.close(force: true));

      httpServer.transform(WebSocketTransformer()).listen((webSocket) {
        final remote = Channel(
          transport: IOWebSocketChannel(webSocket),
          packetCodec: packetCoded(serializationTarget.value),
          serializationRegistry: testSerializationRegistry(),
        );

        registerTestHandlers(remote);
      });

      localTransport =
          IOWebSocketChannel.connect('ws://127.0.0.1:${httpServer.port}');
      break;
  }

  final local = Channel(
    transport: localTransport,
    packetCodec: packetCoded(serializationTarget.value),
    serializationRegistry: testSerializationRegistry(),
  );
  addTearDown(local.close);

  return local;
}

void registerTestHandlers(Channel channel) {
  channel
    ..addCallEndpoint((EchoRequest req) => 'Input: ${req.input}')
    ..addCallEndpoint((DataRequest req) {
      final result = req.input.data.toTypedList();
      result[0] = 42;
      return MessageData(result.toData());
    })
    ..addCallEndpoint((ThrowTestError _) =>
        Future<void>.error(const TestError('Oops'), StackTrace.current))
    ..addStreamEndpoint(
        (EchoRequest req) => Stream.value('Input: ${req.input}'))
    ..addStreamEndpoint((ThrowTestError _) =>
        Stream<void>.error(const TestError('Oops'), StackTrace.current))
    ..addStreamEndpoint(
        (InfiniteStream _) => Stream<void>.periodic(InfiniteStream.interval));
}

class TestIsolateConfig {
  TestIsolateConfig(
    this.context,
    this.sendPort,
    this.target,
  );

  final IsolateContext context;
  final SendPort? sendPort;
  final SerializationTarget target;
}

void testIsolateMain(TestIsolateConfig config) {
  initSecondaryIsolate(config.context);

  final remote = Channel(
    transport: IsolateChannel.connectSend(config.sendPort!),
    autoOpen: false,
    packetCodec: packetCoded(config.target),
    serializationRegistry: testSerializationRegistry(),
  );

  registerTestHandlers(remote);

  remote.open();
}

PacketCodec packetCoded(SerializationTarget target) {
  switch (target) {
    case SerializationTarget.isolatePort:
      return IsolatePacketCodec();
    case SerializationTarget.json:
      return JsonPacketCodec();
  }
}

SerializationRegistry testSerializationRegistry() => SerializationRegistry()
  ..addSerializableCodec('EchoRequest', EchoRequest.deserialize)
  ..addSerializableCodec('DataRequest', DataRequest.deserialize)
  ..addSerializableCodec('MessageData', MessageData.deserialize)
  ..addSerializableCodec('ThrowError', ThrowTestError.deserialize)
  ..addSerializableCodec('InfiniteStream', InfiniteStream.deserialize)
  ..addSerializableCodec('NonExistentEndpoint', NonExistentEndpoint.deserialize)
  ..addSerializableCodec('TestError', TestError.deserialize);

class EchoRequest extends Request<String> {
  EchoRequest(this.input);

  final String input;

  @override
  StringMap serialize(SerializationContext context) => {'input': input};

  static EchoRequest deserialize(StringMap map, SerializationContext context) =>
      EchoRequest(map['input']! as String);
}

class DataRequest extends Request<MessageData> {
  DataRequest(this.input);

  final MessageData input;

  @override
  StringMap serialize(SerializationContext context) =>
      {'input': context.serialize(input)};

  static DataRequest deserialize(StringMap map, SerializationContext context) =>
      DataRequest(context.deserializeAs(map['input'])!);

  @override
  void willSend() => input.willSend();

  @override
  void didReceive() => input.didReceive();
}

class MessageData extends Serializable {
  MessageData(Data data) : _data = data;

  Data get data => _data!;
  Data? _data;

  TransferableData? _transferableData;

  @override
  StringMap serialize(SerializationContext context) =>
      {'data': context.addData(_data!)};

  static MessageData deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      MessageData(context.getData(map['data']! as int));

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

class ThrowTestError extends Request<Null> {
  @override
  StringMap serialize(SerializationContext context) => {};

  static ThrowTestError deserialize(
          StringMap map, SerializationContext context) =>
      ThrowTestError();
}

class InfiniteStream extends Request<Null> {
  static const interval = Duration(milliseconds: 10);

  @override
  StringMap serialize(SerializationContext context) => {};

  static InfiniteStream deserialize(
          StringMap map, SerializationContext context) =>
      InfiniteStream();
}

class NonExistentEndpoint extends Request<Null> {
  @override
  StringMap serialize(SerializationContext context) => {};

  static NonExistentEndpoint deserialize(
          StringMap map, SerializationContext context) =>
      NonExistentEndpoint();
}

@immutable
class TestError extends Serializable implements Exception {
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

  @override
  StringMap serialize(SerializationContext context) => {'message': message};

  static TestError deserialize(StringMap map, SerializationContext context) =>
      TestError(map.getAs('message'));
}
