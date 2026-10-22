# Type Racer — Phases

> Build order for v2. Work on **one phase at a time**; each phase ends with green tests, a working app and an updated `Memory.md`.
> Status: ⬜ not started · 🟨 in progress · ✅ done

| # | Phase | Machine | Main learning | Status |
|---|---|---|---|---|
| 0 | Safety net & quick fixes | Windows | Unit testing basics | 🟨 |
| 1 | Server rewrite: TypeScript + SOLID (in-memory store, Mongo removed) | Windows | TypeScript, SOLID, DI, test doubles | ⬜ |
| 2 | Error handling, validation, quotes, room codes | Windows | Fail-safe design, zod, Strategy/Composite | ⬜ |
| — | **Push both repos to GitHub → switch to Ubuntu** | | | ⬜ |
| 3 | Ubuntu setup + Docker Compose | Ubuntu | Containers | ⬜ |
| 4 | Redis as the datastore (+ leaderboard, history) | Ubuntu | Redis data modelling, atomicity, TTL | ⬜ |
| 5 | Multi-instance: Socket.IO v4, Redis adapter, distributed clock | Ubuntu | Horizontal scaling, pub/sub, distributed claims | ⬜ |
| 6 | Nginx load balancer & load testing | Ubuntu | Reverse proxy, WebSockets, measuring scale | ⬜ |
| 7 | Kafka event streaming + stats-worker | Ubuntu | Topics, partitions, consumer groups, replay | ⬜ |
| 8 | Flutter SOLID refactor & tests | either | Client architecture, widget tests | ⬜ |
| 9 | CI & production deploy | either | CI/CD, ops | ⬜ |
| 10 | Extras (optional) | either | Product features | ⬜ |

---

## Phase 0 — Safety net & quick fixes (Windows)
**Goal:** get tests running on both sides and fix cheap v1 bugs, without restructuring.

- [x] Create `Memory.md` from the template at the bottom of this file.
- [x] Add `.gitattributes` (`* text=auto eol=lf`, binaries marked `binary`) in both repos.
- [x] Server: add Vitest (`npm test`, `npm run test:coverage`); `tests/unit/`.
- [x] Server: unit tests for existing pure code — `calculateTime`, `calculateWPM`, `cleanName`, `shouldEnd` (all modes).
- [x] Client: replace the default counter test; unit tests for `player_utils.dart` (`rankPlayers`, `elapsedSeconds`, `wpmOf`) and `typing_stats.dart`.
- [x] Fix: `timer` event authorises the host from `session.playerId` + test.
- [x] Fix: Create button spinner stays on until `updateGame` / error, 10 s timeout.
- [x] Fix: `create-game` catches quote failures and emits `notCorrectGame` instead of hanging.
- [x] Rename to "Type Racer" (package id changed to `com.ketanverma.typeracer` on Android/iOS/macOS/Linux): MaterialApp title, Android `android:label`, web `<title>`/manifest, `pubspec.yaml` description. Package id `com.example.type_racer` → `com.ketanverma.typeracer` (confirm first — it makes Android treat it as a new app).
- [x] Sentry `sendDefaultPii: false`.
- [x] Remove npm `http` package; delete unused `Models/Player.js`; add `server/.env.example`.

**Done when:** `npm test` and `flutter test` pass; manual create → join → race → rematch works.
**Learn:** what a unit test is, Arrange–Act–Assert, `expect`, regression tests.

---

## Phase 1 — Server rewrite: TypeScript + SOLID (Windows)
**Goal:** rebuild the server in TypeScript with the layers in `Architecture.md §3`, storing games **in memory** (MongoDB removed). Same socket events and payloads → the current Flutter app works unchanged.

