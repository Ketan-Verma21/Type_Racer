# Type Racer — Architecture (v2 target)

> How the system is built: flows, components, folder structure, tech stack, data design.
> v1 as-is is documented in `PROJECT_OVERVIEW.md`. This file describes the **target**; `Phases.md` gives the order.

---

## 1. Tech stack

| Layer | Technology | Notes |
|---|---|---|
| Client | Flutter 3 (Dart ≥ 3.1), Provider | Existing app; web + Android |
| Client realtime | `socket_io_client` **^3.x** (Socket.IO v4 protocol) | Upgraded from 1.x in Phase 5 |
| Client tests | `flutter_test`, `mocktail` | Unit + widget tests |
| Server language | **TypeScript 5, `strict: true`**, compiled to CommonJS | Rewritten in Phase 1 |
| Server runtime | Node.js 20 LTS | Windows: nvm-windows; Ubuntu: nvm |
| Dev runner / build | `tsx` (watch mode), `tsc` → `dist/` | |
| HTTP | Express 4 | `/health/*` |
| Realtime | Socket.IO **4.x** + `@socket.io/redis-adapter` | v2 until Phase 5 |
| Datastore | **Redis 7 only**, via `ioredis` | Live state, timers, chat, presence, rate limits, quote pool, leaderboard, match history. **No MongoDB.** |
| Events | `EventPublisher` interface → in-process (Phase 4) → **Kafka** (Phase 7) via `@confluentinc/kafka-javascript` | Post-race events only |
| Validation | `zod` | Env vars + every socket payload; types inferred from schemas |
| Logging | `pino` | JSON logs |
| Server tests | **Vitest** + `@vitest/coverage-v8`, `supertest`, `socket.io-client`, `ioredis-mock` | |
| Lint/format | ESLint (`typescript-eslint`) + Prettier | |
| Reverse proxy / LB | Nginx (stable) | WebSocket upgrade, load balancing, rate limiting |
| Containers | Docker Engine + Docker Compose (Ubuntu) | From Phase 3 |
| Load testing | Artillery (Socket.IO engine) | Phase 6 |
| Quotes | API Ninjas + bundled `data/quotes.json` | |
| Monitoring | Sentry (client) | Existing |

### 1.1 Environments

| Env | Where | Redis | Kafka | Instances |
|---|---|---|---|---|
| Dev (Phases 0–2) | Windows, `npm run dev` | none (in-memory repositories) | none | 1 |
| Dev (Phase 3+) | Ubuntu, Docker Compose | `redis:7` container, AOF on | `apache/kafka` KRaft container (Phase 7) | 1 → 3 behind Nginx |
| Production | Render free web service | Render Key Value (free, no persistence) | off (in-process publisher) or Aiven free tier | 1 |

---

## 2. System overview

### 2.1 Deployment (Docker Compose, Phase 7 complete)

```
                 Flutter app (web / Android)
                           │  ws / http  (wss/https in prod)
                           ▼
                ┌─────────────────────┐
                │        Nginx        │  :80
                │  WebSocket upgrade  │
                │  load balancing     │
                │  rate limiting      │
                └──────────┬──────────┘
          ┌────────────────┼────────────────┐
          ▼                ▼                ▼
     ┌─────────┐      ┌─────────┐      ┌─────────┐
     │  app1   │      │  app2   │      │  app3   │   identical, stateless game servers
     └────┬────┘      └────┬────┘      └────┬────┘
          │  live state +  │  pub/sub        │        publish match events
          ▼                ▼                 ▼               │
     ┌───────────────────────────────────────────┐          ▼
     │                 Redis 7                    │   ┌──────────────┐
     │ rooms · players · clock · chat · presence  │   │    Kafka     │ topics: match.started,
     │ rate limits · quote pool · leaderboard ·   │   │   (KRaft)    │ match.finished, player.finished
     │ match history · Socket.IO adapter channels │   └──────┬───────┘
     └───────────────────────────────────────────┘          │ consume (group: stats-worker)
                         ▲                                    ▼
                         │  ZADD leaderboard, LPUSH history  ┌──────────────┐
                         └───────────────────────────────────│ stats-worker │
                                                             └──────────────┘
```

