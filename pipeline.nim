import std/[osproc, streams, strutils, asyncdispatch]
import config, telemetry

const FrameWidth = 1280
const FrameHeight = 720
const FrameSize = FrameWidth * FrameHeight * 4

proc runPipeline*(state: TelemetryState) {.async.} =
  let cfg = state.config

  var teeTargets: seq[string] = @[]
  for t in cfg.targets:
    if t.enabled:
      teeTargets.add("[f=flv:onfail=ignore:flvflags=no_duration_filesize]" & t.url & "/" & t.key)

  if teeTargets.len == 0:
    echo "⚠️ Nenhum destino RTMP ativo habilitado em config."
    return

  let teeDest = teeTargets.join("|")
  let intervalMs = if cfg.fps > 0: 1000 div cfg.fps else: 100

  # Frame de fundo escuro RGBA (12, 12, 12, 255)
  var frameBuffer = newString(FrameSize)
  for i in 0 ..< FrameSize div 4:
    let idx = i * 4
    frameBuffer[idx] = chr(12)
    frameBuffer[idx + 1] = chr(12)
    frameBuffer[idx + 2] = chr(12)
    frameBuffer[idx + 3] = chr(255)

  while true:
    echo "[Stream] Disparando pipeline nativo FFmpeg para os destinos RTMP..."
    var process: Process
    try:
      let args = [
        "-hide_banner",
        "-loglevel", "warning",
        "-filter_threads", "1",
        "-thread_queue_size", "2",
        "-f", "rawvideo",
        "-pix_fmt", "rgba",
        "-video_size", "1280x720",
        "-framerate", $cfg.fps,
        "-i", "pipe:0",
        "-thread_queue_size", "32",
        "-probesize", "32k",
        "-analyzeduration", "0",
        "-reconnect", "1",
        "-reconnect_at_eof", "1",
        "-reconnect_streamed", "1",
        "-reconnect_delay_max", "5",
        "-i", cfg.radioUrl,
        "-c:v", "libx264",
        "-preset", "ultrafast",
        "-tune", "zerolatency",
        "-threads", "1",
        "-b:v", "1200k",
        "-maxrate", "1200k",
        "-bufsize", "2400k",
        "-pix_fmt", "yuv420p",
        "-g", "20",
        "-keyint_min", "10",
        "-sc_threshold", "0",
        "-c:a", "aac",
        "-b:a", "128k",
        "-ar", "44100",
        "-af", "aresample=async=1000,volume=0.8",
        "-flags", "+global_header",
        "-f", "tee",
        "-map", "0:v",
        "-map", "1:a",
        teeDest
      ]

      process = startProcess(
        "ffmpeg",
        args = args,
        options = {poUsePath, poStdErrToStdOut}
      )

      while process.running:
        try:
          process.inputStream.write(frameBuffer)
          process.inputStream.flush()
          state.framesEmitted.inc()
        except CatchableError:
          break

        await sleepAsync(intervalMs)

      echo "[Stream] FFmpeg finalizado. Reiniciando em 2s..."
      process.close()
    except CatchableError as e:
      echo "[Stream] Erro ao iniciar ffmpeg: ", e.msg, ". Tentando em 5s..."
      if process != nil:
        try: process.close() except CatchableError: discard
      await sleepAsync(5000)
      continue

    await sleepAsync(2000)