- [ ] Tooling: `typescript`, `tsx`, `@types/node`, `@types/express`, ESLint (`typescript-eslint`), Prettier; `tsconfig.json` (`strict`, `target ES2022`, `module commonjs`, `outDir dist`); scripts `dev` (`tsx watch src/index.ts`), `build` (`tsc`), `start` (`node dist/index.js`), `test`, `lint`, `typecheck`.
- [ ] `domain/types.ts` + `domain/` pure modules: `rules`, `settings`, `wpm`, `errors`.
- [ ] `domain/modes/`: `ModeStrategy` + `ClassicMode`, `FlawlessMode`, `SuddenDeathMode` + `modeRegistry`.
- [ ] `ports/` interfaces: `GameRepository`, `ChatRepository`, `SessionStore`, `QuoteProvider`, `Clock`, `IdGenerator`, `Broadcaster`.
- [ ] `adapters/memory/*`, `SystemClock`, `RandomIdGenerator`, `SocketIoBroadcaster`, current API Ninjas quote fetch as `ApiNinjasQuoteProvider`.
- [ ] `services/`: `GameService`, `RaceClock` (still `setInterval`-based on one instance for now), `ChatService`, `PresenceService`, `QuoteService`.
- [ ] `transport/socket/*` handlers (thin), `gameDto.ts` producing the v1 `updateGame` shape (`_id` fields kept).
- [ ] `container.ts` composition root; `index.ts` + `app.ts`; `/health` still returns `{ok, db: true, uptime}` (the v1 app checks `db`).
- [ ] Remove `mongoose`, `Models/`, `MONGO_URL`; delete old JS files once the TS server passes the regression check.
- [ ] Tests (Vitest): every mode strategy; `GameService` (create, join, room full, spectator, settings validation, correct/wrong word per mode, finish, rematch promotes spectators, host hand-over on leave); `RaceClock` with `FakeClock`; contract suite for `GameRepository` against the in-memory adapter.
- [ ] Update Render: build `npm ci && npm run build`, start `npm start`, remove `MONGO_URL`.

**Done when:** `npm run typecheck`, `npm run lint`, `npm test` green; ≥ 80 % coverage on `domain/` + `services/`; the unchanged Flutter app plays a full race against the TS server.
**Learn:** TS types/interfaces/generics, each SOLID letter in real code (`Architecture.md §3.3`), constructor injection, fakes vs mocks.

---

## Phase 2 — Error handling, validation, quotes, room codes (Windows)
**Goal:** the server never hangs or crashes on bad input or failing dependencies.

- [ ] `config/env.ts` with zod; fail fast on bad env.
- [ ] `transport/socket/schemas.ts` (zod per event, types via `z.infer`) + `withHandler`; `error-message` and `joined` events (keep `notCorrectGame` for create/join).
- [ ] Services throw `DomainError`s; `withHandler` maps them.
- [ ] `pino` logger with `instanceId`; no `console.log`.
- [ ] Quotes: `LocalQuoteProvider` (`data/quotes.json`, ≥ 100 quotes), `FallbackQuoteProvider`, API timeout 3 s; `QuoteService.getWords(minWords)` concatenates → **quote length setting works (FR-1, FR-2).**
- [ ] Short room codes (FR-11): `domain/roomCode.ts`, `RandomIdGenerator.roomCode()`, uniqueness check in the repository. Client: join validation + uppercase input for 6-char codes.
- [ ] Client: listen to `joined` and `error-message`; Join screen loading + 10 s timeout (FR-5).
- [ ] `/health/live`, `/health/ready`.
- [ ] Tests: schemas reject bad payloads; fallback order; min-words; room-code format/uniqueness; `withHandler` mapping; supertest for health routes.

**Done when:** an empty `QUOTES_API_KEY` still creates rooms; garbage payloads get `error-message`; rooms use 6-char codes end to end.