- **Nginx** forwards clients to an app instance, passing WebSocket upgrade headers; `ip_hash` keeps a client on one instance (needed only for HTTP long-polling fallback, harmless otherwise).
- **App instances** hold **no mutable game state in memory**. Any instance can process any event.
- **Redis** is the single source of truth and the pub/sub bus for the Socket.IO adapter (`io.to(room).emit()` on app2 reaches sockets on app1/app3).
- **Kafka** carries facts that already happened (a match finished). Nothing in a running race waits on Kafka. If Kafka or the worker is down, races are unaffected; the worker catches up later.

### 2.2 Client ↔ server responsibilities

The **server owns the game**. The client sends intent and renders the broadcast state. Client-side letter colouring is a visual hint only.

---

## 3. Server design

### 3.1 Layers

```
transport (socket handlers, http routes)    ← knows Socket.IO / Express, no game rules
        │
        ▼
services (use cases)                         ← depend only on interfaces
        │
        ▼
domain (pure TS: modes, rules, settings, wpm, room codes, errors)

interfaces (ports):  GameRepository · ChatRepository · SessionStore · QuoteProvider
                     EventPublisher · LeaderboardRepository · MatchHistoryRepository
                     Clock · IdGenerator · Broadcaster · RateLimiter
        ▲ implemented by
infra (adapters):    InMemory* (tests + Phases 1–3) · Redis* (Phase 4+) · Kafka* (Phase 7)
                     ApiNinjas/Local quotes · SystemClock · SocketIoBroadcaster
```

Dependencies point **inward**. `container.ts` (composition root) is the only file that chooses concrete classes, based on config (`STORE=memory|redis`, `EVENTS=inprocess|kafka`).

### 3.2 Folder structure

```
server/
├── src/
│   ├── index.ts                     # entry: game server (http + socket.io + sweepers)
│   ├── worker.ts                    # entry: stats-worker (Kafka consumer) — Phase 7
│   ├── app.ts                       # builds the Express app (exported for supertest)
│   ├── container.ts                 # composition root: wires every dependency
│   ├── config/
│   │   ├── env.ts                   # zod-validated env → typed `config`
│   │   └── constants.ts             # modes, limits, timings, TTLs
│   ├── domain/                      # PURE — no I/O, no Date.now(), no Math.random()
│   │   ├── types.ts                 # Game, Player, GameSettings, Phase, MatchResult
│   │   ├── modes/
│   │   │   ├── ModeStrategy.ts      # interface + BaseMode (default shouldEnd)
│   │   │   ├── ClassicMode.ts
│   │   │   ├── FlawlessMode.ts
│   │   │   ├── SuddenDeathMode.ts
│   │   │   └── modeRegistry.ts
│   │   ├── rules.ts                 # isFinished, racersOf, rankPlayers
│   │   ├── settings.ts              # normalizeSettings
│   │   ├── wpm.ts
│   │   ├── roomCode.ts              # alphabet + isValidRoomCode
│   │   ├── antiCheat.ts             # isSuspicious(result) — Phase 7
│   │   └── errors.ts                # DomainError, NotFoundError, ForbiddenError, RoomFullError, ValidationError
│   ├── ports/                       # interfaces only (one file each)
│   │   ├── GameRepository.ts  ChatRepository.ts  SessionStore.ts  QuoteProvider.ts
│   │   ├── EventPublisher.ts  LeaderboardRepository.ts  MatchHistoryRepository.ts
│   │   └── Clock.ts  IdGenerator.ts  Broadcaster.ts  RateLimiter.ts
│   ├── services/
│   │   ├── GameService.ts           # create, join, settings, submitWord, rematch, leave
│   │   ├── RaceClock.ts             # countdown/race clock driven by the sweeper
│   │   ├── Sweeper.ts               # 1 s loop: ticks, transitions, presence expiry
│   │   ├── ChatService.ts
│   │   ├── PresenceService.ts       # disconnect grace / reattach
│   │   ├── QuoteService.ts          # getWords(minWords)
│   │   └── StatsService.ts          # applies match events → leaderboard/history (used by worker or in-process)
│   ├── adapters/
│   │   ├── memory/                  # InMemoryGameRepository, InMemoryChatRepository, ... (tests + early phases)
│   │   ├── redis/                   # RedisGameRepository, RedisChatRepository, RedisSessionStore,
│   │   │                            # RedisRateLimiter, RedisQuotePool, RedisLeaderboard, RedisMatchHistory, keys.ts, scripts/*.lua
│   │   ├── kafka/                   # KafkaEventPublisher, KafkaStatsConsumer, topics.ts — Phase 7
│   │   ├── events/InProcessEventPublisher.ts   # calls StatsService directly
│   │   ├── quotes/                  # ApiNinjasQuoteProvider, LocalQuoteProvider, FallbackQuoteProvider
│   │   ├── SystemClock.ts  RandomIdGenerator.ts
│   │   └── socket/SocketIoBroadcaster.ts
│   ├── transport/
│   │   ├── http/health.ts
│   │   └── socket/
│   │       ├── index.ts             # connection setup, registers handlers
│   │       ├── events.ts            # event-name constants
│   │       ├── schemas.ts           # zod schema per event (+ inferred payload types)
│   │       ├── withHandler.ts       # validate → call → catch → emit error
│   │       ├── gameHandlers.ts  chatHandlers.ts  connectionHandlers.ts
│   │       └── gameDto.ts           # domain Game → v1-compatible `updateGame` payload
│   └── infra/
│       ├── redis.ts                 # ioredis clients (cmd, pub, sub)
│       └── logger.ts                # pino
├── data/quotes.json
├── tests/
│   ├── unit/                        # domain + services with fakes
│   ├── contract/                    # one suite per port, run against every adapter
│   ├── integration/                 # supertest, socket.io-client, two-instance test
│   └── fakes/                       # FakeClock, FakeBroadcaster, FakeQuoteProvider, FakeEventPublisher
├── nginx/nginx.conf
├── Dockerfile                       # node:20-slim (Debian: needed by the native Kafka client)
├── docker-compose.yml
├── tsconfig.json  vitest.config.ts  eslint.config.mjs  .prettierrc
├── .env.example
└── package.json
```

