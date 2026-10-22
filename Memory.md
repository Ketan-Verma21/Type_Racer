# Memory — Type Racer v2

> Progress log for AI assistants. Read after `Rules.md`, before coding. Update at the end of every session.

## Current status
- Phase: 3 — Ubuntu setup + Docker Compose (✅ done; server branch `phase-3-docker`, app branch `phase-3-docs`). Phases 0–2 ✅ merged.
- Machine: **Ubuntu 22.04** (zsh; Node 20.20.2 via nvm 0.40.3, npm 11.21.1; Docker 29.1.3 from Ubuntu's `docker.io` + `docker-compose-v2`; Flutter 3.47.7 (snap, Dart 3.13.5); Chrome 156). Repos at `~/Code/Project/type_racer` (+ `server/`).
- Last session: 2026-10-22 — Docker image builds, Compose stack healthy, all tests green on Linux.

## Done
- 2026-10-22 v1 analysed → `PROJECT_OVERVIEW.md`.
- 2026-10-22 Planning docs: `PRD.md`, `Architecture.md`, `Rules.md`, `Phases.md`, `Design.md`.
- 2026-10-22 Phase 0 started: `Memory.md`, `.gitattributes` (root + server), `server/.env.example`.
- 2026-10-22 Server: Vitest config (`vitest.config.mjs`), scripts `test` / `test:watch` / `test:coverage`; tests in `tests/unit/*.test.mjs` (helpers, shouldEnd, gameHandlers — 29 tests). Tests load CommonJS code via `createRequire` so `vi.spyOn` hits the same module instance the handlers use.
- 2026-10-22 Server fixes (`sockets/gameHandlers.js`): `timer` uses `session.playerId` + checks `gameId === session.gameId` + tolerates empty payload; `create-game` / `join-game` emit `notCorrectGame` on unexpected errors. Removed unused `Models/Player.js`. Regression tests verified to FAIL on the old handler and pass on the new one (checked with a node:test shim, not real Vitest).
- 2026-10-22 Client: `test/widget_test.dart` replaced by `test/unit/player_utils_test.dart` + `test/unit/typing_stats_test.dart` (not yet run). Create screen: spinner stays until `updateGame`/`notCorrectGame`, 10 s timeout, empty-name check; `LoaderOverlay` wrapper removed. `SocketMethods.updateGameListener(onEnterGame:)` and `notCorrectGameListener(onError:)` callbacks added.
- 2026-10-22 Rename to "Type Racer": MaterialApp title, Android label, iOS CFBundleName, web title/manifest (colours #0B0F1E), Windows/Linux window titles, pubspec description. Sentry `sendDefaultPii: false`.

- 2026-10-22 Server deps clean-reinstalled (old lockfile didn't match node_modules); `http` package removed; vitest 4.1.12 + @vitest/coverage-v8 4.1.12 installed. **`npm test`: 29/29 passed on Windows.**
- 2026-10-22 **`flutter test`: 17/17 passed on Windows.** (`flutter pub outdated` lists 61 newer packages — ignore for now; socket_io_client 3.1.6 is the Phase 5 target.)

- 2026-10-22 App id `com.example.type_racer` → `com.ketanverma.typeracer` (Android namespace/applicationId + MainActivity moved to `kotlin/com/ketanverma/typeracer/`; iOS/macOS bundle id; Linux APPLICATION_ID). Android will install it as a new app.
- 2026-10-22 Root repo now ignores `server/` (`.gitignore`); the server is owned only by the `TypeRacerServer` repo. Owner runs `git rm -r --cached server` once.

- 2026-10-22 **Phase 1 code complete** (server branch `phase-1-typescript`): TypeScript server in `src/` (domain / ports / adapters / services / transport, `container.ts` composition root), MongoDB code removed, old JS deleted. 129 Vitest tests (verified by compiling with tsc and running under a node:test shim) + end-to-end smoke test (compiled server + 2 real socket.io-client v2 clients: create, join, bad id, guest-start ignored, settings, chat, countdown 5..0, full race + WPM, rematch, leave) all passed. Typecheck/lint/prettier clean.
- 2026-10-22 How the AI verifies without npm: tsc/eslint/prettier run from the owner's `node_modules` (pure JS) in the device VM; tests compiled with tsc into `~/scratch/out` and run with `node --test` + a vitest shim (`~/scratch/shim`, script `~/scratch/run.sh`). Real Vitest must still be run by the owner on Windows.

- 2026-10-22 Phase 1 merged to master; Render now builds `npm ci && npm run build`, starts `npm start`; MONGO_URL removed.
- 2026-10-22 **Phase 2 code complete**: zod env + payload schemas, `withHandler` error replies (`error-message`, `notCorrectGame` for create/join/rejoin), `joined` event, PinoLogger, 108 bundled quotes + fallback chain + quote length via `getWords(minWords)`, 6-char room codes, `/health/live|ready`. 162 server tests + e2e smoke (no API key → bundled quotes; long = 45 words; lowercase code joins; FORBIDDEN / BAD_REQUEST replies) passed. App: `--dart-define=SERVER_URL`, room-code input + validation, Join spinner/timeout, big room code in lobby, `error-message` snackbar; new `test/unit/room_code_test.dart` (not run yet).

- 2026-10-22 **Phase 3 (Ubuntu):** toolchain installed and checked. On Linux: `npm test` 162/162, `flutter test` 23/23.
- 2026-10-22 `server/Dockerfile` (multi-stage `node:20-slim`: build = `npm ci` + `npm run build`; runtime = `npm ci --omit=dev`, `dist/` + `data/`, `USER node`), `.dockerignore` (no node_modules/tests/.git/.env), `docker-compose.yml` (`app` on 3000 with `env_file: .env`, `INSTANCE_ID=app1`, healthcheck via `node -e fetch(/health/ready)`; `redis:7` `--appendonly yes`, volume `redis-data`, port `127.0.0.1:6379`; app waits for healthy Redis). `docker compose up --build -d` → both containers up, `/health` + `/health/ready` OK, JSON logs with `instanceId`.
- 2026-10-22 README "Getting Started" rewritten: Mongo removed, clone layout, "Run with Docker", Node dev option, `--dart-define=SERVER_URL`.

## Decisions
- 2026-10-22 Env var names stay `API_URL` / `API_KEY` (match existing .env and Render), not QUOTES_API_*.
- 2026-10-22 Pretty logs only when stdout is a terminal, so Render gets JSON without needing NODE_ENV=production (which would make `npm ci` skip the dev dependencies the build needs).
- 2026-10-22 Server URL `--dart-define` pulled forward from Phase 3 to Phase 2.
- 2026-10-22 Server → TypeScript (strict) + Vitest (Phase 1).
- 2026-10-22 Redis is the only datastore; MongoDB removed in Phase 1 (in-memory store until Redis in Phase 4).
- 2026-10-22 Kafka = Phase 7, post-race events only (stats-worker, leaderboard, anti-cheat).
- 2026-10-22 6-character room codes (Phase 2); rename to "Type Racer" everywhere.
- 2026-10-22 Phases 0–2 on Windows; push to GitHub; Phase 3+ on Ubuntu (Node, Flutter, Docker installed there in Phase 3).
- 2026-10-22 Hosting: build multi-instance locally; production = Render free web service + Render Key Value; Kafka online optional (Aiven free).
- 2026-10-22 The AI's sandboxes cannot reach the npm registry → the owner runs `npm install` / `npm test` / `flutter test` on Windows and pastes results.

- 2026-10-22 Docker comes from Ubuntu's packages (`docker.io`, `docker-compose-v2`), not Docker's apt repo — don't mix the two.
- 2026-10-22 No `curl` in the slim image → healthchecks use `node -e "fetch(...)"`. Containers must not get a TTY (pino would load `pino-pretty`, a dev dependency).

## Decisions (Phase 1 design)
- `Notifier` port (gameChanged/timer/raceOver/playerFinished/chat*/reaction) instead of a generic Broadcaster — services never see Socket.IO event names.
- `RoomMembership` port: services add a socket to the game room *before* broadcasting (creator must receive the first `updateGame`). In Phase 5 this maps to `io.in(socketId).socketsJoin(room)`, which works across instances.
- `Scheduler` port (`every`/`after`) + `FakeScheduler` so timers are tested by ticking; `Logger` port + `ConsoleLogger` (pino in Phase 2).
- Handlers depend on a tiny `ConnectionTracker` + own `ServerSocket`/`IoServer` interfaces (Socket.IO 2→4 upgrade only touches adapters).
- Services receive the caller's `Session` (gameId, playerId, nickname); handlers own the `SessionStore`.
- `GameRepository.updateMeta` with an `undefined` field removes it (contract test).
- Domain `Player` uses clean names (`id`, `isHost`, `wordIndex`, `wpm`); `gameDto.ts` maps to v1 names (`_id`, `isPartyLeader`, `currentWordIndex`, `WPM`, `socketID`).
- Create with an empty nickname now replies `notCorrectGame "Please enter your name"` (v1 silently ignored it).

## Next steps
1. ~~Full race against the Docker backend~~ — done 2026-10-22.
2. Commit + push `phase-3-docker` (server) and `phase-3-docs` (app); merge.
3. Phase 4 — Redis as the datastore (`ioredis`, `RedisGameRepository`, contract suite against `ioredis-mock` + the Compose Redis).

## Known issues / TODO
- 2026-10-22 Node 20 is past end-of-life (April 2026). Kept per plan; consider Node 22 (image + nvm + `engines`) as a small separate change.
- 2026-10-22 `docker compose` warns "buildx isn't installed" → `sudo apt install docker-buildx` (harmless; classic builder used).
- 2026-10-22 How the AI works now: the session is linked to the Ubuntu machine; it reads/writes files in `~/Code/Project` but cannot run commands — the owner runs npm/flutter/docker and pastes output.
- 2026-10-22 Lesson: merging the root repo's "stop tracking server/" commit into a branch where `server/` was still tracked made git DELETE the server files from disk. Recovered with `git restore .` inside `server/` (all work was committed in TypeRacerServer). Root now ignores `server/`, so it can't recur.
- npm 10.8.2 crashed with `Cannot read properties of null (reading 'edgesOut')` on installs → fixed by `npm install -g npm@11`. `@vitest/*` packages must be pinned to the exact installed vitest version (`npm i -D @vitest/coverage-v8@<vitest version>`), otherwise npm 11 fails with `reading 'children'`.
- 11 npm audit warnings, mostly socket.io 2.x — fixed by the Phase 5 upgrade. Do NOT run `npm audit fix --force`.
- Before `.gitattributes`, many files were committed with LF but edited as CRLF on Windows (e.g. `server/index.js` shows a whole-file diff that is only line endings). Run `git add --renormalize .` once in both repos.
- v1 issue list: `PROJECT_OVERVIEW.md §10`.
- `loader_overlay` package is now unused (cleanup in Phase 8).

## Useful commands
- Server: `cd server && npm run dev` · `npm test` · `npm run test:coverage`
- Docker: `cd server && docker compose up --build -d` · `docker compose ps` · `docker compose logs -f app` · `docker compose down`
- Client: `flutter test` · `flutter run -d chrome --dart-define=SERVER_URL=http://localhost:3000`

## Measurements
- (Phase 4+)
