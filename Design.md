# Type Racer — Design System

> The visual and feedback language of the app ("neon arcade at night"). Source of truth in code: `lib/theme/app_colors.dart`, `lib/theme/app_theme.dart`. v2 **keeps this look**; refactors must not change it unless this file is updated first.

---

## 1. Personality

Neon arcade racing at night: dark navy backgrounds, glowing cyan/magenta accents, bold geometric headings, quick springy motion, celebratory feedback. Playful but readable — the quote text is always the calmest, clearest thing on screen.

## 2. Colour

### 2.1 Palette (`AppColors`)

| Token | Hex | Use |
|---|---|---|
| `bg` | `#0B0F1E` | Scaffold background, text on bright buttons |
| `surface` | `#141B33` | Cards, panels (usually at 80–85 % opacity over the background) |
| `surfaceHigh` | `#1C2545` | Inputs, chips, list rows, track rail |
| `cyan` | `#00E5FF` | **Primary** — main buttons, focus, "you", countdown, cursor letter |
| `magenta` | `#FF2E93` | **Secondary** — Join flow, settings panel, other players' chat names |
| `yellow` | `#FFD60A` | Highlights — status pill, trophies, scoreboard, waking-server banner |
| `green` | `#39FF88` | Correct letters/words, "server online", good accuracy (≥ 95 %) |
| `red` | `#FF4D5E` | Errors, wrong letters, OUT, leave, low accuracy (< 85 %) |
| `textPrimary` | `#EAF0FF` | Main text |
| `textMuted` | `#8A94B8` | Secondary text, hints, labels, remaining quote words |

Accuracy colour scale: ≥ 95 % green · ≥ 85 % yellow · below red.

### 2.2 Gradients

| Name | Colours | Use |
|---|---|---|
| `primaryGradient` | `#00E5FF → #3D7BFF` (left→right) | Primary buttons (Create, Start, Play Again) |
| `secondaryGradient` | `#FF2E93 → #FF7A3D` | Secondary buttons (Join, Back to Home) |
| `titleGradient` | cyan → magenta | "TYPE RACER" title (ShaderMask) |
| Background | `#0B0F1E → #111A3A` (top→bottom) | `GameBackground` |

### 2.3 Lane colours
`cyan, magenta, yellow, green, #B388FF` — assigned by lane index, repeating after 5.

### 2.4 Opacity conventions
Card fill 0.80–0.85 · borders 0.25–0.50 of the accent · glow shadows 0.12–0.55 · disabled controls 0.40 · eliminated lane 0.55 · error backgrounds red @ 0.12–0.25.

## 3. Typography

Fonts via `google_fonts` (no bundled font files).

| Role | Font | Weight | Where |
|---|---|---|---|
| Display | **Orbitron** (`AppTheme.display`) | 800 default, letter-spacing 1.5 (1–4) | Titles, buttons, numbers, labels, countdown — usually UPPERCASE |
| Body | **Rajdhani** (`AppTheme.body`, app text theme) | 600 default, 700–800 for emphasis | Sentences, chat, hints, descriptions |
| Mono | **JetBrains Mono** | 400–800 | The quote card and typing input (fixed width = letters line up) |

### Type scale in use

| Size | Display (Orbitron) | Body (Rajdhani) | Mono |
|---|---|---|---|
| 40 | Home title | | |
| 44 / 34 | Countdown (lobby / race) | | |
| 28 | Screen titles (CREATE ROOM, JOIN ROOM) | | |
| 24 | | | Quote text (line-height 1.6) |
| 20 | Scoreboard title & WPM, AppBar | Home subtitle, scoreboard names | Input text |
| 18 | Home buttons, stat values, max players | Text fields | |
| 16 | Buttons | Default body, info text | |
| 14–15 | Lane names, % , section headers | Chat, chips, descriptions | |
| 11–13 | Labels (`PLAYERS`, `MODE`), status pill, WPM in lane | Small labels | |
| 9 | "YOU" badge | | |

Rules: labels/section headers are UPPERCASE Orbitron with letter-spacing 2; never use Orbitron for long sentences; the quote is always JetBrains Mono.

## 4. Layout & spacing

- Content max width **600 px**, centred (`ConstrainedBox(maxWidth: 600)`) on every screen.
- Horizontal gutter 16 px (forms 20 px), card padding 16 px (forms 24 px).
- Vertical rhythm: 6 / 8 / 10 / 12 / 16 / 20 / 30 px.
- Screens are scrollable (`SingleChildScrollView`/`ListView`) so small phones and the keyboard never clip content.
- Everything sits inside `GameBackground` + `SafeArea`.

## 5. Shape & depth

| Element | Radius |
|---|---|
| Back button, small badges | 12 / 6 |
| Inputs, room-code tile, stat tiles, scoreboard rows | 14 |
| Buttons, banners, status cards | 16 |
| Panels (chat, settings, lanes, quote card) | 18 |
| Scoreboard card | 20 |
| Form card (create/join) | 24 |
| Chips, status pill | stadium / 30 |

Depth comes from **glow**, not drop shadows: `BoxShadow(color: accent.withOpacity(0.12–0.55), blurRadius: 10–30)`. Thin 1 px accent borders (2 px for focus / "me").

## 6. Components

