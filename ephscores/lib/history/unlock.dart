import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

enum UnlockResult {
  ok,
  failed,

  /// The phone has no screen lock, so the history can't be protected.
  noLock,
}

/// Asks for the phone's screen lock (fingerprint, face, PIN, pattern or
/// password) before the history is shown.
abstract class Unlocker {
  Future<UnlockResult> unlock();
}

class DeviceUnlocker implements Unlocker {
  final _auth = LocalAuthentication();

  @override
  Future<UnlockResult> unlock() async {
    try {
      if (!await _auth.isDeviceSupported()) return UnlockResult.noLock;
      final ok = await _auth.authenticate(
        localizedReason: 'Desbloquear o histórico de doentes',
        persistAcrossBackgrounding: true,
      );
      return ok ? UnlockResult.ok : UnlockResult.failed;
    } on LocalAuthException catch (e) {
      return e.code == LocalAuthExceptionCode.noCredentialsSet
          ? UnlockResult.noLock
          : UnlockResult.failed;
    } on Object catch (e) {
      debugPrint('Unlock failed: $e');
      return UnlockResult.failed;
    }
  }
}

/// Unlocks with a fixed result; for tests.
class NoUnlocker implements Unlocker {
  const NoUnlocker([this.result = UnlockResult.ok]);

  final UnlockResult result;

  @override
  Future<UnlockResult> unlock() async => result;
}
