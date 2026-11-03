{{flutter_js}}
{{flutter_build_config}}

// Loaded without Flutter's (deprecated) service worker; offline caching is
// handled by sw.js.
_flutter.loader.load({
  onEntrypointLoaded: async (engineInitializer) => {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    document.getElementById('splash')?.remove();
  },
});
