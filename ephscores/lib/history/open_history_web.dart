import 'history.dart';

/// The web app keeps no history: a browser can't protect the key.
Future<HistoryStore> openHistory() async =>
    MemoryHistoryStore(available: false);
