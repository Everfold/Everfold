import 'dart:async';

import 'package:everfold/data/services/storage/preferences_store.dart';

/// 为失败与并发测试提供可控的存储行为
final class TestPreferencesStore implements PreferencesStore {
  TestPreferencesStore({this.value});

  String? value;
  bool failRead = false;
  bool failWrite = false;
  int reads = 0;
  int writes = 0;
  Completer<void>? readGate;
  Completer<void>? writeGate;

  @override
  Future<String?> readString(String key) async {
    reads++;
    if (readGate != null) await readGate!.future;
    if (failRead) throw Exception('private storage details');
    return value;
  }

  @override
  Future<void> writeString(String key, String next) async {
    writes++;
    if (writeGate != null) await writeGate!.future;
    if (failWrite) throw Exception('private storage details');
    value = next;
  }
}