### ➜ Handover to Ubuntu
- [ ] Commit + push root repo (`Type_Racer`) and `server/` repo (`TypeRacerServer`) on `phase-2` branches; merge.
- [ ] Note in `Memory.md`: last commit hashes, anything unfinished.
- [ ] Copy `server/.env` to Ubuntu manually (it's git-ignored).

---

## Phase 3 — Ubuntu setup + Docker Compose (Ubuntu)
**Goal:** a reproducible dev machine; one command runs the backend.

- [ ] Install: git, nvm → Node 20, Docker Engine + Compose plugin (add user to `docker` group), Flutter SDK + Chrome (`flutter doctor`), VS Code/Android Studio as preferred.
- [ ] Clone both repos; `npm ci`; `npm test`; `flutter pub get`; `flutter test` — all green on Linux.
- [ ] `server/Dockerfile` (multi-stage: build with `tsc`, run on `node:20-slim`, non-root user).
- [ ] `server/docker-compose.yml`: `app` (1 instance) + `redis:7` (`--appendonly yes`, volume) — Redis not used by code yet, just running.
- [ ] `.dockerignore`.
- [ ] Client: `SERVER_URL` via `--dart-define` (FR-14).
- [ ] README: "Run with Docker".

**Done when:** `docker compose up` + `flutter run -d chrome --dart-define=SERVER_URL=http://localhost:3000` plays a full race.

---

## Phase 4 — Redis as the datastore (Ubuntu)
**Goal:** swap in-memory adapters for Redis adapters; services unchanged.

- [ ] `infra/redis.ts`, `adapters/redis/keys.ts`.
- [ ] `RedisGameRepository` per `Architecture.md §5.1`; Lua script for atomic capacity-checked join; per-player hashes; TTL 2 h refreshed on activity (FR-10).
- [ ] `RedisChatRepository`, `RedisSessionStore`, `RedisRateLimiter` (FR-9), `RedisQuotePool` with background refill (FR-3).
- [ ] `EventPublisher` port + `InProcessEventPublisher` → `StatsService` → `RedisLeaderboard` (`ZADD GT`) + `RedisMatchHistory` (capped lists) (FR-12, FR-15).
- [ ] `get-leaderboard` socket event.
- [ ] `container.ts`: `STORE=redis` selects Redis adapters. **No service code changes** (DIP payoff).
- [ ] Tests: every Redis adapter passes the same contract suite as the memory adapter (`ioredis-mock`, plus a real-Redis run via Compose); `StatsService` unit tests; leaderboard keeps the best score only.

**Done when:** full race with `STORE=redis`; restart the app container mid-lobby → room still there; join/word latency recorded in `Memory.md`.
**Learn:** hashes vs strings vs sorted sets vs lists, TTL, Lua atomicity, AOF persistence.

---

## Phase 5 — Multi-instance (Ubuntu) — client + server ship together
**Goal:** any number of instances serve the same room.

- [ ] Server `socket.io` 2 → 4; client `socket_io_client` 1.x → 3.x; fix API differences.
- [ ] `@socket.io/redis-adapter` with dedicated pub/sub connections.
- [ ] `Sweeper` (1 s, aligned) replacing every `setInterval` that holds state: tick claims, countdown/race transitions, presence expiry (`Architecture.md §4.4–4.5`).
- [ ] Client identifies itself by `playerId` from `joined`; `rejoin-game` uses it.
- [ ] Tests: two `Sweeper`s sharing one fake Redis emit each tick once; transition claimed once; presence expiry; integration test with **two in-process servers** sharing Redis (player on A sees a word typed on B).

**Done when:** 2 instances on different ports, players split across them, full race works; kill the instance that started the countdown → race still ticks and ends.
**Learn:** pub/sub, why in-memory timers break with N instances, claims with `SET NX`/`ZREM`, idempotency.

---

## Phase 6 — Nginx & load testing (Ubuntu)
- [ ] `server/nginx/nginx.conf` (`Architecture.md §7`).
- [ ] Compose: `nginx` + `app1..app3` + `redis`; only Nginx exposed.
- [ ] Graceful shutdown (`SIGTERM` → stop accepting, close sockets, exit).
- [ ] Artillery script: 125 rooms × 8 bots racing.
- [ ] `docs/load-test.md`: concurrent sockets, p95 word→broadcast latency, CPU/RAM per instance, 1 vs 3 instances.
- [ ] Resilience: `docker compose stop app2` mid-race (NFR-4).

**Done when:** NFR-2/3/4 measured (pass or documented gap).
**Learn:** reverse proxy vs load balancer, WebSocket upgrade, sticky sessions, edge rate limiting, reading load-test output.

---

## Phase 7 — Kafka event streaming + stats-worker (Ubuntu)
**Goal:** move stats processing out of the game servers into a separate consumer, without touching game logic.

- [ ] Compose: `kafka` (`apache/kafka`, KRaft, single broker) + topic creation for `match.started`, `player.finished`, `match.finished` (2 partitions each).
- [ ] `adapters/kafka/KafkaEventPublisher` (`@confluentinc/kafka-javascript`, idempotent producer, key = gameId).
- [ ] `src/worker.ts` + `KafkaStatsConsumer` (group `stats-worker`, commit after Redis writes, idempotency marker).
- [ ] `domain/antiCheat.ts` (FR-17); flagged results skip the leaderboard.
- [ ] `container.ts`: `EVENTS=kafka` → Kafka publisher on game servers; worker runs `StatsService`.
- [ ] Tests: `EventPublisher` contract for both publishers; consumer handler unit tests with a fake message source; idempotency (same event twice → counted once); anti-cheat rules.
- [ ] Experiments, written up in `docs/kafka.md`: stop worker → play → restart → catch-up; 2 workers → partition split; offset reset → leaderboard rebuilt.

**Done when:** leaderboard updates arrive via Kafka; killing Kafka or the worker never affects a race.
**Learn:** topics, partitions, keys & ordering, consumer groups, offsets/commit, at-least-once + idempotency, decoupling producers from consumers.

---

## Phase 8 — Flutter SOLID refactor & tests
- [ ] Typed models (`Game`, `Player`, `GameSettings`, `ChatMessage`, `Reaction`, `TimerState`, `LeaderboardEntry`) + tests.
- [ ] `socket_events.dart`; `GameRepository` (abstract) + `SocketGameRepository`; `FakeGameRepository`.
- [ ] Providers depend on `GameRepository`.
- [ ] Split `game_screen.dart` into `views/lobby|race|watch|results`.
- [ ] Pure logic → `domain/`.
- [ ] Leaderboard screen (FR-15).
- [ ] Remove unused packages after confirming: neopop, firebase_core, feedback_sentry, shorebird_code_push.
- [ ] Widget tests: RaceLane, Scoreboard, SettingsPanel, StatsBar, game views.
- [ ] `withOpacity` → `withValues(alpha:)` if the SDK supports it.

**Done when:** `flutter test` green, ≥ 80 % on `domain/` + models; app looks the same.

---

## Phase 9 — CI & production deploy
- [ ] GitHub Actions — server: `npm ci`, `lint`, `typecheck`, `test:coverage` (Redis service container); client: `flutter analyze`, `flutter test`.
- [ ] Production: Render web service (`STORE=redis`, `EVENTS=inprocess`) + Render Key Value (free); remove the old MongoDB env var; optional Aiven free Kafka + worker.
- [ ] Firebase web deploy with `--dart-define=SERVER_URL=<render url>`.
- [ ] README: architecture, Docker, tests, scaling + Kafka results.

---

## Phase 10 — Extras (optional)
- [ ] Public quick-match queue (Redis list).
- [ ] Power-ups as a new `ModeStrategy` (Open/Closed proof).
- [ ] Login & profiles (new PRD section; PostgreSQL).

---

## Memory.md template (create at the start of Phase 0)

```markdown
# Memory — Type Racer v2

## Current status
- Phase: 0 — Safety net & quick fixes (🟨)
- Machine: Windows
- Last session: YYYY-MM-DD — <one line>

## Done
- <date> <what, which files>

## Decisions
- 2026-10-22 TypeScript + Vitest; Redis only (Mongo removed); Kafka phase; 6-char room codes; rename to Type Racer; Windows for Phases 0–2, Ubuntu from Phase 3.

## Next steps
1. ...

## Known issues / TODO
- ...

## Useful commands
- Server: `cd server && npm run dev` · `npm test` · `npm run typecheck`
- Client: `flutter test` · `flutter run -d chrome --dart-define=SERVER_URL=...`
- Stack (Phase 3+): `cd server && docker compose up --build`

## Measurements
- (Phase 4+) join latency, word→broadcast p95, load test, Kafka experiments
```
