// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:collection/collection.dart';

import '../../bindings.dart';
import '../../database.dart';
import '../../query.dart';
import 'index.dart';

/// A specification of an [Index] from a list of SQL++ [expressions].
///
/// {@category Query}
abstract final class IndexConfiguration implements Index {
  /// The SQL++ expressions to use to create the index.
  abstract List<String> expressions;
}

/// A specification of a value [Index] from a list of SQL++ [expressions].
///
/// {@category Query}
abstract final class ValueIndexConfiguration implements IndexConfiguration {
  /// Creates a specification of a value [Index] from a list of SQL++
  /// [expressions].
  factory ValueIndexConfiguration(List<String> expressions) =
      _ValueIndexConfiguration;
}

/// A specification of a full text [Index] from a list of SQL++ [expressions].
///
/// {@category Query}
abstract final class FullTextIndexConfiguration implements IndexConfiguration {
  /// Creates a specification of a full text [Index] from a list of SQL++
  /// [expressions].
  factory FullTextIndexConfiguration(
    List<String> expressions, {
    bool? ignoreAccents,
    FullTextLanguage? language,
  }) = _FullTextIndexConfiguration;

  /// Whether the index should ignore accents and diacritical marks.
  ///
  /// The default is `false`.
  abstract bool ignoreAccents;

  /// The dominant language.
  ///
  /// Setting this enables word stemming, i.e. matching different cases of the
  /// same word ("big" and "bigger", for instance) and ignoring common
  /// "stop-words" ("the", "a", "of", etc.)
  ///
  /// If left `null` no language-specific behaviors such as stemming and
  /// stop-word removal occur.
  abstract FullTextLanguage? language;
}

/// Type of a [VectorEncoding.scalarQuantizer].
///
/// {@macro cbl.EncryptionKey.enterpriseFeature}
///
/// {@category Query}
/// {@category Enterprise Edition}
enum ScalarQuantizerType {
  /// Use 4 bits per dimension.
  fourBit,

  /// Use 6 bits per dimension.
  sixBit,

  /// Use 8 bits per dimension.
  eightBit;

  DartCBLScalarQuantizerType _toCBL() => switch (this) {
    fourBit => kCBLSQ4,
    sixBit => kCBLSQ6,
    eightBit => kCBLSQ8,
  };
}

/// A vector encoding to reduce the size of the vectors index by algorithmic
/// compression.
///
/// {@macro cbl.EncryptionKey.enterpriseFeature}
///
/// You can configure the vector encoding to address your application’s needs.
///
/// This vector encoding compression reduces disk space required and I/O time
/// during indexing and queries, but greater compression can result in
/// inaccurate results in distance calculations.
///
/// {@category Query}
/// {@category Enterprise Edition}
abstract final class VectorEncoding {
  /// Creates an encoding without data loss, using 4 bytes per dimension.
  ///
  /// This will return the highest quality results but at high performance and
  /// disk space costs.
  factory VectorEncoding.none() => VectorEncodingImpl();

  /// Creates a scalar quantizer encoding of the given [type].
  ///
  /// This reduces the number of bits used for each number in a vector. The
  /// number of bits per component can be set to 4, 6, or 8 bits. The default
  /// setting in Couchbase Lite is 8 bits Scalar Quantizer or SQ-8.
  factory VectorEncoding.scalarQuantizer(ScalarQuantizerType type) =>
      VectorEncodingImpl(scalarQuantizerType: type);

  /// Creates a product quantizer encoding.
  ///
  /// This reduces the number of dimensions and bits per dimension. It splits
  /// the vectors into multiple subspaces and performing scalar quantization on
  /// each space independently before compression. This can produce higher
  /// quality results than Scalar Quantization at the cost of greater
  /// complexity.
  ///
  /// [subQuantizers] must be > 1 and a factor of vector dimensions.
  ///
  /// [bits] must be >= 4 and <= 12.
  factory VectorEncoding.productQuantizer({
    required int subQuantizers,
    required int bits,
  }) => VectorEncodingImpl(
    productQuantizerSubQuantizers: subQuantizers,
    productQuantizerBits: bits,
  );
}

/// A function used to define how close an input query vector is to other
/// vectors within a vector index.
///
/// {@macro cbl.EncryptionKey.enterpriseFeature}
///
/// {@category Query}
/// {@category Enterprise Edition}
enum DistanceMetric {
  /// Euclidean distance (AKA L2)
  ///
  /// This measures the straight-line distance between two points in Euclidean
  /// space which is defined by n dimensions, such as x,y,z. This metric focuses
  /// on the spatial separation or distance between two vectors. Both the
  /// magnitude and direction of the vectors matter. The smaller the distance
  /// value, the more similar the vectors are. This differs from
  /// [euclideanSquared] distance by taking the square root of the calculated
  /// distance between two point. The result is a "true" geometric distance. You
  /// can use this metric when the actual geometric distance matters, such as
  /// calculating distance between cities using GPS coordinates.
  euclidean,