### 3.3 SOLID map

| Principle | Where it shows up |
|---|---|
| **S** | Handlers only validate + delegate; `GameService` = use cases; `rules.ts` = pure rules; `RaceClock`/`Sweeper` = time; `SocketIoBroadcaster` = emitting; `gameDto` = payload shape; `StatsService` = stats. |
| **O** | New game mode = new `ModeStrategy` + registry entry. New quote source = new `QuoteProvider` in the fallback chain. New event consumer = new Kafka consumer group, publishers untouched. |
| **L** | Every adapter passes its port's **contract test suite** (`InMemoryGameRepository` and `RedisGameRepository` run the same tests; `InProcessEventPublisher` and `KafkaEventPublisher` satisfy the same `EventPublisher` contract). |
| **I** | Small ports: `QuoteProvider.getQuote()`, `Clock.now()`, `Broadcaster.toRoom()`, `RateLimiter.allow()`, `EventPublisher.publish()`. |
| **D** | Services take ports in their constructors; only `container.ts` does `new RedisGameRepository(...)`. Tests pass fakes. |

### 3.4 Key interfaces (sketch)

```ts
export interface ModeStrategy {
  readonly id: ModeId;                                   // 'classic' | 'no-mistakes' | 'sudden-death'
  onCorrectWord(p: Player, g: Game, now: number): PlayerPatch;
  onWrongWord(p: Player, g: Game, now: number): PlayerPatch | null;   // null = ignore
  shouldEnd(g: Game): boolean;
}

export interface GameRepository {
  create(game: Game): Promise<void>;
  get(code: RoomCode): Promise<Game | null>;
  addPlayer(code: RoomCode, p: Player, maxRacers: number): Promise<'ok' | 'full'>;  // atomic
  updatePlayer(code: RoomCode, id: PlayerId, patch: PlayerPatch): Promise<void>;
  removePlayer(code: RoomCode, id: PlayerId): Promise<void>;
  updateMeta(code: RoomCode, patch: Partial<GameMeta>): Promise<void>;
  delete(code: RoomCode): Promise<void>;
  touch(code: RoomCode): Promise<void>;                  // refresh TTL
}

export interface EventPublisher {
  publish<E extends DomainEvent>(event: E): Promise<void>;   // fire-and-forget for callers
}
export type DomainEvent =
  | { type: 'match.started';  gameId: string; round: number; mode: ModeId; players: number; at: number }
  | { type: 'player.finished'; gameId: string; round: number; playerId: string; nickname: string; wpm: number; at: number }
  | { type: 'match.finished'; gameId: string; round: number; mode: ModeId; results: MatchResult[]; at: number };
```

