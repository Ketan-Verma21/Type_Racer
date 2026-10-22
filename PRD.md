# Type Racer — Product Requirements Document (PRD)

| | |
|---|---|
| Version | 2.1 — "Scale & Quality" rewrite |
| Owner | Ketan Verma |
| Status | Approved plan |
| Last updated | 2026-10-22 |
| Related | `Architecture.md`, `Rules.md`, `Phases.md`, `Design.md`, `PROJECT_OVERVIEW.md` (v1 analysis) |

---

## 1. Summary

Type Racer is a real-time multiplayer typing race (Flutter app + Node.js/Socket.IO server). v1 works for a handful of friends on a single free-tier server. **v2 keeps every v1 feature but rebuilds the backend in TypeScript so it can run as many identical server instances behind Nginx, sharing live state through Redis, with SOLID-structured code, unit tests on both client and server, and an optional Kafka event pipeline for stats.**

v2 is also a learning project: the owner wants hands-on experience with SOLID, TypeScript, Redis, Nginx, Kafka, horizontal scaling and unit testing. Where there is a choice, prefer the option that teaches the concept clearly over the cleverest one.

## 2. Problem statement

| v1 limitation | Impact |
|---|---|
| Timers, chat history and reconnect timeouts live in one process's memory | Cannot run more than one server instance; a restart mid-race freezes every running game |
| Every submitted word does a MongoDB `findById` + full `save` | Database is the bottleneck; many players reading the same game id hammer Mongo |
| Game rules, persistence and socket code are mixed; `GameScreen` is 726 lines | Hard to change, hard to test, risky to extend (e.g. new game modes) |
| No tests (only a broken default Flutter test) | Every change is verified by hand |
| Quote length setting is ignored; no fallback if the quote API fails | Settings lie to the user; room creation can hang silently |
| Host check trusts a client-supplied `playerId` | Any player who knows the host's id can start the race |

## 3. Goals

- **G1 — Horizontal scale.** Any number of stateless server instances behind Nginx; any instance can handle any event for any room.
- **G2 — Redis only.** Live game state, chat, presence, leaderboard and recent match history live in Redis. **MongoDB is removed.**
- **G3 — Clean, typed design.** Server rewritten in TypeScript (strict); server and client follow SOLID; game modes, quote sources, storage and event transport are swappable without editing existing logic.
- **G4 — Tested.** Unit tests (Vitest on the server, `flutter_test` on the client), run automatically in CI.
- **G5 — Correctness.** Fix all v1 bugs listed in `PROJECT_OVERVIEW.md §10`.
- **G6 — No regression.** Players never lose a v1 feature; every phase leaves the app shippable.
- **G7 — Event streaming (learning).** Game servers publish match events to Kafka; a separate stats worker builds the leaderboard, match history and anti-cheat flags.

## 4. Non-goals (v2)

- Accounts / login, profiles, friends (future, §7.3 — would bring back a durable database such as PostgreSQL).
- Kafka on the real-time path (words, ticks) — Kafka is only for after-the-fact events.
- Native iOS/desktop polish (Flutter web + Android are the primary targets).
- Kubernetes or managed autoscaling — Docker Compose + Nginx is the scaling target.
- A visual redesign — the neon-arcade look stays (`Design.md`).

## 5. Target users

| Persona | Description | Needs |
|---|---|---|
| **Friend group (primary)** | 2–8 friends racing for fun on phones or browsers, sharing a room code over chat | Fast room join, fair results, chat & reactions, rematch, works on flaky mobile data |
| **Typing learner (secondary)** | Student practising speed/accuracy | Accurate WPM/accuracy, quote length choice, modes that punish mistakes, a leaderboard to beat |
| **Developer / owner (stakeholder)** | Ketan — maintains and extends the project, uses it as a portfolio piece | Readable typed architecture, tests, measurable scaling, docs an AI assistant can follow |

## 6. Existing features (v1 — must keep working)

- Create room / join by code; up to 8 players; host = room creator, passed on if host leaves.
- Lobby with host-only settings: mode, time limit (30/60/90/120 s), quote length, max players.
- Modes: Classic, Flawless (wrong word → back to start), Sudden Death (wrong word → out).
- 5-second countdown, server-driven race clock.
- Live race lanes with cars, live WPM, local accuracy, per-letter feedback, shaking input on error.
- Spectators (join mid-race, promoted into the next round).
- Lobby chat (history of 30), emoji reactions floating on every screen.
- Results scoreboard with medals, confetti, sounds, haptics, mute.
- Reconnect grace period (15 s) keeps your place after a drop.
- Server wake-up handling for free-tier hosting (`/health` polling + banner).

## 7. Requirements

Priority: **Must** · **Should** · **Could**.

### 7.1 Functional

