# Memory — Type Racer v2

> Progress log for AI assistants. Read after `Rules.md`, before coding. Update at the end of every session.

## Current status
- Phase: 0 — Safety net & quick fixes (🟨 in progress)
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

## Decisions
- 2026-10-22 Server → TypeScript (strict) + Vitest (Phase 1).
- 2026-10-22 Redis is the only datastore; MongoDB removed in Phase 1 (in-memory store until Redis in Phase 4).
- 2026-10-22 Kafka = Phase 7, post-race events only (stats-worker, leaderboard, anti-cheat).
- 2026-10-22 6-character room codes (Phase 2); rename to "Type Racer" everywhere.
- 2026-10-22 Phases 0–2 on Windows; push to GitHub; Phase 3+ on Ubuntu (Node, Flutter, Docker installed there in Phase 3).
- 2026-10-22 Hosting: build multi-instance locally; production = Render free web service + Render Key Value; Kafka online optional (Aiven free).
- 2026-10-22 The AI's sandboxes cannot reach the npm registry → the owner runs `npm install` / `npm test` / `flutter test` on Windows and pastes results.

## Next steps
1. Manual check create → join → race → rematch, and empty name on Create shows an error.
4. Commit on branch `phase-0-safety-net` in both repos (after `git add --renormalize .`), then start Phase 1.

## Known issues / TODO
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
