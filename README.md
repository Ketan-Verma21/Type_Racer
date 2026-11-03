<div align="center">

# 🏎️ Type Racer

**A real-time multiplayer typing race with game modes, live stats, spectators, chat and a neon-arcade UI.**

Built with **Flutter** · **TypeScript** · **Socket.IO** · **Redis** · **Docker**

[![Codemagic build status](https://api.codemagic.io/apps/6abe03331a2d91e04c85b4ea/6abe03331a2d91e04c85b4e9/status_badge.svg)](https://codemagic.io/apps/6abe03331a2d91e04c85b4ea/6abe03331a2d91e04c85b4e9/latest_build)

<a href="https://buymeacoffee.com/vrm_ketan" target="_blank">
  <img src="https://img.buymeacoffee.com/button-api/?text=Buy me a coffee&emoji=☕&slug=vrm_ketan&button_colour=FFDD00&font_colour=000000&font_family=Cookie&outline_colour=000000&coffee_colour=ffffff" alt="Buy Me A Coffee" height="48" />
</a>

</div>

---

## 📖 About

Create a room, share the code, and race your friends to type the same quote the fastest. Every keystroke is validated on the server, so everyone sees the same live race: cars slide down their lanes as you type, WPM updates every second, and the winner gets confetti.

## 🎬 Demo

[![Watch the demo](https://img.youtube.com/vi/h-L4iLzStZU/hqdefault.jpg)](https://youtu.be/h-L4iLzStZU)

## ✨ Features

### Gameplay
- **Real-time multiplayer** – up to 8 players per room, synced through Socket.IO.
- **Live race track** – every player has a lane and a car that moves as they type.
- **Live WPM and accuracy** – updated every second during the race.
- **Per-letter feedback** – correct letters turn green, mistakes turn red, the input box shakes on a wrong letter.
- **Three game modes**
  | Mode | Rule |
  |---|---|
  | 🏁 **Classic** | Wrong words are ignored. Fastest typist wins. |
  | 🎯 **Flawless** | A wrong word sends you back to the start. |
  | 💀 **Sudden Death** | One wrong word and you're out. First to finish, or last one standing, wins. |
- **Host settings** – mode, time limit (30–120 s), quote length (short / medium / long) and max players.
- **Spectator mode** – join a race that already started and watch it live; you join as a player on the next round.
- **Rematch** – the host starts another round in the same room.

### Social
- **Lobby chat** and **emoji reactions** that float across everyone's screen.
- **Ranked scoreboard** with medals, winner banner and WPM.

### Polish
- **Neon-arcade UI** – animated background, glowing buttons, countdown pop, entrance animations.
- **Winner celebration** – confetti, sound effects and haptic feedback (with a mute button).
- **Resilient connections** – a dropped player has 15 seconds to reconnect and keep their place; leaving players are removed cleanly and the host role is passed on.

<<<<<<< HEAD
## 🖼️ Demo Video
[![Watch the demo](https://img.youtube.com/vi/h-L4iLzStZU/hqdefault.jpg)](https://youtu.be/h-L4iLzStZU)
=======
### Under the hood
- **Server-authoritative** – the app only sends typed words; the server checks every word, runs the clock and computes WPM, so scores can't be faked.
- **Runs on several servers at once** – two game servers share one Redis: players on different servers race in the same room, and **a race keeps going even if the server that started it crashes**.
- **Redis as the datastore** – Lua scripts make "take the last seat" atomic, rooms clean themselves up after 2 hours, and there's a leaderboard and match history.
- **Tested** – 280+ server tests, including contract tests that every storage adapter (in-memory and Redis) must pass, and end-to-end tests with real sockets and two real servers.

## 🧱 Tech Stack

| Layer | Technology |
|---|---|
| App | Flutter, Provider, socket_io_client 3, flutter_animate, google_fonts, confetti, audioplayers |
| Server | TypeScript (strict), Node.js 20, Express, Socket.IO 4 + Redis adapter, zod, pino |
| Data | Redis (games, sessions, race clock, leaderboard, pub/sub between servers) |
| Quotes | [API Ninjas Quotes API](https://api-ninjas.com/api/quotes), with 108 bundled quotes as a fallback |
| Infra | Docker + Docker Compose (two game servers + Redis) |
| Tests | Vitest (server), flutter_test (app) |

## 🏗️ Architecture

```
 Flutter app (player A) ──┐                       ┌── Flutter app (player B)
                          │ Socket.IO             │ Socket.IO
                          ▼                       ▼
                 ┌──────────────────┐   ┌──────────────────┐
                 │  game server 1   │   │  game server 2   │   same code, same image
                 │  (app1 :3000)    │   │  (app2 :3001)    │
                 └────────┬─────────┘   └─────────┬────────┘
                          └───────────┬───────────┘
                                      ▼
                         ┌────────────────────────┐
                         │         Redis          │  games · sessions · race clock ·
                         │                        │  leaderboard · pub/sub between servers
                         └────────────────────────┘
```

The **server owns the game**. The app sends intent (create, join, start, typed a word) and renders the state the server broadcasts (`updateGame`, `timer`). Red/green letter feedback in the app is only a visual hint; whether a word is correct is always decided by the server.

The server is its own repository — **[Ketan-Verma21/TypeRacerServer](https://github.com/Ketan-Verma21/TypeRacerServer)** — with its own README covering its design (SOLID, ports and adapters), the Redis data model, the socket events and the tests.

### Folder structure (app)

```
type_racer/                      # Flutter project (this repo)
├── lib/
│   ├── main.dart
│   ├── theme/                   # colour palette + theme
│   ├── screens/                 # home, create room, join room, game
│   ├── widgets/                 # race lane, scoreboard, chat, settings, buttons...
│   ├── providers/               # game state, client state, chat
│   ├── models/                  # GameState
│   └── utils/                   # socket client/methods, room codes, sounds, helpers
├── assets/sounds/               # sound effects
├── test/unit/                   # unit tests
└── server/                      # the TypeRacerServer repo, cloned here (ignored by this repo)
```

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) and Chrome (for the web build)
- [Docker Engine](https://docs.docker.com/engine/install/) with the Compose plugin — **or** Node.js 20 and npm
- Optional: a free [API Ninjas](https://api-ninjas.com/) key. Without one the server uses its 108 bundled quotes.

### 1. Clone
The server is its own repo, cloned inside the app folder (the app repo ignores `server/`):
```bash
git clone https://github.com/Ketan-Verma21/Type_Racer.git type_racer
cd type_racer
git clone https://github.com/Ketan-Verma21/TypeRacerServer.git server
cp server/.env.example server/.env   # fill in API_KEY if you have one
```

### 2. Start the server

#### Run with Docker (recommended)
One command starts two game servers (`app1` on port 3000, `app2` on 3001) and Redis:
```bash
cd server
docker compose up --build -d   # build the image and start in the background
docker compose ps              # all three services should say (healthy)
docker compose logs -f app1 app2   # follow both servers' logs (JSON)
docker compose down            # stop; Redis data stays in the redis-data volume
```
The server listens on `http://localhost:3000` (`/health`, `/health/live`, `/health/ready`).
Redis is only reachable from this machine (`127.0.0.1:6379`). Rebuild with `--build` after changing server code.

#### Run with Node (for development)
```bash
cd server
npm ci
npm run dev        # auto-restarts on changes (STORE=memory by default)
npm test           # unit + contract tests (Vitest), no Docker needed
```

With Redis running (`docker compose up -d redis`), the same contract tests and a latency benchmark can run against the real thing. They use database 15 and wipe it:
```bash
REDIS_TEST_URL=redis://localhost:6379/15 npm run test:redis
REDIS_TEST_URL=redis://localhost:6379/15 npm run bench:redis
```

### 3. Run the app
Point the app at your server with `SERVER_URL` (default: the hosted server):
```bash
flutter pub get
flutter run -d chrome --dart-define=SERVER_URL=http://localhost:3000
```
On a phone, use your computer's LAN IP instead of `localhost`.

Open the app in two tabs (or devices), create a room in one, and join with the 6-character code in the other.

To see two servers working together, run a second copy against the other server:
```bash
flutter run -d chrome --web-port 5002 --dart-define=SERVER_URL=http://localhost:3001
```

## 🔌 Socket Events

| Event | Direction | Purpose |
|---|---|---|
| `create-game` / `join-game` | client → server | Create a room / join it (as a spectator if it already started) |
| `update-settings` | client → server | Host changes mode, time, length, max players |
| `timer` | client → server | Host starts the countdown |
| `userInput` | client → server | A typed word |
| `rematch` | client → server | Host starts another round |
| `chat-message` / `reaction` | both | Lobby chat and emoji reactions |
| `leave-game` / `rejoin-game` | client → server | Leave, or reattach after a reconnect |
| `updateGame` | server → client | Full game state, broadcast on every change |
| `timer` | server → client | Countdown and remaining time |
| `joined` | server → client | Who this device is (`gameId`, `playerId`) after create / join / rejoin |
| `error-message` / `notCorrectGame` | server → client | Errors, e.g. invalid code or room full |
| `get-leaderboard` / `leaderboard` | both | Top 10 players for a game mode |

The full list, with payloads, is in the [server README](https://github.com/Ketan-Verma21/TypeRacerServer#-socket-events).

## 🗺️ Roadmap

- [x] TypeScript server with SOLID design, input validation and structured logs
- [x] Unit, contract and end-to-end tests
- [x] Dockerised server (Docker Compose)
- [x] Redis as the datastore, leaderboard and match history (server side)
- [x] Several game servers at once (Socket.IO Redis adapter, race clock in Redis)
- [ ] Nginx load balancer + load testing
- [ ] Kafka for post-race events (stats, anti-cheat)
- [x] CI for the app: Codemagic builds the Flutter web app
- [ ] CI for the server: GitHub Actions running the tests on every push
- [ ] Leaderboard screen in the app
- [ ] Login and player profiles
- [ ] Power-ups

## 🤝 Contributing

Contributions are welcome!

1. Fork the repository
2. Create a branch: `git checkout -b feature/your-feature-name`
3. Commit your changes: `git commit -m "Add some feature"`
4. Push the branch: `git push origin feature/your-feature-name`
5. Open a Pull Request

## ☕ Support

If you enjoy the project, you can support me here:

<a href="https://buymeacoffee.com/vrm_ketan" target="_blank">
  <img src="https://img.buymeacoffee.com/button-api/?text=Buy me a coffee&emoji=☕&slug=vrm_ketan&button_colour=FFDD00&font_colour=000000&font_family=Cookie&outline_colour=000000&coffee_colour=ffffff" alt="Buy Me A Coffee" height="48" />
</a>

## 📬 Contact

- **Email:** try.vrmketan@gmail.com
- **GitHub:** [Ketan-Verma21](https://github.com/Ketan-Verma21)
- **Buy Me a Coffee:** [buymeacoffee.com/vrm_ketan](https://buymeacoffee.com/vrm_ketan)
