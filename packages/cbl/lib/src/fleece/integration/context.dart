import '../decoder.dart';

class MContext {
  MContext({
    FleeceDecoder? decoder,
  }) : decoder = decoder ?? FleeceDecoder();

  final FleeceDecoder decoder;
}
