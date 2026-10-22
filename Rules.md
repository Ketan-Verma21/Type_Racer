# Type Racer — Rules for AI Assistants

> Read this file, then `Memory.md`, before writing any code. These rules override your defaults.
> Reference docs: `PRD.md` (what), `Architecture.md` (how), `Phases.md` (order), `Design.md` (look), `Memory.md` (progress).

---

## 1. Workflow

1. **Start of every session:** read `Rules.md` → `Memory.md` → the current phase in `Phases.md`. Do not re-read the whole codebase; open only the files the task needs.
2. **One phase at a time.** Only work on tasks in the current phase. If something from a later phase is needed, stop and say so.
3. **Small steps.** Change one thing, run the tests, move on. Prefer several small commits to one big one.
4. **Plan before big changes.** Anything touching more than ~5 files: write a short plan (files, tests) and wait for approval.
5. **Ask, don't guess,** when a requirement is unclear or a new dependency is needed.
6. **End of every task/session:** update `Memory.md` (done, decisions, next, issues) and tick boxes in `Phases.md`.
7. Never claim something works without running it. Report test results honestly, including failures.
8. Check which machine the current phase runs on (`Phases.md`): Windows phases have **no Docker, Redis or Kafka** — use in-memory adapters.

## 2. Definition of done (every task)

- [ ] Code is in the right layer/folder (`Architecture.md §3.2`, `§8.1`).
- [ ] Tests added/updated; `npm test`, `npm run typecheck`, `npm run lint` and/or `flutter test`, `flutter analyze` pass.
- [ ] v1 features still work when gameplay is touched (create → join → race → results → rematch).
- [ ] Socket contract changes recorded in `Architecture.md §9`, client and server updated together.
- [ ] `Memory.md` updated.

## 3. Libraries

### Server — allowed
Runtime: `express@4`, `socket.io` (v2 until Phase 5, then v4), `@socket.io/redis-adapter`, `ioredis`, `@confluentinc/kafka-javascript` (Phase 7), `axios`, `dotenv`, `zod`, `pino`, `lru-cache`.
Dev: `typescript`, `tsx`, `@types/*`, `vitest`, `@vitest/coverage-v8`, `supertest`, `socket.io-client`, `ioredis-mock`, `eslint` + `typescript-eslint`, `prettier`, `pino-pretty`, `artillery` (+ Socket.IO engine).

