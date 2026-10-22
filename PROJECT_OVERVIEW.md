# Type Racer — Project Overview

> Internal technical reference for the whole codebase (Flutter app + Node server).
> The public-facing description lives in `README.md`; this file explains **how the code actually works**, file by file, and lists known issues.

---

## 1. What it is

A real-time multiplayer typing race. A host creates a room, shares the room code (a MongoDB ObjectId), up to 8 players join and race to type the same quote. The **server is authoritative**: it validates every submitted word, owns the timers and broadcasts the full game state to everyone in the room.

| Part | Tech | Where |
|---|---|---|
| Client | Flutter (Dart ≥ 3.1.2), Provider, socket_io_client 1.x | `lib/` |
| Server | Node.js, Express 4, Socket.IO **2.x**, Mongoose 8 | `server/` |
| Database | MongoDB (Atlas) — one `Game` document per room | `server/Models/Game.js` |
| Quotes | API Ninjas Quotes API (`API_URL`, `API_KEY` in `.env`) | `server/api/getSentence.js` |
| Server hosting | Render free tier — `https://typ-racer-server.onrender.com` | `lib/utils/socket_client.dart` |
| Web hosting | Firebase Hosting, project `typeracer-12405`, serves `build/web` | `firebase.json`, `.firebaserc` |
| Crash reporting | Sentry (`sentry_flutter`), DSN hard-coded in `main.dart` | `lib/main.dart`, `sentry.properties` |

Git: the root repo is `Ketan-Verma21/Type_Racer`; `server/` is its **own** git repo (`Ketan-Verma21/TypeRacerServer`) nested inside the folder.

---

## 2. Repository layout

```
type_racer/
├── lib/                         Flutter app (~3.2k lines)
│   ├── main.dart                Sentry init, MultiProvider, routes
│   ├── models/                  GameState, ClientState
│   ├── providers/               GameState, ClientState (timer), Chat, ServerStatus
│   ├── screens/                 home, create_room, join_room, game (726 lines)
│   ├── widgets/                 race lane, sentence card, input box, scoreboard, chat...
│   ├── theme/                   AppColors (neon palette), AppTheme (Orbitron + Rajdhani)
│   └── utils/                   socket client/methods, game modes, player helpers, sound, stats
├── assets/sounds/               beep, go, tick, error, out, win, lose (.wav)
├── server/                      Node backend (~580 lines, separate git repo)
│   ├── index.js                 Express + Socket.IO + Mongo bootstrap, /health
│   ├── config/constants.js      modes, limits, timings
│   ├── sockets/                 event handlers (parse → call service → emit)
│   ├── services/                game rules, timers, chat history, reconnect grace
│   ├── Models/                  Game.js (used), Player.js (unused legacy)
│   ├── api/getSentence.js       quote fetching
│   └── utils/                   helpers (time, WPM, name), io singleton
├── android/ ios/ web/ windows/ macos/ linux/   Flutter platform shells (mostly default)
├── test/widget_test.dart        default Flutter counter test (stale)
├── firebase.json / .firebaserc  web hosting
├── sentry.properties            Sentry auth token (git-ignored)
└── sentry-wizard.exe            88 MB Sentry setup binary (git-ignored)
```

---

## 3. Architecture & data flow

```
 Flutter app                                         Node server
┌───────────────────────────┐   Socket.IO (ws)   ┌───────────────────────────────┐
│ Screens / Widgets         │◄──────────────────►│ sockets/*Handlers  (thin)     │
│   ▲ Provider.watch        │                    │   ▼                           │
│ Providers (ChangeNotifier)│   HTTP GET /health │ services/  gameService (rules)│
│   ▲ updateGameState(...)  │──────────────────► │            timerService       │
│ SocketMethods (emit/on)   │                    │            chatService (mem)  │
│ SocketClient (singleton)  │                    │            reconnectService   │
└───────────────────────────┘                    │ MongoDB    Game documents     │
                                                 │ api/       API Ninjas quotes  │
                                                 └───────────────────────────────┘
```

