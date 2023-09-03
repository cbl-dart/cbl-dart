// TODO(blaugold): Migrate to collection API.
// ignore_for_file: deprecated_member_use

import 'dart:typed_data';

import 'package:cbl/cbl.dart';
import 'package:cbl/src/database/database_base.dart';
import 'package:cbl/src/replication/configuration.dart';
import 'package:cbl/src/replication/conflict.dart';
import 'package:cbl/src/typed_data_internal.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';
import '../utils/matchers.dart';

void main() {
  setupTestBinding();

  group('Configuration', () {
    test('defaults', () {
      final config = ReplicatorConfiguration(
        database: _Database(),
        target: UrlEndpoint(Uri.parse('ws://host/db')),
      );

      expect(config.replicatorType, ReplicatorType.pushAndPull);
      expect(config.continuous, false);
      expect(config.authenticator, isNull);
      expect(config.pinnedServerCertificate, isNull);
      expect(config.trustedRootCertificates, isNull);
      expect(config.headers, isNull);
      expect(config.channels, isNull);
      expect(config.documentIds, isNull);
      expect(config.pushFilter, isNull);
      expect(config.typedPushFilter, isNull);
      expect(config.pullFilter, isNull);
      expect(config.typedPullFilter, isNull);
      expect(config.conflictResolver, isNull);
      expect(config.typedConflictResolver, isNull);
      expect(config.enableAutoPurge, isTrue);
      expect(config.heartbeat, isNull);
      expect(config.maxAttempts, isNull);
      expect(config.maxAttemptWaitTime, isNull);
    });

    test('set validated properties', () {
      final config = ReplicatorConfiguration(
        database: _Database(),
        target: UrlEndpoint(Uri.parse('ws://host/db')),
      )..heartbeat = const Duration(seconds: 1);

      expect(config.heartbeat, const Duration(seconds: 1));
      expect(() => config.heartbeat = Duration.zero, throwsRangeError);
      expect(
        () => config.heartbeat = const Duration(seconds: -1),
        throwsRangeError,
      );

      config.maxAttempts = 1;
      expect(config.maxAttempts, 1);
      expect(() => config.maxAttempts = 0, throwsRangeError);
      expect(() => config.maxAttempts = -1, throwsRangeError);

      config.maxAttemptWaitTime = const Duration(seconds: 1);
      expect(config.maxAttemptWaitTime, const Duration(seconds: 1));
      expect(
        () => config.maxAttemptWaitTime = Duration.zero,
        throwsRangeError,
      );
    });

    test('from', () {
      final source = ReplicatorConfiguration(
        database: _Database(),
        target: UrlEndpoint(Uri.parse('ws://host/db')),
        replicatorType: ReplicatorType.pull,
        continuous: true,
        authenticator: SessionAuthenticator(sessionId: 'sessionId'),
        pinnedServerCertificate: Uint8List(0),
        trustedRootCertificates: Uint8List(0),
        headers: {'Client': 'cbl-dart', 'Authentication': 'AUTH'},
        channels: ['A'],
        documentIds: ['ID'],
        pushFilter: (document, flags) => true,
        typedPushFilter: (document, flags) => true,
        pullFilter: (document, flags) => true,
        typedPullFilter: (document, flags) => true,
        conflictResolver: ConflictResolver.from((_) => null),
        typedConflictResolver: TypedConflictResolver.from((_) => null),
        enableAutoPurge: false,
        heartbeat: const Duration(seconds: 1),
        maxAttempts: 1,
        maxAttemptWaitTime: const Duration(seconds: 1),
      );

      final copy = ReplicatorConfiguration.from(source);

      expect(copy.database, source.database);
      expect(copy.target, source.target);
      expect(copy.replicatorType, source.replicatorType);
      expect(copy.continuous, source.continuous);
      expect(copy.authenticator, source.authenticator);
      expect(copy.pinnedServerCertificate, source.pinnedServerCertificate);
      expect(copy.trustedRootCertificates, source.trustedRootCertificates);
      expect(copy.headers, source.headers);
      expect(copy.channels, source.channels);
      expect(copy.documentIds, source.documentIds);
      expect(copy.pushFilter, source.pushFilter);
      expect(copy.typedPushFilter, source.typedPushFilter);
      expect(copy.pullFilter, source.pullFilter);
      expect(copy.typedPullFilter, source.typedPullFilter);
      expect(copy.conflictResolver, source.conflictResolver);
      expect(copy.typedConflictResolver, source.typedConflictResolver);
      expect(copy.enableAutoPurge, source.enableAutoPurge);
      expect(copy.heartbeat, source.heartbeat);
      expect(copy.maxAttempts, source.maxAttempts);
      expect(copy.maxAttemptWaitTime, source.maxAttemptWaitTime);
    });

    test('toString', () {
      ReplicatorConfiguration config;

      config = ReplicatorConfiguration(
        database: _Database(),
        target: UrlEndpoint(Uri.parse('ws://host/db')),
      );
      expect(
        config.toString(),
        'ReplicatorConfiguration('
        'database: _Database, '
        'target: UrlEndpoint(ws://host/db), '
        // ignore: missing_whitespace_between_adjacent_strings
        'replicatorType: pushAndPull'
        ')',
      );

      config = ReplicatorConfiguration(
        database: _Database(),
        target: UrlEndpoint(Uri.parse('ws://host/db')),
        replicatorType: ReplicatorType.pull,
        continuous: true,
        authenticator: SessionAuthenticator(sessionId: 'sessionId'),
        pinnedServerCertificate: Uint8List(0),
        trustedRootCertificates: Uint8List(0),
        headers: {'Client': 'cbl-dart', 'Authentication': 'AUTH'},
        channels: ['A'],
        documentIds: ['ID'],
        pushFilter: (document, flags) => true,
        typedPushFilter: (document, flags) => true,
        pullFilter: (document, flags) => true,
        typedPullFilter: (document, flags) => true,
        conflictResolver: ConflictResolver.from((_) => null),
        typedConflictResolver: TypedConflictResolver.from((_) => null),
        enableAutoPurge: false,
        heartbeat: const Duration(seconds: 1),
        maxAttempts: 1,
        maxAttemptWaitTime: const Duration(seconds: 1),
      );

      expect(
        config.toString(),
        'ReplicatorConfiguration('
        'database: _Database, '
        'target: UrlEndpoint(ws://host/db), '
        'replicatorType: pull, '
        'CONTINUOUS, '
        'authenticator: SessionAuthenticator(sessionId: ******nId, '
        'cookieName: SyncGatewaySession), '
        'PINNED-SERVER-CERTIFICATE, '
        'TRUSTED-ROOT-CERTIFICATES, '
        'headers: {Client: cbl-dart, Authentication: REDACTED}, '
        'channels: [A], '
        'documentIds: [ID], '
        'PUSH-FILTER, '
        'TYPED-PUSH-FILTER, '
        'PULL-FILTER, '
        'TYPED-PULL-FILTER, '
        'CUSTOM-CONFLICT-RESOLVER, '
        'TYPED-CUSTOM-CONFLICT-RESOLVER, '
        'DISABLE-AUTO-PURGE, '
        'heartbeat: 1s, '
        'maxAttempts: 1, '
        // ignore: missing_whitespace_between_adjacent_strings
        'maxAttemptWaitTime: 1s'
        ')',
      );
    });

    group('combineReplicationFilters', () {
      test('no filter', () {
        expect(combineReplicationFilters(null, null, null), null);
      });

      test('if only untyped filter is used return it directly', () {
        // ignore: prefer_function_declarations_over_variables
        final ReplicationFilter filter = (document, flags) => true;
        expect(combineReplicationFilters(filter, null, null), filter);
      });

      group('typed filter', () {
        group('with unresolvable type', () {
          test('throw exception', () {
            final adapter = TypedDataRegistry();
            final combinedFilter = combineReplicationFilters(
              null,
              (document, flags) => true,
              adapter,
            )!;
            expect(
              () => combinedFilter(MutableDocument(), {}),
              throwsA(
                isTypedDataException
                    .havingCode(TypedDataErrorCode.unresolvableType),
              ),
            );
          });

          test('use untyped filter as fallback', () {
            final doc = MutableDocument();
            final adapter = TypedDataRegistry();
            final combinedFilter = combineReplicationFilters(
              expectAsync2((document, flags) {
                expect(document, doc);
                return true;
              }),
              (document, flags) => true,
              adapter,
            )!;
            expect(combinedFilter(doc, {}), isTrue);
          });
        });
      });
    });

    group('combineConflictResolvers', () {
      test('no conflict resolvers', () {
        expect(combineConflictResolvers(null, null, null), null);
      });

      test('if only untyped conflict resolvers is used return it directly', () {
        final resolver = ConflictResolver.from((conflict) => null);
        expect(combineConflictResolvers(resolver, null, null), resolver);
      });

      group('typed conflict resolver', () {
        group('with unresolved type', () {
          test('throw exception', () {
            final adapter = TypedDataRegistry();

            void expectResolverThrows(Conflict conflict) {
              final combinedFilter = combineConflictResolvers(
                null,
                TypedConflictResolver.from((conflict) => null),
                adapter,
              )!;
              expect(
                () => combinedFilter.resolve(conflict),
                throwsA(
                  isTypedDataException
                      .havingCode(TypedDataErrorCode.unresolvableType),
                ),
              );
            }

            expectResolverThrows(ConflictImpl(
              '',
              MutableDocument(),
              MutableDocument(),
            ));
            expectResolverThrows(ConflictImpl(
              '',
              null,
              MutableDocument(),
            ));

            expectResolverThrows(ConflictImpl(
              '',
              MutableDocument(),
              null,
            ));
          });

          test('use untyped filter as fallback', () {
            final adapter = TypedDataRegistry();

            void expectUsesUntypedResolver(Conflict conflict) {
              final combinedFilter = combineConflictResolvers(
                ConflictResolver.from(expectAsync1((conflict) => null)),
                TypedConflictResolver.from((conflict) => null),
                adapter,
              )!;
              expect(combinedFilter.resolve(conflict), isNull);
            }

            expectUsesUntypedResolver(ConflictImpl(
              '',
              MutableDocument(),
              MutableDocument(),
            ));
            expectUsesUntypedResolver(ConflictImpl(
              '',
              null,
              MutableDocument(),
            ));
            expectUsesUntypedResolver(ConflictImpl(
              '',
              MutableDocument(),
              null,
            ));
          });
        });
      });
    });
  });
}

class _Database with DatabaseBase implements Database {
  @override
  void noSuchMethod(Invocation invocation) {}

  @override
  TypedDataAdapter? get typedDataAdapter => TypedDataRegistry();

  @override
  String toString() => '_Database';
}
