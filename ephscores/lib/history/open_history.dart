/// The history for this platform: encrypted SQLite on Android, none on the
/// web.
library;

export 'open_history_web.dart'
    if (dart.library.ffi) 'sqlite_history.dart'
    show openHistory;