- The client sends **intent** (`create-game`, `join-game`, `timer`, `userInput`, …).
- The server mutates the `Game` document, saves it and emits **`updateGame`** with the whole document to the room (`io.to(gameId)`).
- The client replaces its `GameState` wholesale on every `updateGame`; all UI derives from it.
- Timers run only on the server and are pushed via the `timer` event as `{countDown, msg}`.
- Client-side red/green letter feedback is cosmetic; correctness is decided by `gameService.processWord`.

---

## 4. Game lifecycle (state machine)

The `Game` document's flags define the phase:

| Phase | `isJoin` | `isOver` | `startTime` | Client view |
|---|---|---|---|---|
| Lobby | `true` | `false` | unset | `_lobbyView` (settings, players, chat, Start button) |
| Countdown (5→0) | `true` | `false` | unset | lobby + big countdown, `msg = "Game Starting"` |
| Racing | `false` | `false` | set | `_raceView` (sentence, stats, lanes, input) |
| Finished (me) | `false` | `false` | set | `_resultsView` with "Waiting for others…" |
| Over | `false` | `true` | set | `_resultsView` with winner, Play Again (host) |
| Rematch | back to Lobby | | cleared | |

Spectators (joined after start) and eliminated players get `_watchView`.

**Sequence:**
1. `create-game` → `gameService.createGame` fetches a quote, creates the doc with the creator as `isPartyLeader`.
2. `join-game` → validates 24-hex id; lobby → racer (if under `maxPlayers`), otherwise → spectator.
3. Host `update-settings` (lobby only, not while timers run). Changing `length` refetches the quote.
4. Host `timer` → `timerService.startCountdown`: emits 5..0 each second, sets `isJoin=false`, then `startClock` sets `startTime` and emits `m:ss` remaining every second.
5. Each word + space → `userInput`. Correct → `currentWordIndex++`; finishing sets the player's `WPM`. Wrong → depends on mode.
6. Race ends when `shouldEnd(game)` is true or the clock hits 0 → `endGame` fills WPM for unfinished racers, sets `isOver=true`, emits `updateGame` + `done`.
7. Host `rematch` → new quote, reset all players, promote spectators into free slots, back to lobby.

### Game modes (`config/constants.js` `MODES`)

| id | UI name | Wrong word | Race ends when |
|---|---|---|---|
| `classic` | 🏁 Classic | ignored | all racers finished / out, or time up |
| `no-mistakes` | 🎯 Flawless | `currentWordIndex = 0` | same as classic |
| `sudden-death` | 💀 Sudden Death | `isEliminated = true`, WPM frozen | first finisher, last one standing (≥2 racers), all done, or time up |

### Ranking (`lib/utils/player_utils.dart › rankPlayers`)
Non-eliminated first → finished before unfinished → higher WPM first. Winner = rank 1.

### WPM
- Server (`utils/helpers.calculateWPM`): `floor(wordsCompleted / minutesSinceStart)` — **words**, not the standard 5-chars-per-word.
- Client live WPM (`game_screen.dart`): uses server WPM if set (≥0), otherwise `currentWordIndex / (elapsed/60)` where `elapsed` is derived from the server's `m:ss` string; shown as 0 for the first 3 s.
- Accuracy (`utils/typing_stats.dart`): local only, `(keys − wrongKeys) / keys`.

---

## 5. Server reference (`server/`)

### Environment (`server/.env`, git-ignored)
```
PORT=3000
MONGO_URL=<mongodb connection string>
API_URL=https://api.api-ninjas.com/v2/quotes
API_KEY=<api ninjas key>
```
Scripts: `npm start` (`node ./index.js`), `npm run dev` (nodemon).

### `index.js`
Creates Express + HTTP server + Socket.IO 2, registers handlers, connects Mongo, listens on `0.0.0.0:PORT`.
- `GET /health` → `{ ok: true, db: <mongo connected>, uptime }` with CORS `*` (used by the app to wake Render).
- `GET /` → plain text "Type Racer server is running".

