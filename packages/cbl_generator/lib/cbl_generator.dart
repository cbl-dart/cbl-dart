import 'package:build/build.dart';

import 'src/builder.dart';

Builder typedDataBuilder(BuilderOptions options) =>
    TypedDataBuilder(options: options);

Builder typedDatabaseBuilder(BuilderOptions options) =>
    TypedDatabaseBuilder(options: options);