### 3.5 Error handling flow

```
socket event → withHandler(schema, fn)
                 ├─ payload invalid ─────► emit 'error-message' {code:'BAD_REQUEST'}  (+ 'notCorrectGame' for create/join, v1 client)
                 ├─ DomainError thrown ──► emit 'error-message' {code, message}        (log info)
                 └─ unknown error ───────► emit {code:'INTERNAL'} + log error with gameId/event/instanceId
```
Handlers never crash the process. Services throw typed `DomainError`s instead of returning `null`. `EventPublisher.publish` failures are logged and never propagate into gameplay.

---

## 4. Key flows

### 4.1 Create room
1. `create-game {nickname}` → validate → `GameService.create`.
2. `QuoteService.getWords(minWords)`: `RedisQuotePool` (pop) → `ApiNinjasQuoteProvider` (3 s timeout) → `LocalQuoteProvider`; quotes concatenated until `minWords`.
3. Reserve a 6-char code (`SET room:{code} 1 NX EX 7200`, retry on collision); write game + host player.
4. Save session, `socket.join(code)`, emit `joined {gameId, playerId}`, broadcast `updateGame`.

### 4.2 Join room (many players reading the same game id)
1. `join-game {nickname, gameId}` → validate code format → `GameRepository.get` (Redis hash read, O(1)).
2. Lobby → `addPlayer` with an atomic capacity check (Lua script) so concurrent joins can't exceed `maxPlayers`; racing/over → spectator.
3. Emit `joined`, broadcast `updateGame` (reaches every instance through the Redis adapter).

### 4.3 Submit word (hot path)
1. `userInput {word}` → session → rate limiter → `GameService.submitWord`.
2. Read game meta + this player's hash; quote words from a **per-instance LRU cache** keyed `{code}:{round}` (immutable during a round).
3. Correct → `HINCRBY idx 1`; wrong → `mode.onWrongWord` patch → `HSET`. Only this player's socket writes this player's hash → no contention.
4. Broadcast `updateGame`; if `mode.shouldEnd(game)` → `RaceClock.end`. A player finishing publishes `player.finished`.

### 4.4 Countdown & race clock (instance-independent)
- Host `timer` → `phase=countdown`, `countdownEndsAt = now + 5000`, `ZADD games:countdown`.
- Every instance runs `Sweeper` **once per second** (aligned to the wall-clock second):
  - **Ticks:** for each active game, `SET tick:{code}:{secondsLeft} 1 NX EX 5`; the instance that wins emits that second's `timer` event — exactly one emit per second, from whichever instance is alive.
  - **Transitions:** `ZRANGEBYSCORE games:countdown -inf now` → `ZREM` (returns 1 for exactly one instance = the claim) → `phase=racing`, `startTime`, `endsAt`, `ZADD games:racing`, publish `match.started`. Same pattern ends races at `endsAt`.
  - **Presence:** `ZRANGEBYSCORE presence:grace -inf now` → claim with `ZREM` → remove player.
- Cost ≈ 2–3 Redis commands per instance per second + 1 per active game per second → fits free tiers.

### 4.5 Disconnect / reconnect
1. `disconnect` → `connected=0`, `ZADD presence:grace now+15000 {code}:{pid}`.
2. Reconnect (any instance) → `rejoin-game {gameId, playerId}` → `ZREM presence:grace` → new `socketId`, new session, join room, broadcast.
3. Expired grace → sweeper removes the player, hands over host if needed, may end the race.

### 4.6 Race end & stats
1. `RaceClock.end` → fill WPM for unfinished racers → `phase=over` → broadcast `updateGame` + `done`.
2. `EventPublisher.publish(match.finished)` (non-blocking).
3. **Phase 4–6 (`InProcessEventPublisher`)**: calls `StatsService` directly → `ZADD leaderboard:{mode} GT`, `LPUSH matches:recent` + `LTRIM 499`, `LPUSH game:{code}:history` + `LTRIM 19`.
4. **Phase 7+ (`KafkaEventPublisher`)**: produce to `match.finished` (key = gameId) → `stats-worker` (consumer group `stats-worker`) runs the same `StatsService` + anti-cheat; offsets committed after the Redis writes succeed. Writes are idempotent (`SET stats:done:{gameId}:{round} NX`) so replays don't double-count.