| Component | Spec |
|---|---|
| **CustomButton** | Gradient fill, UPPERCASE Orbitron text in `bg`, radius 16, min width 240 (150 on home), glow shadow; press → scale 0.94 + smaller glow (100–150 ms); `onTap: null` → 40 % opacity, no glow. Primary = cyan gradient, `secondary: true` = magenta gradient. |
| **Text field** | `surfaceHigh` fill, radius 14, no border at rest (cyan @ 0.15), 2 px cyan when focused, Rajdhani 18, muted hint. |
| **Game input** | JetBrains Mono 20, keyboard icon; wrong prefix → red text, red 2 px border, red glow, error icon, horizontal shake (300 ms, 3 oscillations, 8 px). |
| **Quote card** | surface @ 0.85, cyan border @ 0.3, radius 18. Done words green; current word: typed-correct green bold, typed-wrong red on red @ 0.25, next letter = cyan block with `bg` text (the cursor), untyped bold primary; overflow letters red struck-through; remaining words muted. |
| **Race lane** | Card with name (👑 for host), "YOU" cyan badge, WPM, %; 4 px rail in `surfaceHigh`, glowing trail in lane colour, 🏎️ car (flipped to face right) sliding with `easeOutCubic` 500 ms; 🏁 at the end; 🏆 when finished; eliminated → 💥 car, OUT in red, 55 % opacity. "Me" lane has a 2 px cyan border. |
| **Stats bar** | 4 tiles: WPM (cyan), ACCURACY (scale colour), WORDS (magenta), mode emoji (yellow). |
| **Scoreboard** | Yellow-bordered card, 🏆 (over) or ⏳ (waiting) with elastic scale-in; rows with 🥇🥈🥉 or `#n`, name, WPM; winner row yellow tint; "me" row cyan border; rows slide in staggered by 120 ms. |
| **Settings panel** | Magenta-bordered card; host sees ChoiceChips (selected = cyan fill, `bg` text) and a ± stepper for max players; guests see read-only chips + "host only". |
| **Chat panel** | Cyan-bordered card, 130 px message list (auto-scroll), own name cyan / others magenta, 140-char input, send icon, reaction row. |
| **Reactions** | 6 emoji buttons (😂 🔥 👏 😮 💀 ❤️) in round `surfaceHigh` buttons; reactions float up 280 px over 2.3 s with the sender's name, fading out. |
| **Banners** | Wrong word / OUT: red @ 0.92 pill near top, scale-in + shake, auto-hide after 1.9 s. Server status: yellow (waking + spinner + seconds), green dot (online), red (failed + Retry). |
| **Status pill** | Top bar centre, UPPERCASE yellow Orbitron 12 on `surfaceHigh`, yellow border ("GAME STARTING", "TIME REMAINING"). |
| **Snackbars** | `awesome_snackbar_content`, floating, transparent background: success / warning / failure. |
| **Background** | Navy gradient + cyan grid (48 px, 6 % opacity) scrolling downward every 3 s + two blurred glows (cyan top-left, magenta bottom-right). |

## 7. Motion

| Moment | Animation |
|---|---|
| Screen entry | fade-in 500–600 ms + slideY 0.15–0.3 (`easeOut` / `easeOutBack`), staggered 300–500 ms on home |
| Home car | bob ±8 px, 900 ms, repeat reverse |
| Countdown numbers | `AnimatedSwitcher` 350 ms, `elasticOut` scale + fade, cyan text glow |
| Car movement | 500 ms `easeOutCubic` |
| Button press | 100 ms scale, 150 ms glow |
| Results | trophy elastic 600 ms; rows staggered fade + slideX |
| Winner | confetti 4 s, explosive, colours cyan/magenta/yellow/green/white |

Keep motion short (≤ 600 ms, except ambient loops); never animate the quote text itself.

## 8. Sound & haptics

| Event | Sound (`assets/sounds/`) | Haptic |
|---|---|---|
| Countdown tick (5…1) | `beep.wav` | selection click |
| GO (0) | `go.wav` | heavy impact |
| Correct word | `tick.wav` | selection click |
| Wrong letter | `error.wav` | light impact |
| Flawless reset | `error.wav` + banner | heavy impact |
| Eliminated | `out.wav` + banner | heavy impact |
| You won | `win.wav` + confetti | 3 × heavy impact (0 / 200 / 400 ms) |
| You lost | `lose.wav` | light impact |

Global mute toggle in the game top bar (volume icon). Sound must fail silently.

## 9. Iconography & emoji

Material rounded icons (`*_rounded`) in muted or accent colours. Emoji are part of the brand: 🏎️ car, 🏁 finish/Classic, 🎯 Flawless, 💀 Sudden Death, 👑 host, 🚦 Join, 🏆 trophy, 💥 eliminated, 👀 spectating.

## 10. Voice & copy

Short, energetic, friendly: "Create or join a room to race!", "Wrong word! Back to the start 🎯", "You're OUT! 💀", "YOU WON! 🎉". Buttons are 1–2 words, UPPERCASE. Errors say what happened and what to do ("Couldn't reach the server — check your internet connection and try again.").

## 11. Accessibility (to improve in Phase 7)

- Correct/wrong feedback uses colour **and** something else (bold, background block, strikethrough, shake, sound) — keep it that way for colour-blind players.
- Keep body text ≥ 14 px; avoid `textMuted` for anything essential on `surface`.
- Respect the system "reduce motion" setting for the background grid and confetti (TODO).
- Add `Semantics` labels to icon-only buttons (leave, mute, send) (TODO).
- Tap targets ≥ 44 px.

## 12. Code rules for the design

- Use `AppColors` / `AppTheme` tokens only — no raw hex values or new `TextStyle(fontFamily: ...)` in widgets.
- New screens: `Scaffold` → `GameBackground` → `SafeArea` → centred `ConstrainedBox(maxWidth: 600)`.
- New colour, font size or component variant → add it here first.
- `withOpacity` is deprecated in recent Flutter; migrate to `withValues(alpha: x)` during Phase 7 with identical values.
