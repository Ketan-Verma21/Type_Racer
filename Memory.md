# Memory — Type Racer v2

> Progress log for AI assistants. Read after `Rules.md`, before coding. Update at the end of every session.

## Current status
- Phase: 2 — Validation, logging, quotes, room codes (🟨 code complete; branches `phase-2-validation` (server) and `phase-2-room-codes` (app); waiting for owner checks). Phases 0–1 ✅ merged.
- Machine: Windows (Node 20.19.5 via nvm-windows 1.2.2, **npm 11** (upgraded from 10.8.2), Flutter at `D:\Flutter\sdk`, no Docker)
- Last session: 2026-10-22 — Phase 0 code written; waiting for the owner to install Vitest and run both test suites on Windows

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
1. Owner: server `npm run typecheck`, `npm run lint`, `npm test`; app `flutter analyze`, `flutter test`; play a game with `flutter run -d chrome --dart-define=SERVER_URL=http://localhost:3000`.
2. Commit both phase-2 branches, push, merge (the old app still works with 6-char codes — it never checked the format — but the new app is nicer).
3. Push to GitHub, switch to Ubuntu, start Phase 3 (Ubuntu setup + Docker Compose).

## Known issues / TODO
- 2026-10-22 Lesson: merging the root repo's "stop tracking server/" commit into a branch where `server/` was still tracked made git DELETE the server files from disk. Recovered with `git restore .` inside `server/` (all work was committed in TypeRacerServer). Root now ignores `server/`, so it can't recur.
- npm 10.8.2 crashed with `Cannot read properties of null (reading 'edgesOut')` on installs → fixed by `npm install -g npm@11`. `@vitest/*` packages must be pinned to the exact installed vitest version (`npm i -D @vitest/coverage-v8@<vitest version>`), otherwise npm 11 fails with `reading 'children'`.
- 11 npm audit warnings, mostly socket.io 2.x — fixed by the Phase 5 upgrade. Do NOT run `npm audit fix --force`.
- Before `.gitattributes`, many files were committed with LF but edited as CRLF on Windows (e.g. `server/index.js` shows a whole-file diff that is only line endings). Run `git add --renormalize .` once in both repos.
- v1 issue list: `PROJECT_OVERVIEW.md §10`.
- `loader_overlay` package is now unused (cleanup in Phase 8).

## Useful commands
- Server: `cd server && npm run dev` · `npm test` · `npm run test:coverage`
- Client: `flutter test` · `flutter run -d chrome`

## Measurements
- (Phase 4+)
