import std/[asynchttpserver, asyncdispatch, json, strutils]
import telemetry

const IndexHtml = """<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Restream Nim - VPS Command Center</title>
    <style>
        body { background: #0b0f17; color: #f0f6fc; font-family: monospace; padding: 20px; }
        .card { background: #161b22; border: 1px solid #30363d; border-radius: 6px; padding: 16px; margin-bottom: 12px; }
        .tag { background: #238636; color: white; padding: 2px 8px; border-radius: 12px; font-weight: bold; }
    </style>
</head>
<body>
    <div class="card">
        <h2>⚡ Restream Nim Engine <span class="tag">ONLINE</span></h2>
        <p>Native Zero-GC Stream Relay & Telemetry Fan-out</p>
        <p>Endpoints: RTMP Ingest :1935 | Web Dashboard :3011</p>
        <div id="stats">Carregando telemetria...</div>
    </div>
    <script>
        setInterval(async () => {
            const res = await fetch('/api/telemetry');
            const data = await res.json();
            document.getElementById('stats').innerHTML = `
                <b>Engine:</b> ${data.engine}<br>
                <b>Uptime:</b> ${data.uptime_seconds}s<br>
                <b>Frames:</b> ${data.frames_emitted}<br>
                <b>FPS:</b> ${data.fps} | <b>Resolução:</b> ${data.resolution}<br>
                <b>Destinos:</b> ${data.targets.join(', ')}
            `;
        }, 3000);
    </script>
</body>
</html>"""

proc runServer*(state: TelemetryState, port: int) {.async.} =
  var server = newAsyncHttpServer()

  proc cb(req: Request) {.async, gcsafe.} =
    let path = req.url.path
    var headers = newHttpHeaders([
      ("Access-Control-Allow-Origin", "*"),
      ("Access-Control-Allow-Methods", "GET, POST, OPTIONS"),
      ("Access-Control-Allow-Headers", "Content-Type, Authorization")
    ])

    if req.reqMethod == HttpOptions:
      await req.respond(Http200, "", headers)
      return

    if path == "/api/status" or path == "/status.json":
      headers.add("Content-Type", "application/json; charset=utf-8")
      let body = $state.toStatusJson()
      await req.respond(Http200, body, headers)
    elif path == "/api/telemetry":
      headers.add("Content-Type", "application/json; charset=utf-8")
      let body = $state.toTelemetryJson()
      await req.respond(Http200, body, headers)
    elif path == "/" or path == "":
      headers.add("Content-Type", "text/html; charset=utf-8")
      await req.respond(Http200, IndexHtml, headers)
    else:
      await req.respond(Http404, "Not Found", headers)

  echo "🌐 [Web Server] Painel de telemetria ativo em http://0.0.0.0:", port
  await server.serve(Port(port), cb, "0.0.0.0")