### `config/constants.js`
| Constant | Value |
|---|---|
| `RECONNECT_GRACE_MS` | 15000 |
| `COUNTDOWN_SECONDS` | 5 |
| `MODES` | classic, no-mistakes, sudden-death |
| `TIME_LIMITS` | 30, 60, 90, 120 |
| `LENGTH_WORDS` | short 12, medium 25, long 45 |
| `REACTIONS` | 😂 🔥 👏 😮 💀 ❤️ |
| `MAX_PLAYERS_LIMIT` | 8 |
| `CHAT_HISTORY_SIZE` | 30 |
| `CHAT_MAX_LENGTH` | 140 |

### `Models/Game.js` (Mongoose)
```
Game {
  words: [String]
  players: [Player]
  isJoin: Boolean = true      // lobby
  isOver: Boolean = false
  startTime: Number           // ms epoch, set when the clock starts
  settings: { mode='classic', timeLimit=120, length='medium', maxPlayers=5 }
}
Player (subdocument, has _id) {
  currentWordIndex=0, socketID, isPartyLeader=false, WPM=-1, nickname,
  isSpectator=false, isEliminated=false, mistakes=0
}
```
`Models/Player.js` is an old standalone schema and is not imported anywhere.

### `sockets/` — one `session` object per connection
`sockets/index.js` creates `{ gameId, playerId, nickname, lastChatAt, lastReactionAt }` per socket and passes it to all three handler files.

- **gameHandlers.js** — `create-game`, `join-game`, `update-settings`, `timer` (host check via `playerId`), `userInput` (emits `done` to the finisher), `rematch`.
- **chatHandlers.js** — `chat-message` (500 ms rate limit, trimmed to 140 chars), `chat-sync` → `chat-history`, `reaction` (200 ms rate limit, whitelist only).
- **connectionHandlers.js** — `leave-game` (immediate removal), `disconnect` (schedules removal after 15 s), `rejoin-game` (reattaches a new socket id to the existing player and cancels removal).

### `services/`
- **gameService.js** — all rules: `shouldEnd`, `createGame`, `joinGame`, `applySettings` (validates every field against constants; `maxPlayers` clamped to [current racers, 8]), `processWord`, `endGame`, `rematch`, `removePlayer` (deletes the game when empty, passes host role to the next racer, may end the race), `reattachPlayer`.
- **timerService.js** — in-memory `Map<gameId, {countdown, clock}>` of intervals; `hasTimers` doubles as the "race is starting/running" lock.
- **chatService.js** — in-memory `Map<gameId, messages[]>` (last 30).
- **reconnectService.js** — in-memory `Map<playerId, timeout>`.

### `api/getSentence.js`
GETs `API_URL` with `X-Api-Key`, takes `res.data[0].quote`, splits on whitespace → `string[]`.

### `utils/`
`helpers.js` — `calculateTime` (→ `m:ss`), `calculateWPM`, `cleanName` (trim, max 16 chars). `io.js` — module-level `io` singleton (`setIO`/`getIO`).

---

## 6. Socket event contract

| Event | Direction | Payload | Notes |
|---|---|---|---|
| `create-game` | C→S | `{nickname}` | |
| `join-game` | C→S | `{nickname, gameId}` | gameId must be 24-hex |
| `update-settings` | C→S | `{gameId, settings:{mode,timeLimit,length,maxPlayers}}` | host, lobby only |
| `timer` | C→S | `{playerId, gameId}` | host starts countdown |
| `userInput` | C→S | `{userInput, gameId}` | one word + trailing space |
| `rematch` | C→S | `{gameId}` | host, after `isOver` |
| `chat-message` | C→S / S→C | `{gameId, text}` / `{playerId, nickname, text, ts}` | |
| `chat-sync` | C→S | `{gameId}` | server replies `chat-history` (array) |
| `reaction` | C→S / S→C | `{gameId, emoji}` / `{id, nickname, emoji}` | |
| `leave-game` | C→S | `{gameId}` | |
| `rejoin-game` | C→S | `{gameId, playerId}` | sent on every reconnect while in a game |
| `updateGame` | S→C | full `Game` document | broadcast on every change |
| `timer` | S→C | `{countDown, msg}` | `msg` ∈ "Game Starting", "Time Remaining", "Waiting for players" |
| `done` | S→C | — | to finisher, and to the room on game end (client listener is a no-op) |
| `notCorrectGame` | S→C | error string | shown as a snackbar |