  /// Squared Euclidean distance (AKA Squared L2)
  ///
  /// This is the default distance metric. This measures the straight-line
  /// distance between two points in Euclidean space which is defined by n
  /// dimensions, such as x,y,z. This metric focuses on the spatial separation
  /// or distance between two vectors. Both the magnitude and direction of the
  /// vectors matter. The smaller the distance value, the more similar the
  /// vectors are. You can use this metric to simplify computation in situations
  /// where only the relative distance matters, rather than actual distance.
  euclideanSquared,

  /// Cosine distance (1.0 - Cosine Similarity)
  ///
  /// This measures the cosine of the angle between two vectors in vector space.
  /// This metric focuses on the alignment of two vectors, the similarity of
  /// direction. Only the direction of the vectors matter. The smaller the
  /// distance value, the more similar the vectors are. You can use this metric
  /// when comparing similarity of document content no matter the document size
  /// in text similarity or information retrieval applications.
  cosine,

  /// Dot-product distance (Negative of dot-product)
  ///
  /// This metric captures the overall similarity by comparing the magnitude and
  /// direction of vectors. The result is larger when the vectors are aligned
  /// and have large magnitudes and smaller in the opposite case. You can use
  /// this metric in recommendation systems to provide users with related
  /// content with preference to items the most similar to frequently visited
  /// items.
  dot;

  DartCBLDistanceMetric _toCBL() => switch (this) {
    euclideanSquared => kCBLDistanceMetricEuclideanSquared,
    cosine => kCBLDistanceMetricCosine,
    euclidean => kCBLDistanceMetricEuclidean,
    dot => kCBLDistanceMetricDot,
  };
}

/// A specification of a vector [Index] from a SQL++ [expression].
///
/// {@macro cbl.EncryptionKey.enterpriseFeature}
///
/// Vector Search is a technique to retrieve semantically similar items based on
/// vector embedding representations of the items in a multi-dimensional space.
/// You can use vector search to find the top N items similar to a given item
/// based on their vector representations. Vector Search is an essential
/// component of generative AI and predictive AI applications.
///
/// Vector search is a sophisticated data retrieval technique that focuses on
/// matching the contextual meanings of search queries and data entries, rather
/// than simple text matching. Vectors are represented by arrays of numbers
/// known as an embedding, which are generated by Large Language Models (LLMs)
/// to depict objects such as text, images, and audio.
///
/// Once you choose the LLM you wish to integrate in your application, you can
/// create vector indexes that will store these embeddings for improved search
/// performance and start querying against them.
///
/// {@category Query}
/// {@category Enterprise Edition}
abstract final class VectorIndexConfiguration implements IndexConfiguration {
  /// Creates a specification of a vector [Index] from a SQL++ [expression].
  factory VectorIndexConfiguration(
    String expression, {
    required int dimensions,
    required int centroids,
    bool? lazy,
    VectorEncoding? encoding,
    DistanceMetric? metric,
    int? minTrainingSize,
    int? maxTrainingSize,
    int? numProbes,
  }) = _VectorIndexConfiguration;

  /// The SQL++ expression to use to create the index.
  abstract String expression;

  /// The list of SQL++ expressions to use to create the index, which must
  /// contain a single expression for a vector index.
  ///
  /// Consider using [expression] instead.
  @override
  abstract List<String> expressions;

  /// The number of vector dimensions to use for the index.
  ///
  /// Vector dimensions describes the amount of numbers in a given vector
  /// embedding, commonly known as its width. The greater the number of
  /// dimensions, the greater accuracy of results. However, a greater number of
  /// dimensions also results in greater compute and memory costs and an
  /// increase in the latency of the search. Vector dimensions are dependent on
  /// the model used to generate the vector embeddings.
  ///
  /// The range of supported dimensions is 2 to 4096.
  abstract int dimensions;

  /// The number of centroids to use for the index.
  ///
  /// Centroids are vectors that function as the center point of a vector
  /// cluster within the data set. Each vector is then associated to the vector
  /// it is closest to by [k-means clustering]. Each Centroid is contained
  /// within a bucket along with its associated vectors. The greater the number
  /// of centroids, the greater the potential accuracy of the model. However, a
  /// greater number of centroids will incur a longer indexing time.
  ///
  /// Choosing centroids in vector search involves trade-offs that can impact
  /// clustering effectiveness and search efficiency. The initial selection of
  /// centroids, the number chosen, and their sensitivity to high dimensionality
  /// and outliers affect the quality of vector clustering.
  ///
  /// The general guideline for the optimum number of centroids is approximately
  /// the square root of the number of documents.
  ///
  /// The range of supported centroids is 1 to 64,000.
  ///
  /// [k-means clustering]: https://en.wikipedia.org/wiki/K-means_clustering
  abstract int centroids;

