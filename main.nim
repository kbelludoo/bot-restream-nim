import std/[os, asyncdispatch, strutils]
import config, telemetry, pipeline, server

proc main() =
  echo "================================================================================"
  echo "     ⚡ RESTREAM NIM ENGINE (NATIVE ZERO-GC & ULTRA-LOW FOOTPRINT) ⚡          "
  echo "             Kick + Twitch + YouTube • Zero Buffer Bloat • < 5MB RAM            "
  echo "================================================================================"

  var configPath = "config.json"
  var i = 1
  while i <= paramCount():
    let arg = paramStr(i)
    if (arg == "-config" or arg == "--config") and i + 1 <= paramCount():
      configPath = paramStr(i + 1)
      i += 2
    else:
      i += 1

  var cfg = loadConfig(configPath)
  let portStr = getEnv("PORT", $cfg.webPort)
  let port = try: parseInt(portStr) except CatchableError: cfg.webPort
  cfg.webPort = port

  let state = newTelemetryState(cfg)

  # 1. Start Web Server
  asyncCheck runServer(state, port)

  # 2. Start Video/Audio Relay Pipeline
  asyncCheck runPipeline(state)

  runForever()

when isMainModule:
  main()