---

## 7. Flutter app reference (`lib/`)

### Entry — `main.dart`
`SentryFlutter.init` (traces/profiles sample rate 1.0, `sendDefaultPii: true`) → `MultiProvider` with 4 providers → `MaterialApp` (dark `AppTheme`, title `'Slim Shady'`) with named routes:
`/` Home · `/create-room` · `/join-room` · `/game-screen`.

### State — `providers/` & `models/`
| Provider | Holds | Updated by |
|---|---|---|
| `GameStateProvider` | `GameState{id, players, isJoin, isOver, words, settings}` (players are raw JSON maps) | `updateGame` listener |
| `ClientStateProvider` | `ClientState{timer:{countDown,msg}}` | `timer` listener |
| `ChatProvider` | `messages` (max 50), `reactions` (auto-removed after 2.6 s) | chat listeners |
| `ServerStatusProvider` | `ServerState` checking → waking → ready / failed | pings `/health` every 3 s, up to 4 min; considered stale after 8 min |

### Networking — `utils/socket_client.dart`, `utils/socket_methods.dart`
- `SocketClient` — app-wide singleton, websocket transport, `autoConnect:false` then connects immediately, aggressive reconnection (100 000 attempts, 2–10 s back-off). `kServerUrl` is the Render URL.
- `SocketMethods` — new instance per screen/widget; wraps every emit and listener. Listeners always `off()` before `on()` so they don't stack, and capture providers/navigator up front instead of using `context` inside callbacks. `_whenConnected` queues Create/Join until the socket is connected. `rejoinOnReconnect` registers a `connect` handler that sends `rejoin-game`. `leaveGame` emits leave and removes all game listeners.
- Identifying "me": `findMe(players)` matches `socketID == socket.id`.

### Screens
- **HomeScreen** — animated title, `ServerStatusBanner`, Create/Join buttons disabled until the server is ready; re-checks on app resume.
- **CreateRoomScreen** — nickname → `CreateGame`; `updateGameListener` navigates to `/game-screen` on first `updateGame`.
- **JoinRoomScreen** — nickname + game id → `JoinGame`; errors via `notCorrectGame` snackbar.
- **GameScreen** — the whole game in one screen; `build()` picks one of four views (results / watch / lobby / race) from the state. Listens for changes to play sounds, haptics, banners ("Wrong word!", "You're OUT!"), confetti for the winner, and resets local state on rematch. Leave button → confirm dialog → `_goHome` (leave, pop to root, reset providers).

### Widgets
| Widget | Purpose |
|---|---|
| `SentenceGame` | quote card: done words green, current word letter-by-letter (green/red/cyan cursor), overflow struck-through, rest muted |
| `GameTextField` | input; on space sends the word to the server and clears; shakes + error sound on a wrong prefix; records accuracy |
| `RaceLane` | per-player lane with animated car 🏎️, trail, %, WPM, 👑 host, 💥/OUT when eliminated |
| `StatsBar` | WPM · Accuracy · Words done · Mode |
| `Scoreboard` | ranked list with medals, winner title |
| `SettingsPanel` | host chips for mode/time/length/max players; read-only chips for others |
| `ChatPanel`, `ReactionBar`, `ReactionOverlay` | lobby chat, emoji buttons, floating emojis |
| `ServerStatusBanner` | waking / online / failed + Retry |
| `GameBackground` | gradient + scrolling neon grid + glows, wraps every screen |
| `CustomButton`, `CustomTextfield`, `MyBackButton` | styled primitives |

### Theme
`AppColors`: bg `#0B0F1E`, surface `#141B33`, cyan `#00E5FF` (primary), magenta `#FF2E93`, yellow `#FFD60A`, green `#39FF88`, red `#FF4D5E`; 5 lane colours. `AppTheme`: Orbitron for display text, Rajdhani for body, JetBrains Mono for the quote/input.