| ID | Requirement | Priority |
|---|---|---|
| FR-1 | Quote length setting controls length: short ≥ 12, medium ≥ 25, long ≥ 45 words (combine quotes if needed). | Must |
| FR-2 | Room creation never fails because of the quote API: fall back to a bundled local quote set. | Must |
| FR-3 | Pre-fetched pool of quotes in Redis so creating/rematching a room needs no external API call. | Should |
| FR-4 | Host-only actions (start, settings, rematch) are authorised from the server-side session, never from client payloads. | Must |
| FR-5 | Create and Join always get a response (success or a readable error) within 10 s; the client shows a loading state until then. | Must |
| FR-6 | Reconnect works even if the new connection lands on a different server instance. | Must |
| FR-7 | Countdown and race clock keep running if the instance that started them dies. | Must |
| FR-8 | Chat history and reactions work across instances. | Must |
| FR-9 | Rate limits (chat 1 msg / 500 ms, reaction 1 / 200 ms, words ≤ 20 / s) enforced across instances. | Should |
| FR-10 | Abandoned rooms expire automatically (idle TTL 2 h). | Must |
| FR-11 | Short room codes: 6 characters from an unambiguous alphabet (no 0/O/1/I), e.g. `K7P2QX`. | Must |
| FR-12 | Recent match results kept in Redis (last 20 per room, last 500 overall). | Should |
| FR-13 | `/health/live` and `/health/ready` (Redis reachable); `/health` kept for the v1 wake-up check. | Must |
| FR-14 | Client server URL configurable per environment (`--dart-define=SERVER_URL=...`). | Must |
| FR-15 | Global leaderboard (best WPM per mode) in a Redis sorted set, shown in the app. | Should |
| FR-16 | Match events (`match.started`, `match.finished`, `player.finished`) published through an `EventPublisher`; with Kafka enabled, a stats worker consumes them to update leaderboard, history and anti-cheat flags. | Should |
| FR-17 | Anti-cheat: flag results with impossible WPM (> 250) or words faster than humanly possible; flagged results are excluded from the leaderboard. | Could |
| FR-18 | App branded "Type Racer" everywhere (title, Android label, web title/manifest, package id). | Must |

### 7.2 Non-functional

| ID | Requirement |
|---|---|
| NFR-1 Scalability | Server instances are stateless; scaling = adding instances to the Nginx upstream. Verified with 3 instances in Docker Compose. |
| NFR-2 Capacity | ≥ 1,000 concurrent sockets (≈ 125 full rooms) on the 3-instance local setup, measured with a load test. |
| NFR-3 Latency | p95 submitted word → `updateGame` broadcast < 100 ms on LAN under target load. |
| NFR-4 Resilience | Kill one instance mid-race: players reconnect within the 15 s grace and the race finishes correctly. Kill the stats worker: no gameplay impact; it catches up on restart. |
| NFR-5 Testability | Domain logic pure. Server `domain/` + `services/` ≥ 80 % line coverage; Flutter `domain/` + models ≥ 80 %. |
| NFR-6 Maintainability | TypeScript `strict`; SOLID boundaries per `Architecture.md`; guideline max ~300 lines per file. |
| NFR-7 Security | Secrets only in env vars; every socket payload validated (zod); Nginx rate limiting; no PII to Sentry by default. |
| NFR-8 Observability | Structured JSON logs (`instanceId`, `gameId`, `event`); Sentry on the client. |
| NFR-9 Compatibility | Each phase keeps client and server compatible or ships both together. |
| NFR-10 Cost | Runs at ₹0: Docker locally; production on Render free web service + Render Key Value free; Kafka online optional on Aiven free tier. Redis usage designed to stay well inside free-tier limits (1 s sweeper). |

### 7.3 Future (after v2)

Login & profiles (with PostgreSQL) · per-user leaderboard history · public matchmaking queue · power-ups · custom quotes per room · VPS deployment with HTTPS · Codemagic builds.

## 8. Success metrics

- All Must requirements done; all v1 features pass a manual regression checklist.
- Server and client tests green in CI; coverage targets met.
- Load-test report for NFR-2/3 with 3 instances, plus the kill-an-instance and kill-the-worker experiments.
- Adding a fourth game mode requires only a new strategy class + registry entry.
- Swapping in-memory → Redis storage and in-process → Kafka events requires changes only in `container.ts`.

## 9. Constraints & assumptions

- Solo developer, ₹0 infrastructure budget.
- **Dev machines:** Phases 0–2 on Windows (Node 20.19 via nvm-windows, Flutter at `D:\Flutter\sdk`, no Docker). Phase 3 onward on Ubuntu (Docker Engine, Node, Flutter installed in Phase 3). Code moves between them through GitHub.
- Production today: Render free web service, Firebase Hosting (web), API Ninjas free key. MongoDB Atlas is retired in v2.
- Render free Key Value has no persistence: leaderboard/history reset when Render restarts it (accepted — best effort).
- `server/` is a separate git repository (`TypeRacerServer`).

## 10. Decisions (closed 2026-10-22)

| # | Decision |
|---|---|
| D1 | Server rewritten in **TypeScript** (strict), tests with **Vitest**. |
| D2 | Build multi-instance locally with Docker Compose; production stays on Render (single instance + Key Value). |
| D3 | Short 6-character room codes replace 24-character ids. |
| D4 | Rename to "Type Racer" everywhere. |
| D5 | **MongoDB removed**; Redis is the only datastore (Docker Redis runs with AOF persistence). |
| D6 | Kafka added as a dedicated phase for post-race events only. |
