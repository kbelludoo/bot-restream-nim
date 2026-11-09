import std/[os, json]

type
  TargetConfig* = object
    name*: string
    url*: string
    key*: string
    enabled*: bool

  RestreamConfig* = object
    ingestPort*: int
    webPort*: int
    targets*: seq[TargetConfig]
    radioUrl*: string
    fps*: int
    resolution*: string

proc defaultRestreamConfig*(): RestreamConfig =
  result.ingestPort = 1935
  result.webPort = 3011
  result.targets = @[
    TargetConfig(
      name: "Twitch",
      url: "rtmp://live.twitch.tv/app",
      key: "live_21107325_YimOnx0kdCUXwTxLJA0Gx6aXgHiMXE",
      enabled: true
    ),
    TargetConfig(
      name: "Kick",
      url: "rtmps://fa723fc1b171.global-contribute.live-video.net/app",
      key: "sk_us-west-2_B4TGW0mCmcpr_ljDLFlMEshyWortcD8KnheaC7zpzyw",
      enabled: true
    ),
    TargetConfig(
      name: "YouTube",
      url: "rtmp://a.rtmp.youtube.com/live2",
      key: "5fst-9b20-k652-g8mg-10p0",
      enabled: true
    )
  ]
  result.radioUrl = "https://radio.plaza.one/mp3"
  result.fps = 10
  result.resolution = "720p"

proc loadConfig*(path: string): RestreamConfig =
  result = defaultRestreamConfig()
  if fileExists(path):
    try:
      let txt = readFile(path)
      let j = parseJson(txt)
      if j.hasKey("settings"):
        let s = j["settings"]
        if s.hasKey("webDashboardPort"):
          let p = s["webDashboardPort"].getInt(3011)
          result.webPort = if p == 3008: 3011 else: p
      if j.hasKey("ingest") and j["ingest"].hasKey("port"):
        result.ingestPort = j["ingest"]["port"].getInt(1935)
      if j.hasKey("targets") and j["targets"].kind == JArray:
        result.targets = @[]
        for item in j["targets"]:
          result.targets.add(TargetConfig(
            name: item{"name"}.getStr("Target"),
            url: item{"url"}.getStr(""),
            key: item{"key"}.getStr(""),
            enabled: item{"enabled"}.getBool(false)
          ))
      if j.hasKey("fps"): result.fps = j["fps"].getInt(10)
      if j.hasKey("resolution"): result.resolution = j["resolution"].getStr("720p")
      if j.hasKey("radio_url"): result.radioUrl = j["radio_url"].getStr(result.radioUrl)
    except CatchableError as e:
      echo "⚠️ Erro ao analisar ", path, ": ", e.msg
