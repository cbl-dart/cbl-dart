import '../encoder.dart';
import '../slice.dart';
import 'collection.dart';
import 'context.dart';
import 'value.dart';

class MRoot extends MCollection {
  MRoot({
    required this.data,
    required MContext context,
    required bool isMutable,
  })  : _slot = MValue.withValue(context.decoder.loadValueFromData(data)!),
        super(context, isMutable: isMutable) {
    _slot.updateParent(this);
  }

  final Slice data;

  final MValue _slot;

  @override
  MContext get context => super.context!;

  @override
  bool get isMutated => _slot.isMutated;

  @override
  Iterable<MValue> get values => [_slot];

  @override
  void encodeTo(FleeceEncoder encoder) => _slot.encodeTo(encoder);

  Object? get asNative => _slot.asNative(this);

  Slice encode() {
    var encoder = FleeceEncoder();
    encodeTo(encoder);
    return encoder.finish();
  }
}
