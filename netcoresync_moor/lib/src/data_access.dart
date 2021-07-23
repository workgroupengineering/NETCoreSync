import 'dart:async';
import 'package:moor/moor.dart';
import 'netcoresync_engine.dart';
import 'netcoresync_knowledges.dart';
import 'netcoresync_exceptions.dart';

class DataAccess<G extends GeneratedDatabase> extends DatabaseAccessor<G> {
  late G database;
  late NetCoreSyncEngine engine;
  late _NetCoreSyncKnowledgesTable knowledges;

  DataAccess(
    G generatedDatabase,
    this.engine,
  ) : super(generatedDatabase) {
    database = attachedDatabase;
    knowledges = _NetCoreSyncKnowledgesTable(database);
  }

  bool inTransaction() {
    return Zone.current[#DatabaseConnectionUser]
        .toString()
        .contains("Transaction");
  }

  dynamic get resolvedEngine =>
      Zone.current[#DatabaseConnectionUser] ?? database;

  Future<int> getNextTimeStamp() async {
    DatabaseConnectionUser activeDb = resolvedEngine as DatabaseConnectionUser;
    NetCoreSyncKnowledge? localKnowledge = await (activeDb.select(knowledges)
          ..where((tbl) => tbl.local))
        .getSingleOrNull();
    if (localKnowledge == null) {
      NetCoreSyncKnowledge newLocalKnowledge = NetCoreSyncKnowledge();
      newLocalKnowledge.local = true;
      await activeDb.into(knowledges).insert(newLocalKnowledge);
      localKnowledge = await (activeDb.select(knowledges)
            ..where((tbl) => tbl.id.equals(newLocalKnowledge.id)))
          .getSingle();
    }
    int nextTimeStamp = localKnowledge.maxTimeStamp + 1;
    await (activeDb.update(knowledges)
          ..where((tbl) => tbl.id.equals(localKnowledge!.id)))
        .write(_NetCoreSyncKnowledgesCompanion(
      maxTimeStamp: Value(nextTimeStamp),
    ));
    return nextTimeStamp;
  }

  Future<T> syncAction<T, D>(
    Insertable<D> entity,
    Future<T> Function(dynamic syncEntity, int obtainedTimeStamp) action,
  ) async {
    if (!inTransaction()) throw NetCoreSyncMustInsideTransactionException();
    if (!engine.tables.containsKey(D))
      throw NetCoreSyncTypeNotRegisteredException(D);
    int timeStamp = await getNextTimeStamp();
    Insertable<D> syncEntity =
        engine.updateSyncColumns(entity, timeStamp: timeStamp);
    return action(syncEntity, timeStamp);
  }

  Future<List<String>> ensureAllTableTimeStampsAreValid() async {
    if (!inTransaction()) throw NetCoreSyncMustInsideTransactionException();
    DatabaseConnectionUser activeDb = resolvedEngine as DatabaseConnectionUser;
    int maxTimeStamp = 0;
    NetCoreSyncKnowledge? localKnowledge = await (activeDb.select(knowledges)
          ..where((tbl) => tbl.local))
        .getSingleOrNull();
    if (localKnowledge != null) {
      maxTimeStamp = localKnowledge.maxTimeStamp;
    } else {
      maxTimeStamp = await getNextTimeStamp();
    }
    List<String> logs = [];
    for (Type type in engine.tables.keys) {
      final tableUser = engine.tables[type]!;
      int rowsAffected = await activeDb.customUpdate(
        "UPDATE ${tableUser.tableInfo.entityName} SET ${tableUser.timeStampEscapedName} = $maxTimeStamp WHERE ${tableUser.knowledgeIdEscapedName} IS NULL AND (${tableUser.timeStampEscapedName} = 0 OR ${tableUser.timeStampEscapedName} > $maxTimeStamp)",
        updateKind: UpdateKind.update,
      );
      logs.add("$type: $rowsAffected row(s) affected.");
    }
    return logs;
  }
}

// The following classes were copied from Moor's generated @UseMoor class (with several modifications such as making class names private with underscore + removing unused constructors)

class _NetCoreSyncKnowledgesCompanion
    extends UpdateCompanion<NetCoreSyncKnowledge> {
  final Value<String> id;
  final Value<bool> local;
  final Value<int> maxTimeStamp;
  const _NetCoreSyncKnowledgesCompanion({
    this.id = const Value.absent(),
    this.local = const Value.absent(),
    this.maxTimeStamp = const Value.absent(),
  });

  _NetCoreSyncKnowledgesCompanion copyWith(
      {Value<String>? id, Value<bool>? local, Value<int>? maxTimeStamp}) {
    return _NetCoreSyncKnowledgesCompanion(
      id: id ?? this.id,
      local: local ?? this.local,
      maxTimeStamp: maxTimeStamp ?? this.maxTimeStamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (local.present) {
      map['local'] = Variable<bool>(local.value);
    }
    if (maxTimeStamp.present) {
      map['max_time_stamp'] = Variable<int>(maxTimeStamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('_NetCoreSyncKnowledgesCompanion(')
          ..write('id: $id, ')
          ..write('local: $local, ')
          ..write('maxTimeStamp: $maxTimeStamp')
          ..write(')'))
        .toString();
  }
}

class _NetCoreSyncKnowledgesTable extends NetCoreSyncKnowledges
    with TableInfo<_NetCoreSyncKnowledgesTable, NetCoreSyncKnowledge> {
  final GeneratedDatabase _db;
  final String? _alias;
  _NetCoreSyncKnowledgesTable(this._db, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String?> id = GeneratedColumn<String?>(
      'id', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 36),
      typeName: 'TEXT',
      requiredDuringInsert: true);
  final VerificationMeta _localMeta = const VerificationMeta('local');
  late final GeneratedColumn<bool?> local = GeneratedColumn<bool?>(
      'local', aliasedName, false,
      typeName: 'INTEGER',
      requiredDuringInsert: true,
      defaultConstraints: 'CHECK (local IN (0, 1))');
  final VerificationMeta _maxTimeStampMeta =
      const VerificationMeta('maxTimeStamp');
  late final GeneratedColumn<int?> maxTimeStamp = GeneratedColumn<int?>(
      'max_time_stamp', aliasedName, false,
      typeName: 'INTEGER', requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, local, maxTimeStamp];
  @override
  String get aliasedName => _alias ?? 'netcoresync_knowledges';
  @override
  String get actualTableName => 'netcoresync_knowledges';
  @override
  VerificationContext validateIntegrity(
      Insertable<NetCoreSyncKnowledge> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('local')) {
      context.handle(
          _localMeta, local.isAcceptableOrUnknown(data['local']!, _localMeta));
    } else if (isInserting) {
      context.missing(_localMeta);
    }
    if (data.containsKey('max_time_stamp')) {
      context.handle(
          _maxTimeStampMeta,
          maxTimeStamp.isAcceptableOrUnknown(
              data['max_time_stamp']!, _maxTimeStampMeta));
    } else if (isInserting) {
      context.missing(_maxTimeStampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NetCoreSyncKnowledge map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NetCoreSyncKnowledge.fromDb(
      id: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
      local: const BoolType()
          .mapFromDatabaseResponse(data['${effectivePrefix}local'])!,
      maxTimeStamp: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}max_time_stamp'])!,
    );
  }

  @override
  _NetCoreSyncKnowledgesTable createAlias(String alias) {
    return _NetCoreSyncKnowledgesTable(_db, alias);
  }
}
