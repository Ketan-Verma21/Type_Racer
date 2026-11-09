# Memory — Type Racer v2

> Progress log for AI assistants. Read after `Rules.md`, before coding. Update at the end of every session.

## Current status
- Phase: 7 — Kafka + stats-worker (✅ done on server branch `phase-7-kafka`; app docs on `phase-7-docs`; merge next). Phases 0–6 ✅ merged.
- Machine: **Ubuntu 22.04** (zsh; Node 20.20.2 via nvm 0.40.3, npm 11.21.1; Docker 29.1.3 from Ubuntu's `docker.io` + `docker-compose-v2`; Flutter 3.47.7 (snap, Dart 3.13.5); Chrome 156). Repos at `~/Code/Project/type_racer` (+ `server/`).
- Last session: 2026-11-09 — Phase 7: Kafka broker + topics in Compose, Kafka producer on the game servers, `stats-worker`, four experiments; report in `server/docs/kafka.md`.

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

- 2026-10-22 Phase 3 merged (server `phase-3-docker`, app `phase-3-docs`).
- 2026-10-23 **Phase 4 step 4.1:** `ioredis@5.11.1` + `ioredis-mock@8.13.1` (dev); env `STORE=memory|redis`, `REDIS_URL`; `infra/redis.ts` (client, `isRedisReady` PING with 1 s timeout); `adapters/redis/keys.ts`; `/health/ready` 503 when Redis is down, `/health` `db` = store status. Checked by hand: 200 → stop Redis → 503 → start → 200.
- 2026-10-23 **4.2:** `RedisGameRepository` — `game:{id}` hash (words + settings as JSON fields, `seq` for join order), `:players` zset, `:player:{pid}` hashes; Lua scripts (`trAddPlayer` atomic capacity check, `trUpdateGame`/`trUpdatePlayer` no-op on missing game, TTL refresh); `create` = HSETNX reservation + MULTI. Passes the GameRepository contract on ioredis-mock + 7 Redis-only tests (10 concurrent joins into 5 seats → exactly 5).
- 2026-10-23 **4.3:** `RedisChatRepository` (RPUSH+LTRIM capped list), `RedisSessionStore` (hash, 1 h TTL), `RedisRateLimiter` (`SET NX PX`). `tests/unit/adapters/memory.test.ts` replaced by contract suites for chat/session/rate limiter (memory + Redis).
- 2026-10-23 **4.4:** `createStores()` in `container.ts` picks adapters by `STORE` — no service changes. Graceful SIGTERM/SIGINT shutdown (closes Socket.IO + Redis). Compose sets `STORE=redis`, `REDIS_URL=redis://redis:6379`. **215 tests.** Verified 2026-10-26: full race + rematch on Redis and memory; room keys + TTL visible in redis-cli; room survives `docker compose restart app` in the lobby.

- 2026-10-26 **4.5:** `RedisQuotePool` (`quotes:pool` list, LPOP oldest, RPUSH+LTRIM refill ≤10/run every 30 s, target 50) as the first source of the fallback chain pool → API → bundled. Wired only with `STORE=redis` **and** `API_KEY` — the owner has no API key, so the game uses the bundled quotes and the pool stays off. 221 tests.
- 2026-10-29 **4.6:** `domain/events.ts` (`match.finished` with ranked results), `EventPublisher` port + `InProcessEventPublisher` (failing subscriber logged, never thrown), `StatsService` (leaderboard ignores eliminated / 0 WPM), `Leaderboard` + `MatchHistory` ports with memory + Redis adapters (`leaderboard:{mode}` zset via Lua `trKeepBest`; `matches:recent` 500 + `game:{id}:history` 20), `get-leaderboard` → `leaderboard` socket event. Only service change: `RaceClock.finishRace` publishes (fire and forget). 241 tests.
- 2026-10-29 **4.7:** `tests/integration/realRedis.test.ts` runs every contract suite on the real Compose Redis (db 15; db 0 refused) + 10 concurrent connections into 5 seats → exactly 5. `npm run test:redis` 31/31. `npm run bench:redis` (see Measurements). Architecture §5.1/§9 and README updated.

- 2026-10-29 **5.1:** server Socket.IO **4.8.4** (+ `socket.io-client` 4.8.4 dev), `@types/socket.io` removed; `transport/socket/createSocketServer.ts` (cors `*`); end-to-end test `tests/integration/socketE2E.test.ts` (real server + real v4 clients). Server **README.md** written (kept up to date in every server commit). `npm audit fix` → body-parser 1.20.9, 0 vulnerabilities. 245 tests.
- 2026-10-29 **5.2:** app `socket_io_client` **3.1.6**; `myPlayerId` from `joined` (`player_utils.dart`, set in `socket_client.dart`, cleared on leave); `findMe` matches playerId first, socket id as fallback; 4 new Flutter tests (27). Server `allowEIO3` removed.
- 2026-10-29 **5.3:** `@socket.io/redis-adapter` **8.3.0** (`infra/redisAdapter.ts`, own pub/sub connections); `ConnectionTracker` + local socket map removed; `tests/integration/twoServers.test.ts` (two in-process servers on real Redis).
- 2026-10-29 **5.4:** race clock in Redis — `ports/RaceSchedule.ts` (memory + Redis, `games:clock`), `services/Sweeper.ts` (whole-second aligned, no overlap), `RaceClock` rewritten (claims for ticks and transitions, whole-second times). `buildContainer` returns a `Container` with `stop()`. Same timing as before (5..0, race starts the next second). Owner checked: restart mid-race → race carries on.
- 2026-11-03 **5.5:** reconnect grace in Redis — `ports/GracePeriods.ts` (`presence:grace`), `PresenceService` swept by the Sweeper; drop on A + rejoin on B keeps the player. Owner reported 282 tests + 4 skipped, 50 real-Redis.
- 2026-11-03 **5.6:** Compose runs `app1` (:3000) + `app2` (:3001) from one `x-app` block. **Bug found by the owner:** Create timed out with the Redis adapter — its non-local `socketsJoin` lands only after a pub/sub round trip, so the creator missed the first `updateGame`. Fix: `io.local.in(id).socketsJoin()` (a socket is always joined by its own server). Regression test in `twoServers.test.ts` (run without the fix first, then with it). Owner reported all checks done, including play across both servers and the kill test (stop app1 mid-countdown).

- 2026-11-04 App repo connected to **Codemagic** by the owner: it builds the Flutter web app; status badge added to the README. Server CI (GitHub Actions) is still Phase 9.

- 2026-11-04 **6.1:** `server/nginx/nginx.conf` + Compose `nginx` (:8080) → `app1..app3` → `redis`; game servers no longer published. `least_conn` (not `ip_hash`), server `transports: ["websocket"]`, Nginx 1.28 `resolve` + Docker DNS (`127.0.0.11`) so a restarted server rejoins; `/health/live` returns `instance`. 283 tests.
- 2026-11-04 **6.2:** load generator `tests/load/` (`bot.ts`, `room.ts`, `run.ts`, `metrics.ts`; `npm run load -- --rooms N`), results JSON in `load-results/` (git-ignored). Smoke: 5 rooms, p95 13 ms.
- 2026-11-06 **6.3/6.4:** full runs (see Measurements). **Bug found:** with app2/app3 stopped, 58/125 rooms timed out — Nginx's default 60 s `proxy_connect_timeout` kept sending connections to dead servers. Fix: `proxy_connect_timeout 2s` + `proxy_next_upstream error timeout` + `proxy_next_upstream_tries 3` → 125/125.
- 2026-11-06 **6.5:** `server/docs/load-test.md` + README "Performance" section.

- 2026-11-06 **7.1/7.2:** events carry an `eventId`; `ProcessedEvents` port (memory + Redis `SET stats:done:{id} NX EX 86400`); `StatsService.onEvent` claims → handles → releases on error; `domain/antiCheat.ts` (> 250 WPM flagged, kept off the leaderboard); match counts (`HINCRBY stats:matches`); `RaceClock` publishes `match.started`.
- 2026-11-06 **7.3:** `@confluentinc/kafka-javascript` 1.11.0 (KafkaJS-style API). `KafkaEventPublisher` (topic per event type, key = gameId, JSON; fire-and-forget, never throws); idempotent producer `acks=all`; `keepTrying` connects in the background; `EVENTS=inprocess|kafka` + `KAFKA_BROKERS`. Compose: `apache/kafka:4.1.0` KRaft (internal `kafka:9092`, host `localhost:9094`) + `kafka-init` (2 topics × 2 partitions). Dockerfile `deps` stage with python3/make/g++ for the native client. 315 tests.
- 2026-11-08 **7.4:** `src/worker.ts` + `KafkaStatsConsumer` (group `stats-worker`, autoCommit off, commit offset + 1 after the Redis writes; Redis down → retry with backoff 0.5–10 s; bad messages logged + skipped; `decodeEvent` validates with zod). Compose `stats-worker` (same image, `node dist/worker.js`). Nginx healthcheck → `127.0.0.1` (`localhost` = ::1 inside the container → was "unhealthy").
- 2026-11-09 **7.5:** experiments → `server/docs/kafka.md` + README "Kafka experiments" (see Measurements).

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

- 2026-10-23 ioredis pinned to **5.x**: ioredis 6.0.0 exists but ioredis-mock 8.13.1 only supports ^5 (no `--force`). Revisit when the mock supports 6.
- 2026-10-23 Round words stored as a `words` field in the game hash (not `game:{id}:words`) — always read with the game. Update Architecture.md §5.1 in step 4.7.
- 2026-10-26 Host leaving hands the room to the next player (existing behaviour, by design); "send everyone home when the host leaves" would be a separate product change.

- 2026-10-29 Leaderboard "keep best" is a Lua script, not `ZADD GT`: ioredis-mock 8.13.1's `zadd` only accepts NX/XX/CH/INCR (checked in its source).
- 2026-10-29 Leaderboard is keyed by nickname (no accounts) — two players with the same name share an entry. Fine until login exists.

- 2026-10-29 One `games:clock` zset (not `games:countdown` + `games:racing`); transitions claimed with Lua compare-and-remove, not a bare `ZREM` (a bare ZREM by a slow instance could remove the next phase's entry).
- 2026-10-29 Clock times are whole seconds: deadlines snapped to the second, sweeps round "now" — otherwise a mid-second Start showed 6 first and timer jitter skipped/repeated numbers.
- 2026-11-03 Room join/leave are **local** (`io.local.in(socketId)`): every join/leave is done by the server the socket is connected to; broadcasts still cross servers through the adapter.

- 2026-11-04 Load balancing is **not sticky** (`least_conn`): the server accepts WebSocket only, so a connection never needs to return to the same instance; `ip_hash` would put a one-IP load test on one server.
- 2026-11-04 Load tool: own TypeScript bots (socket.io-client) instead of Artillery — 8 coordinated players per room and exact word→broadcast timing; no new dependency.

- 2026-11-06 Two topics (`match.started`, `match.finished`), not three: `player.finished` dropped — nothing consumes it yet.
- 2026-11-06 Kafka client = `@confluentinc/kafka-javascript` (librdkafka, maintained) instead of `kafkajs` (unmaintained). Native module → compiled at install; the Docker `deps` stage has build tools, the `build` stage uses `npm ci --ignore-scripts`.
- 2026-11-06 Publishing is fire-and-forget: a race never waits for Kafka. Connecting never blocks startup and Kafka isn't part of `/health/ready`.
- 2026-11-08 The worker commits manually after the Redis writes (at-least-once) and relies on `eventId` dedup → effectively once. A Redis outage blocks the partition (retry) instead of skipping, to keep a room's events in order.
- 2026-11-08 Production (Phase 9) stays `EVENTS=inprocess` (no free Kafka needed); Kafka is for local runs and demos.

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
1. Merge `phase-7-kafka` (server) and `phase-7-docs` (app) into master.
2. Phase 8 — Flutter SOLID refactor & tests.
3. Phase 9 (end): host the server (Render + Render Key Value), set `SERVER_URL` in Codemagic, deploy the web build to Vercel, add a "Play it live" link.

## Known issues / TODO
- ~~2026-10-26 Restarting the app mid-countdown or mid-race froze that room~~ — fixed in Phase 5.4 (race clock in Redis).
- 2026-11-09 Dedup gap: if Redis dies after `claim` but before the writes, `release` fails too → the retried event is skipped for 24 h. Fix later with one Lua script (claim + writes).
- 2026-11-09 While Kafka is down, librdkafka logs `Connection refused` on every reconnect (noisy, harmless).
- 2026-11-09 Not yet shown: events produced *while* Kafka is down are kept (in exp. 4 the races started around the stop and finished after the restart). Stricter test: stop Kafka before the races start.
- 2026-11-06 Docker pulls failed (IPv6 unreachable + systemd-resolved timeouts) → `DNS=1.1.1.1 8.8.8.8` in `/etc/systemd/resolved.conf`; IPv6 disabled until reboot with `sysctl` when needed.
- 2026-11-03 Crash window: between claiming a deadline and scheduling the next phase, a crash leaves that room without a clock entry (stuck). Rare; a "repair stuck rooms" sweep could fix it later.
- 2026-10-26 The AI's file writes to the device can land late or stale if a file is edited after creation → it now writes each version to a fresh path and verifies the device copy (checksum) after every write. Commit only behind `&&` (format → typecheck → lint → test).
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
- Docker: `cd server && docker compose up --build -d` (game on http://localhost:8080) · `docker compose ps` · `docker compose logs -f app1 app2 app3` · `docker compose stop app2` (kill test) · `docker compose down`
- Load test: `ulimit -n 8192 && npm run load -- --rooms 125` (server folder, stack running)
- Kafka: `docker compose logs stats-worker` · consumer lag: `docker compose exec kafka /opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group stats-worker` · watch events: `... kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic match.finished --from-beginning --property print.key=true` · two workers: `docker compose up -d --scale stats-worker=2`
- Client: `flutter test` · `flutter run -d chrome --dart-define=SERVER_URL=http://localhost:3000`

## Measurements
- 2026-11-09 **Kafka experiments** (`server/docs/kafka.md`), same laptop, bots at 60 WPM:
  - Worker stopped, 20 races: 20/20 finished; 40 events waited (lag 9 + 11 per topic); restart → caught up in 20 s (mostly container start + group join); match count 22 → 42
  - `--scale stats-worker=2`: each worker got 2 of the 4 partitions
  - Stats wiped + offsets reset to earliest: match count 42 → 0 → 42. Leaderboard rebuilt from Phase 7 races only (Phase 6 bot scores predate Kafka)
  - Kafka stopped 30 s during 10 races: 10/10 finished, p95 7 ms; match count 42 → 52
- 2026-11-06 **Load test** (`server/docs/load-test.md`), i7-1165G7 4c/8t, 15 GiB, everything on one laptop; bots at 60 WPM, long quote, 60 s races:
  - 1,000 players · 3 servers: 125/125 rooms · word→broadcast p50 3 · p95 **17** · p99 34 ms · servers 55–80 % CPU, ~100–128 MiB each
  - 1,000 players · 1 server: 125/125 · p95 16 ms · server at 100–124 % CPU (its ceiling)
  - 2,000 players · 2 servers: 250/250 · p50 19 · p95 **77** · p99 106 ms
  - 2,000 players · 1 server: **239/250** · p50 261 · p95 527 · p99 860 ms (overloaded)
  - Kill app2 mid-race (1,000 players, 3 servers): 333/333 dropped players back, rejoin p95 **0.96 s**, 125/125 races finished
  - Redis never the bottleneck: < 50 % CPU, < 20 MiB
- 2026-10-29 Redis store latency, `npm run bench:redis`, 1000 rounds, local Docker Redis (Ubuntu laptop). Store calls only, not the browser round trip:
  - join (get + addPlayer + get): p50 0.43 ms · p95 0.69 ms · p99 1.08 ms
  - word (get + update + get): p50 0.39 ms · p95 0.64 ms · p99 0.97 ms