### Server — avoid
- MongoDB / Mongoose or any other database (Redis only — PRD D5).
- Other frameworks (Nest, Fastify, Koa), other Redis clients (`redis`/node-redis), ORMs.
- `kafkajs` (not actively maintained) — use `@confluentinc/kafka-javascript`.
- `socket.io-redis` (deprecated) — use `@socket.io/redis-adapter`.
- DI frameworks (`inversify`, `tsyringe`, `awilix`) — wire by hand in `container.ts`.
- `ts-node`, `nodemon`, Jest — use `tsx` and Vitest.
- The npm `http` package (Node's built-in only).

### Client — allowed
Existing packages in `pubspec.yaml`, plus `mocktail` (dev). `socket_io_client` → `^3.x` in Phase 5 only.

### Client — avoid
- Other state management (Riverpod, Bloc, GetX, MobX). **Stay on Provider.**
- Code generation (freezed, json_serializable) — hand-written `fromJson`.
- New UI kits; follow `Design.md`.

**Any dependency not listed here requires asking first.** Removing packages needs confirmation too.

## 4. Architecture rules

### Server
- `domain/` is **pure TypeScript**: no imports from Redis, Kafka, Socket.IO, Express, axios; no `Date.now()`, `Math.random()`, `process.env`. Time and ids are passed in.
- Services depend on **ports** (`src/ports/*`), never on adapters. Only `container.ts` imports concrete adapters.
- Socket handlers: validate (zod) → read session → call one service method → emit. No game rules in handlers.
- Every mode behaviour lives in a `ModeStrategy`. No `if (mode === ...)` outside `domain/modes/`.
- No mutable game state in process memory in Redis mode; only immutable caches (`Architecture.md §5.3`). No `setInterval` holding game state after Phase 5 — use the `Sweeper`.
- Multi-key Redis changes that must be consistent use `MULTI`, `WATCH` or Lua. Every room key has a TTL. Key names only from `adapters/redis/keys.ts`.
- Kafka is **never** on the real-time path. `EventPublisher.publish` must not block or throw into gameplay. Consumers must be idempotent.
- Host-only actions are authorised from the server session, never payload fields.

### Client
- Widgets never touch the socket. Widgets → state (ChangeNotifier) → `GameRepository`.
- Typed models from `data/models/`; no new `Map<String, dynamic>` through the UI.
- Pure logic in `domain/`, unit tested.
- Never use `BuildContext` inside a socket callback; capture what you need when registering.
- Files under ~300 lines; split widgets/views.

## 5. Error handling

### Server
- Services throw `DomainError` subclasses (`NotFoundError`, `ForbiddenError`, `RoomFullError`, `ValidationError`); never return `null`/`undefined` to signal failure.
- `withHandler` catches everything: DomainError → `error-message {code, message}`; unknown → `{code:'INTERNAL'}` + `logger.error` with `gameId`, `event`, `instanceId`, stack.
- No empty `catch {}`, no `console.log` (use `logger`), no `any` (use `unknown` + narrowing; zod for external data).
- External calls (quote API, Kafka) have timeouts (≤ 3 s) and fallbacks; failure never blocks a player.
- Invalid env → fail fast at startup (`config/env.ts`).
- Redis down → `/health/ready` returns 503.

### Client
- Every action waiting on the server shows a loading state with a 10 s timeout and a readable error.
- Show `error-message` / `notCorrectGame` in the existing snackbar style.
- Sound, haptics and Sentry failures are swallowed.
- No `print`; `debugPrint` in debug only.

## 6. Testing rules

- Test behaviour, not implementation. Names as sentences: `it('sends a flawless player back to word 0 on a wrong word')`.
- Arrange–Act–Assert; one behaviour per test.
- Unit tests use fakes (in-memory adapters, `FakeClock`, `FakeBroadcaster`, `FakeQuoteProvider`, `FakeEventPublisher`; `FakeGameRepository` in Dart). No network, real Redis or Kafka in unit tests.
- Every bug fix comes with a test that failed before the fix.
- Every adapter passes its port's contract suite (`tests/contract/`).
- Locations: `server/tests/{unit,contract,integration,fakes}/**/*.test.ts`; client `test/unit/**`, `test/widget/**`.
- Don't lower coverage targets to make CI pass.

## 7. Code style

- **TypeScript:** `strict: true`; 4-space indent, double quotes, semicolons (Prettier enforces); `async/await`; `camelCase` functions/vars, `PascalCase` classes/types/interfaces (no `I` prefix); one class per file, file name = class name; named exports only (no `export default`); `type` for unions/data shapes, `interface` for ports; `readonly` where possible; return types on exported functions.
- **Dart:** `flutter_lints`; `lowerCamelCase` members, `UpperCamelCase` types, `snake_case.dart` files; `const` constructors; `super.key`.
- Comments explain *why*. Keep the short, friendly comment style of the codebase.
- Event names, Redis keys, Kafka topics come from constants (`events.ts` / `socket_events.dart`, `keys.ts`, `topics.ts`).

## 8. Security & secrets

- Never print, commit or copy secrets: `server/.env`, `sentry.properties`, API keys, Redis/Kafka URLs with passwords. Keep `.env.example` with empty values.
- Never commit `sentry-wizard.exe`, `node_modules/`, `dist/`, `build/`, coverage output.
- Validate and length-limit every input (nickname ≤ 16, chat ≤ 140, word ≤ 50, room code = 6 chars from the code alphabet).
- Sentry `sendDefaultPii: false`.

## 9. Git & machines

- Two repos: root `Type_Racer` (Flutter) and `server/` (`TypeRacerServer`). The root repo **ignores** `server/`; commit server changes from inside `server/` only.
- Branch per phase: `phase-<n>-<short-name>`. Never commit directly to `master`/`main`.
- Conventional commits: `feat(server): ...`, `fix(client): ...`, `test: ...`, `refactor: ...`, `chore: ...`, `docs: ...`.
- Don't push, force-push, rebase shared branches or delete branches unless asked.
- `.gitattributes` keeps LF line endings — don't commit CRLF files from Windows.
- Windows: use PowerShell-friendly npm scripts (no `rm -rf`, `export VAR=`; use cross-platform tools or Node scripts).

## 10. The AI must NOT

- Rewrite large working parts "while it's there" or reformat whole files.
- Change the visual design without a `Design.md` reason.
- Rename socket events or change payload shapes without updating client and server in the same phase.
- Invent APIs, package versions or file contents — check `package.json`, `package-lock.json`, `pubspec.lock` or the docs.
- Delete files, tests or docs without saying so.
- Skip updating `Memory.md`.
