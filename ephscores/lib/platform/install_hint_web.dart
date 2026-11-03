import 'package:web/web.dart' as web;

/// True in iOS Safari when the app isn't running from the home screen, where
/// installing is the only way to get an app-like, persistent experience.
bool get shouldSuggestInstall {
  final nav = web.window.navigator;
  final ua = nav.userAgent;
  // iPadOS reports itself as a Mac; touch support gives it away.
  final ios =
      RegExp('iPhone|iPad|iPod').hasMatch(ua) ||
      (ua.contains('Macintosh') && nav.maxTouchPoints > 1);
  final installed = web.window.matchMedia('(display-mode: standalone)').matches;
  return ios && !installed;
}
