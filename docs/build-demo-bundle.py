"""Packs the Flutter web build into one self-contained HTML file.

The Artifact host serves a single page with a strict CSP, so every runtime
asset the engine would fetch has to travel inside the file. main.dart.js goes
in as plain text (it contains no '</script>'), the rest as base64 served by a
fetch() shim.
"""
import base64
import json
import pathlib

BUILD = pathlib.Path('/home/user/TrailWatts/build/web')
OUT = pathlib.Path('/home/user/TrailWatts/docs/trailwatt-demo.html')

# NOTICES (1.7 MB, only for the licence page) and the canvaskit-only shader
# are deliberately left out.
ASSETS = [
    'assets/AssetManifest.bin',
    'assets/AssetManifest.bin.json',
    'assets/AssetManifest.json',
    'assets/FontManifest.json',
    'assets/fonts/MaterialIcons-Regular.otf',
    'assets/packages/flutter_map/lib/assets/flutter_map_logo.png',
]

embedded = {}
for rel in ASSETS:
    p = BUILD / rel
    if not p.exists():
        raise SystemExit(f'missing asset: {rel}')
    embedded[rel] = base64.b64encode(p.read_bytes()).decode()

main_js = (BUILD / 'main.dart.js').read_text(encoding='utf-8')
if '</script' in main_js.lower():
    raise SystemExit('main.dart.js would break out of the script tag')

html = """<title>Trailwatt</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
  html, body { margin:0; padding:0; height:100%; background:#F5F7F6; }
  #tw-boot { font: 500 13px/1.5 -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
             color:#5B6B69; display:flex; align-items:center; justify-content:center;
             height:100vh; }
</style>
<div id="tw-boot">Carregando Trailwatt...</div>
<script>
window.__TW_ASSETS = __ASSETS__;
(function () {
  var decode = function (b64) {
    var bin = atob(b64), out = new Uint8Array(bin.length);
    for (var i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
    return out;
  };
  var original = window.fetch.bind(window);
  window.fetch = function (input, init) {
    var url = typeof input === 'string' ? input : (input && input.url) || '';
    for (var key in window.__TW_ASSETS) {
      if (url.indexOf(key) !== -1) {
        return Promise.resolve(new Response(decode(window.__TW_ASSETS[key]), {
          status: 200,
          headers: { 'Content-Type': 'application/octet-stream' }
        }));
      }
    }
    return original(input, init);
  };
})();

window._flutter = {
  buildConfig: {
    engineRevision: '__REV__',
    builds: [{ compileTarget: 'dart2js', renderer: 'html', mainJsPath: 'main.dart.js' }],
    useLocalCanvasKit: true
  },
  loader: {
    // main.dart.js calls this once it has loaded; there is no separate
    // flutter.js loader here because nothing needs to be fetched.
    didCreateEngineInitializer: function (engineInitializer) {
      return engineInitializer.initializeEngine({ renderer: 'html' })
        .then(function (appRunner) {
          var boot = document.getElementById('tw-boot');
          if (boot) boot.remove();
          return appRunner.runApp();
        });
    }
  }
};
</script>
<script>
__MAIN_JS__
</script>
"""

rev = json.loads((BUILD / 'version.json').read_text()).get('engine_revision', '')
html = (html
        .replace('__ASSETS__', json.dumps(embedded))
        .replace('__REV__', rev)
        .replace('__MAIN_JS__', main_js))

OUT.parent.mkdir(parents=True, exist_ok=True)
OUT.write_text(html, encoding='utf-8')
print(f'{OUT}  {OUT.stat().st_size / 1024 / 1024:.2f} MB')