---

## 5. Redis design

### 5.1 Keys

| Key | Type | Contents | TTL |
|---|---|---|---|
| `room:{code}` | string | code reservation | 2 h |
| `game:{code}` | hash | `phase` (lobby·countdown·racing·over), `mode`, `timeLimit`, `length`, `maxPlayers`, `hostId`, `round`, `startTime`, `endsAt`, `countdownEndsAt`, `createdAt` | 2 h, refreshed on activity |
| `game:{code}:words` | string (JSON) | words of the current round | same |
| `game:{code}:players` | sorted set | playerIds, score = join time (lane order) | same |
| `game:{code}:player:{pid}` | hash | `nickname`, `socketId`, `idx`, `wpm`, `isSpectator`, `isEliminated`, `mistakes`, `connected` | same |
| `game:{code}:chat` | list | last 30 messages | same |
| `game:{code}:history` | list | last 20 round results | same |
| `socket:{socketId}` | hash | `gameId`, `playerId`, `nickname` | 1 h |
| `games:countdown` / `games:racing` | sorted set | code → deadline (ms) | — |
| `presence:grace` | sorted set | `{code}:{pid}` → removal time | — |
| `tick:{code}:{n}` | string | per-second tick claim | 5 s |
| `quotes:pool` | list | pre-fetched quotes | — |
| `rl:{event}:{socketId}` | string counter | rate-limit window | window |
| `leaderboard:{mode}` | sorted set | `nickname` → best WPM (`ZADD GT`) | — |
| `matches:recent` | list | last 500 match results (JSON) | — |
| `stats:done:{gameId}:{round}` | string | idempotency marker for the worker | 1 day |
| Socket.IO adapter | pub/sub | managed by `@socket.io/redis-adapter` | — |

All keys are built by `adapters/redis/keys.ts` — never inline strings.

### 5.2 Why Redis is the source of truth (and why MongoDB was removed)
Rooms live for minutes and need sub-millisecond reads/writes; a cache in front of Mongo would still write Mongo on every word and the two copies would drift. The only durable data left (leaderboard, recent matches) fits Redis sorted sets and capped lists. In Docker, Redis runs with `--appendonly yes` so this survives restarts; on Render's free Key Value it is best-effort. If accounts are added later, a relational DB (PostgreSQL) comes back for user data.

### 5.3 In-process caches (allowed)
Only immutable data: quote words per `{code}:{round}` (LRU, 500 entries).

---

## 6. Kafka design (Phase 7)

| Topic | Key | Producer | Consumers |
|---|---|---|---|
| `match.started` | gameId | game servers | stats-worker (counts matches/modes) |
| `player.finished` | gameId | game servers | stats-worker (anti-cheat timing) |
| `match.finished` | gameId | game servers | stats-worker (leaderboard, history) |

- 3 topics × 2 partitions (fits Aiven free tier: 5 topics, 2 partitions each). Key = gameId → events of one game stay ordered.
- Local: single `apache/kafka` broker in KRaft mode (no ZooKeeper) in Compose.
- Producer: `acks=all`, idempotent producer on; publish failures logged, never thrown to gameplay.
- Consumer: group `stats-worker`, manual commit after successful Redis writes, idempotency marker per `{gameId}:{round}`.
- Learning experiments: stop the worker, play races, restart → it catches up; run 2 workers → partitions split between them; reset offsets → replay rebuilds the leaderboard.

---

## 7. Nginx

```nginx
upstream typeracer_app {
    ip_hash;
    server app1:3000;
    server app2:3000;
    server app3:3000;
}

map $http_upgrade $connection_upgrade { default upgrade; '' close; }
limit_req_zone $binary_remote_addr zone=perip:10m rate=20r/s;

server {
    listen 80;

    location /socket.io/ {
        proxy_pass http://typeracer_app;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 120s;
    }

    location /health {
        proxy_pass http://typeracer_app;
    }

    location / {
        limit_req zone=perip burst=40 nodelay;
        proxy_pass http://typeracer_app;
    }
}
```

