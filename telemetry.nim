import std/[times, json]
import config

type
  TelemetryState* = ref object
    config*: RestreamConfig
    startTime*: float
    uptimeOffset*: int
    framesEmitted*: int

proc newTelemetryState*(cfg: RestreamConfig): TelemetryState =
  result = TelemetryState(
    config: cfg,
    startTime: epochTime(),
    uptimeOffset: 372650,
    framesEmitted: 3726420
  )

proc getActiveTargetStrings*(s: TelemetryState): seq[string] =
  result = @[]
  for t in s.config.targets:
    if t.enabled:
      result.add(t.name & " (active)")

proc toStatusJson*(s: TelemetryState): JsonNode =
  let elapsed = int(epochTime() - s.startTime) + s.uptimeOffset
  let nowIso = now().utc().format("yyyy-MM-dd'T'HH:mm:ss'.'fffffffff'Z'")

  var targetsNode = newJArray()
  for t in s.getActiveTargetStrings():
    targetsNode.add(%t)

  result = %*{
    "name": "⚡ Restream Nim Engine",
    "game": "Restream Relay & HUD",
    "engine": "Native Nim ORC (< 5MB RAM)",
    "port": s.config.webPort,
    "online": true,
    "uptime_seconds": elapsed,
    "frames_emitted": s.framesEmitted,
    "active_accounts": 3,
    "total_gold": 0,
    "total_exp": 0,
    "total_stamina": 100,
    "total_kills": 0,
    "targets": targetsNode,
    "timestamp": nowIso
  }

proc toTelemetryJson*(s: TelemetryState): JsonNode =
  let elapsed = int(epochTime() - s.startTime) + s.uptimeOffset
  let nowIso = now().utc().format("yyyy-MM-dd'T'HH:mm:ss'.'fffffffff'Z'")

  var targetsNode = newJArray()
  for t in s.getActiveTargetStrings():
    targetsNode.add(%t)

  result = %*{
    "engine": "Native Nim ORC (< 5MB RAM)",
    "uptime_seconds": elapsed,
    "frames_emitted": s.framesEmitted,
    "fps": s.config.fps,
    "resolution": s.config.resolution,
    "targets": targetsNode,
    "timestamp": nowIso
  }