  /// Whether index is lazy or not.
  ///
  /// The default is `false`.
  ///
  /// If the index is lazy, it will not be automatically updated when the
  /// documents in the collection are changed, except when the documents are
  /// deleted or purged.
  ///
  /// When configuring the index to be lazy, the configured [expression] is
  /// evaluated to obtain the value used for computing the vector.
  ///
  /// To begin updating a lazy index, use [Collection.index] to get it and call
  /// its [QueryIndex.beginUpdate] method. This will return an [IndexUpdater] if
  /// the index needs to be updated. See [IndexUpdater] for more information.
  abstract bool lazy;

  /// The vector encoding type to use for the index.
  ///
  /// The default is a [VectorEncoding.scalarQuantizer] with
  /// [ScalarQuantizerType.eightBit].
  abstract VectorEncoding encoding;

  /// The distance metric to use for the index.
  ///
  /// The default is [DistanceMetric.euclideanSquared].
  abstract DistanceMetric metric;

  /// The minimum number of vectors for training the index.
  ///
  /// If not specified, [minTrainingSize] will be determined based on the number
  /// of [centroids] and the [encoding].
  abstract int? minTrainingSize;

  /// The maximum number of vectors used for training the index.
  ///
  /// If not specified, [maxTrainingSize] will be determined based on the number
  /// of [centroids] and the [encoding].
  abstract int? maxTrainingSize;

  /// The number of centroids that will be scanned during a query.
  ///
  /// If not specified, [numProbes] will be determined based on the number of
  /// [centroids].
  abstract int? numProbes;
}

// === Impl ====================================================================

abstract final class _IndexConfiguration implements IndexConfiguration {
  _IndexConfiguration(List<String> expressions) {
    this.expressions = expressions;
  }

  List<String> _expressions = [];

  @override
  List<String> get expressions => _expressions;

  @override
  set expressions(List<String> expressions) {
    if (expressions.isEmpty) {
      throw ArgumentError.value(
        expressions,
        'expressions',
        'must not be empty',
      );
    }
    _expressions = expressions;
  }
}