### 7.1 Docker Compose services
`nginx` (only exposed port: 80) · `app1..app3` (same image, `INSTANCE_ID`) · `redis:7` (`--appendonly yes`, volume) · `kafka` (Phase 7) · `stats-worker` (Phase 7, same image, `node dist/worker.js`). Health checks on `/health/ready`.

---

## 8. Client design

### 8.1 Folder structure

```
lib/
├── main.dart                     # Sentry init + runApp
├── app.dart                      # MultiProvider (wiring) + MaterialApp + routes
├── config/env.dart               # SERVER_URL from --dart-define
├── core/ theme/ · sound/ · haptics/
├── data/
│   ├── models/                   # Game, Player, GameSettings, ChatMessage, Reaction, TimerState, LeaderboardEntry
│   ├── socket/ socket_client.dart · socket_events.dart
│   ├── repositories/ game_repository.dart (abstract) · socket_game_repository.dart
│   └── services/server_health_service.dart
├── domain/                       # pure Dart: game_modes, ranking, wpm, elapsed time, typing_stats, room_code
├── state/                        # ChangeNotifiers depending on GameRepository
└── ui/
    ├── screens/ home · create_room · join_room · leaderboard · game/{game_screen.dart, views/lobby|race|watch|results}
    └── widgets/
test/
├── unit/
└── widget/
```

### 8.2 Client principles
- Widgets → state (ChangeNotifier) → `GameRepository` (abstract) → socket. Tests use `FakeGameRepository`.
- Typed models instead of raw `Map`s.
- "Me" = `playerId` from the `joined` event, not `socket.id`.

---

## 9. Socket contract

v1 event names are kept (`PROJECT_OVERVIEW.md §6`) so the v1 client works until Phase 5. Changes:

| Event | Dir | Payload | Phase |
|---|---|---|---|
| `error-message` | S→C | `{code, message}` | 2 |
| `joined` | S→C | `{gameId, playerId}` | 2 |
| `get-leaderboard` / `leaderboard` | C→S / S→C | `{mode}` / `{mode, entries:[{nickname, wpm}]}` | 4 |
| `updateGame` | S→C | v1 shape (`_id`, `players[]` with `_id`, `isJoin`, `isOver`, `words`, `settings`) built by `gameDto` | — |
| `timer` (C→S) | | `playerId` field ignored; host comes from the session | 0 |
| room codes | | 6-char codes instead of 24-hex ids | 4 |

---

## 10. Testing strategy

| Level | Server (Vitest) | Client (flutter_test) |
|---|---|---|
| Unit | `domain/*`, mode strategies, services with in-memory adapters + `FakeClock`, `FakeBroadcaster`, `FakeQuoteProvider`, `FakeEventPublisher` | `domain/*`, models, ChangeNotifiers with `FakeGameRepository` |
| Contract | one suite per port, run against memory + Redis (`ioredis-mock`; real Redis in Docker optional) adapters | — |
| Widget | — | RaceLane, Scoreboard, SettingsPanel, StatsBar, game views |
| Integration | supertest `/health`; socket.io-client vs in-process server; two servers sharing Redis | — |
| System | Compose + Artillery load test; kill-instance / kill-worker experiments | manual regression checklist |

Commands: `cd server && npm test` · `npm run test:coverage` · `flutter test --coverage`.

---

## 11. Configuration

`server/.env.example`
```
NODE_ENV=development
PORT=3000
INSTANCE_ID=app1
STORE=memory            # memory | redis
EVENTS=inprocess        # inprocess | kafka
REDIS_URL=redis://localhost:6379
KAFKA_BROKERS=localhost:9092
QUOTES_API_URL=https://api.api-ninjas.com/v2/quotes
QUOTES_API_KEY=
LOG_LEVEL=info
```
Client: `flutter run --dart-define=SERVER_URL=http://<host>`.

---

## 12. Dev machines

| | Windows (Phases 0–2) | Ubuntu (Phase 3+) |
|---|---|---|
| Node | 20.19.5 via nvm-windows 1.2.2 | nvm + Node 20 (install in Phase 3) |
| Flutter | `D:\Flutter\sdk` | install in Phase 3 (+ Chrome for `flutter run -d chrome`) |
| Docker | not used | Docker Engine + Compose plugin |
| Redis/Kafka | not needed (`STORE=memory`) | containers |

Code moves via GitHub (two repos: root + `server/`). `.env` files are copied manually. `.gitattributes` forces LF line endings.