### Utilities
`game_modes.dart` (mode metadata, times, lengths — mirrors server constants), `player_utils.dart` (`findMe`, `racersOf`, `wpmOf`, `rankPlayers`, `elapsedSeconds`), `sound_service.dart` (low-latency `audioplayers`, global mute `ValueNotifier`), `typing_stats.dart`.

---

## 8. Dependencies

**Flutter (used):** provider, socket_io_client ^1.0.2, http, google_fonts, flutter_animate, confetti, audioplayers, awesome_snackbar_content, flutter_spinkit, loader_overlay, sentry_flutter.
**Flutter (declared but not imported in `lib/`):** neopop, firebase_core, feedback_sentry, shorebird_code_push, cupertino_icons. Dev: sentry_dart_plugin, flutter_lints.
**Server:** express, socket.io ^2.3.0, mongoose ^8, axios, dotenv, `http` (npm placeholder package — unnecessary, Node's built-in `http` is what's used). Dev: nodemon.

> socket_io_client 1.x speaks the Socket.IO v2 protocol, which is why the server is pinned to socket.io 2.x. Upgrading one side requires upgrading the other (client 2.x/3.x ↔ server 3.x/4.x).

---

## 9. Running locally

```bash
# server
cd server && npm install
# create server/.env (see section 5)
npm run dev

# app — point kServerUrl in lib/utils/socket_client.dart at your server
# (use the LAN IP, not localhost, on a phone)
flutter pub get
flutter run            # or: flutter run -d chrome

# deploy web
flutter build web && firebase deploy
```

---

## 10. Known issues & observations

Found while reading the code — none of these have been changed.

**Bugs / behaviour that doesn't match the README**
1. **Quote length setting has no effect.** `getSentence(LENGTH_WORDS[...])` is called with a word count but `getSentence` takes no parameters and always returns a single API quote.
2. **No offline fallback quote.** The README mentions one, but if the API call fails `createGame` throws, the error is only logged and the client gets no response (spinner/screen just waits).
3. **Create button spinner** is set to `true` and immediately back to `false` in the same tap handler, so it never shows.
4. **`test/widget_test.dart`** is the default counter test and will fail (and `MyApp` now needs Sentry/providers).
5. **`timer` event** trusts the `playerId` sent by the client rather than `session.playerId`; anyone who knows the host's player id could start the race.
6. `done` listener on the client is an empty no-op.

**Scaling / reliability**
7. Timers, chat history and reconnect timeouts are in-memory Maps → the server must run as a single instance; a restart mid-race leaves games stuck (`isJoin=false`, no clock).
8. Abandoned games are only deleted when the last player is removed; nothing cleans up documents left by crashes.
9. Every keystroke-word does a `findById` + `save` of the whole game and broadcasts the full document — fine for 8 players, chatty at scale.

**Security / hygiene**
10. Sentry DSN is hard-coded in `main.dart` (DSNs are semi-public, but `sendDefaultPii: true` and 100 % trace/profile sampling are worth reviewing).
11. `sentry.properties` (auth token) and `server/.env` are git-ignored — keep it that way. `sentry-wizard.exe` (88 MB) sits in the project root.
12. Socket.IO 2.x is old/unmaintained.

**Polish / leftovers**
13. App title is `'Slim Shady'`; Android label `type_racer`; package id `com.example.type_racer`; `pubspec.yaml` description is still "A new Flutter project."
14. Unused: `server/Models/Player.js`, several pubspec packages (section 8), `models/client_state.dart` is just a wrapper map.
15. WPM counts words, not standard 5-character words, so long-word quotes read lower.
16. Mode/time/length lists are duplicated between `server/config/constants.js` and `lib/utils/game_modes.dart` (and reactions in `chat_panel.dart`) — keep them in sync.
17. README roadmap: login/profiles, leaderboard & match history, Docker/Nginx/HTTPS, Codemagic CI/CD, service unit tests, Redis adapter, power-ups.