final class _ValueIndexConfiguration extends _IndexConfiguration
    implements ValueIndexConfiguration, IndexImplInterface {
  _ValueIndexConfiguration(super.expressions);

  @override
  CBLIndexSpec toCBLIndexSpec() => CBLIndexSpec(
    expressionLanguage: CBLQueryLanguage.n1ql,
    expressions: expressions.join(', '),
    type: CBLDartIndexType.value$,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ValueIndexConfiguration &&
          runtimeType == other.runtimeType &&
          const DeepCollectionEquality().equals(expressions, other.expressions);

  @override
  int get hashCode => const DeepCollectionEquality().hash(expressions);

  @override
  String toString() => 'ValueIndexConfiguration(${expressions.join(', ')})';
}

final class _FullTextIndexConfiguration extends _IndexConfiguration
    implements FullTextIndexConfiguration, IndexImplInterface {
  _FullTextIndexConfiguration(
    super.expressions, {
    bool? ignoreAccents,
    this.language,
  }) : ignoreAccents = ignoreAccents ?? false;

  @override
  bool ignoreAccents;

  @override
  FullTextLanguage? language;

  @override
  CBLIndexSpec toCBLIndexSpec() => CBLIndexSpec(
    expressionLanguage: CBLQueryLanguage.n1ql,
    expressions: expressions.join(', '),
    type: CBLDartIndexType.fullText,
    ignoreAccents: ignoreAccents,
    language: language?.name,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _FullTextIndexConfiguration &&
          runtimeType == other.runtimeType &&
          const DeepCollectionEquality().equals(
            expressions,
            other.expressions,
          ) &&
          ignoreAccents == other.ignoreAccents &&
          language == other.language;

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(expressions) ^
      ignoreAccents.hashCode ^
      language.hashCode;

  @override
  String toString() {
    final properties = [
      if (ignoreAccents) 'IGNORE-ACCENTS',
      if (language != null) 'language: ${language!.name}',
    ];

    return [
      'FullTextIndexConfiguration(',
      expressions.join(', '),
      if (properties.isNotEmpty) ' | ',
      properties.join(', '),
      ')',
    ].join();
  }
}

final class VectorEncodingImpl implements VectorEncoding {
  VectorEncodingImpl({
    this.scalarQuantizerType,
    this.productQuantizerSubQuantizers,
    this.productQuantizerBits,
  });

  final ScalarQuantizerType? scalarQuantizerType;
  final int? productQuantizerSubQuantizers;
  final int? productQuantizerBits;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VectorEncodingImpl &&
          runtimeType == other.runtimeType &&
          scalarQuantizerType == other.scalarQuantizerType &&
          productQuantizerSubQuantizers ==
              other.productQuantizerSubQuantizers &&
          productQuantizerBits == other.productQuantizerBits;

  @override
  int get hashCode => Object.hash(
    runtimeType,
    scalarQuantizerType,
    productQuantizerSubQuantizers,
    productQuantizerBits,
  );

  @override
  String toString() => [
    'VectorEncoding.',
    if (scalarQuantizerType != null)
      'scalarQuantizer(${scalarQuantizerType!.name})'
    else if (productQuantizerSubQuantizers != null &&
        productQuantizerBits != null)
      'productQuantizer('
          'subQuantizers: $productQuantizerSubQuantizers, '
          'bits: $productQuantizerBits'
          ')'
    else
      'none()',
  ].join();
}

final class _VectorIndexConfiguration extends _IndexConfiguration
    implements VectorIndexConfiguration, IndexImplInterface {
  _VectorIndexConfiguration(
    String expression, {
    required this.dimensions,
    required this.centroids,
    bool? lazy,
    VectorEncoding? encoding,
    DistanceMetric? metric,
    this.minTrainingSize,
    this.maxTrainingSize,
    this.numProbes,
  }) : lazy = lazy ?? false,
       encoding =
           encoding ??
           VectorEncoding.scalarQuantizer(ScalarQuantizerType.eightBit),
       metric = metric ?? DistanceMetric.euclideanSquared,
       super([expression]);

  @override
  String get expression => expressions.single;

  @override
  set expression(String value) => expressions = [value];

  @override
  set expressions(List<String> value) {
    if (value.length != 1) {
      throw ArgumentError.value(
        value,
        'expressions',
        'must contain exactly one expression',
      );
    }
    super.expressions = value;
  }

  @override
  int dimensions;

  @override
  int centroids;

  @override
  bool lazy;

  @override
  VectorEncoding encoding;

  @override
  DistanceMetric metric;

  @override
  int? minTrainingSize;

  @override
  int? maxTrainingSize;

  @override
  int? numProbes;

  @override
  CBLIndexSpec toCBLIndexSpec() {
    final encoding = this.encoding as VectorEncodingImpl;
    return CBLIndexSpec(
      expressionLanguage: CBLQueryLanguage.n1ql,
      expressions: expressions.join(', '),
      type: CBLDartIndexType.vector,
      dimensions: dimensions,
      centroids: centroids,
      lazy: lazy,
      scalarQuantizerType: encoding.scalarQuantizerType?._toCBL(),
      productQuantizerSubQuantizers: encoding.productQuantizerSubQuantizers,
      productQuantizerBits: encoding.productQuantizerBits,
      metric: metric._toCBL(),
      minTrainingSize: minTrainingSize,
      maxTrainingSize: maxTrainingSize,
      numProbes: numProbes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _VectorIndexConfiguration &&
          runtimeType == other.runtimeType &&
          const DeepCollectionEquality().equals(
            expressions,
            other.expressions,
          ) &&
          dimensions == other.dimensions &&
          centroids == other.centroids &&
          lazy == other.lazy &&
          encoding == other.encoding &&
          metric == other.metric &&
          minTrainingSize == other.minTrainingSize &&
          maxTrainingSize == other.maxTrainingSize &&
          numProbes == other.numProbes;

  @override
  int get hashCode => Object.hash(
    const DeepCollectionEquality().hash(expressions),
    dimensions,
    centroids,
    lazy,
    encoding,
    metric,
    minTrainingSize,
    maxTrainingSize,
    numProbes,
  );

  @override
  String toString() {
    final properties = [
      'dimensions: $dimensions',
      'centroids: $centroids',
      if (lazy) 'LAZY',
      'encoding: $encoding',
      'metric: ${metric.name}',
      if (minTrainingSize != null) 'minTrainingSize: $minTrainingSize',
      if (maxTrainingSize != null) 'maxTrainingSize: $maxTrainingSize',
      if (numProbes != null) 'numProbes: $numProbes',
    ];

    return [
      'VectorIndexConfiguration(',
      expressions.join(', '),
      if (properties.isNotEmpty) ' | ',
      properties.join(', '),
      ')',
    ].join();
  }
}
