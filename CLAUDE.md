# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Supported Devices

| Device dir | Yocto MACHINE(s) | SOC_FAMILY override |
|---|---|---|
| `devices/am335x` | `am335x-evm` | *(none — explicit machine name)* |
| `devices/am62xx` | `am62xx-evm`, `am62xxsip-evm`, `am62xx-lp-evm` | `am62xx` |
| `devices/am62pxx` | `am62pxx-evm` | `am62pxx` |
| `devices/am62lxx` | `am62lxx-evm` | `am62lxx` |
| `devices/am62dxx` | `am62dxx-evm` | `am62dxx` |

## Build

```bash
# Node.js server deps
cd common/webserver && npm install

# Native C utilities (cross-compile for target board)
make -C common/linux_app CC=<cross-gcc>             # cpu_stats
make -C devices/<device>/linux_app CC=<cross-gcc>   # audio_utils

# Submodule (GUI Composer components — requires git.ti.com access)
git submodule update --init --recursive
```

## Running

```bash
# Local dev — MOCK=1 skips native binary calls
make dev DEVICE=am335x MOCK=1
make dev DEVICE=am62xx MOCK=1

# Deploy to board
make deploy DEVICE=am62xx BOARD_HOST=root@<ip>
```

Server runs on port 3000. If port is in use: `fuser -k 3000/tcp`.
TI corporate McAfee proxy intercepts localhost curl — add `--noproxy localhost`.

## Architecture

### Directory layout

```
common/
  webserver/         Express server + plugin loader (server.js)
  app/               Generic frontend (index.html, main.js)
    components/      git submodule — ti-gc-components (git.ti.com)
  linux_app/         Shared C utilities: cpu_stats.c, Makefile.common

demos/
  cpu-monitor/       server-plugin.js + manifest.json
  audio-classification/  server-plugin.js + manifest.json

devices/<id>/
  device.json        Device metadata, demo list, per-demo config
  app/images/        Board photos (device-specific overlay)
  linux_app/         Makefile → builds audio_utils from common/linux_app/audio_utils.c

yocto/
  webserver-oob_git.bb      Single Yocto recipe, all devices via COMPATIBLE_MACHINE
  webserver-oob-npm.inc     Auto-generated (tools/generate-inc.js), commit alongside package.json changes
```

### Plugin system

`server.js` reads `device.json`, loads each demo's `server-plugin.js` at startup:
```js
module.exports = function register(app, wss, device) { ... }
```
- `app` — Express instance
- `wss` — WebSocket server
- `device` — parsed `device.json`; access `device.demoConfig['<id>']` for tuning params
- Always export a single function, always support `MOCK=1`
- `WS_OPEN = 1` — `WebSocket.OPEN` is spec constant 1; plugins must NOT `require('ws')` directly

### Audio classification data flow

1. Frontend: `GET /start-audio-classification?device=plughw:X,Y`
2. Server spawns `/usr/bin/audio_utils start_gst <device>`
3. GStreamer pipeline writes class labels to `/tmp/audio_classification_fifo`
4. `common/webserver/lib/fifo-reader.js` (child process) reads FIFO, sends JSON on stdout
5. Parent broadcasts `{class, timestamp}` to WebSocket clients on `/audio`

### REST endpoints

| Endpoint | Backend |
|---|---|
| `GET /device-info` | serves `device.json` content |
| `GET /cpu-load` | `/usr/bin/cpu_stats enhanced` |
| `GET /cpu-info` | `/usr/bin/cpu_stats info` |
| `GET /audio-devices` | `/usr/bin/audio_utils devices` |
| `GET /start-audio-classification?device=` | spawns `audio_utils start_gst` + FIFO reader |
| `GET /stop-audio-classification` | kills processes, pkill gst-launch |

### WebSocket

`ws://<host>:3000/audio` — receives `{class, timestamp}`. Supports `diagnostic_ping` → `diagnostic_response`.

## Adding a device

See `docs/adding-a-device.md`.

## Adding a demo

See `docs/adding-a-demo.md`.

## Yocto

Recipe: `yocto/webserver-oob_git.bb` → copy to `meta-ti-foundational/recipes-demos/webserver-oob/`.
npm inc: regenerate with `node tools/generate-inc.js` after any `package.json` change.
Yocto recipes dir: `/media/jeevan/MYDISK2/tisdk/sources/meta-tisdk/meta-ti-foundational/recipes-demos/`
