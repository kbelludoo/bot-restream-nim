# bot-restream-nim ⚡

Ultra-Low RAM Stream HUD & RTMP Fan-out Relay reescrito em **Nim 2.2** com 100% de paridade com Go e Rust.

## Recursos
- **Fan-out RTMP Paralelo:** Transmissão simultânea de baixa latência para Twitch, Kick e YouTube via FFmpeg nativo.
- **Micro-Consumo de Memória:** Execução completa em < 5MB de RAM com gerenciamento ORC (`--mm:orc`).
- **Telemetria HTTP na Porta 3011:** Endpoints `/api/status`, `/status.json` e `/api/telemetry` com paridade 100%.

## Compilação Cruzada (Linux x86_64 via Zig)
```powershell
nim c --os:linux --cpu:amd64 --gcc.exe:zigcc-linux-gnu.bat --gcc.linkerexe:zigcc-linux-gnu.bat -d:ssl -d:release -o:restream-nim-linux main.nim
```
