<div align="center">

# 🏎️ Type Racer

**A real-time multiplayer typing race with game modes, live stats, spectators, chat and a neon-arcade UI.**

Built with **Flutter** · **Node.js** · **Socket.IO** · **MongoDB**

<a href="https://buymeacoffee.com/vrm_ketan" target="_blank">
  <img src="https://img.buymeacoffee.com/button-api/?text=Buy me a coffee&emoji=☕&slug=vrm_ketan&button_colour=FFDD00&font_colour=000000&font_family=Cookie&outline_colour=000000&coffee_colour=ffffff" alt="Buy Me A Coffee" height="48" />
</a>

</div>

---

## 📖 About

Create a room, share the code, and race your friends to type the same quote the fastest. Every keystroke is validated on the server, so everyone sees the same live race: cars slide down their lanes as you type, WPM updates every second, and the winner gets confetti.

## ✨ Features

### Gameplay
- **Real-time multiplayer** – up to 8 players per room, synced through Socket.IO.
- **Live race track** – every player has a lane and a car that moves as they type.
- **Live WPM and accuracy** – updated every second during the race.
- **Per-letter feedback** – correct letters turn green, mistakes turn red, the input box shakes on a wrong letter.
- **Three game modes**
  | Mode | Rule |
  |---|---|
  | 🏁 **Classic** | Wrong words are ignored. Fastest typist wins. |
  | 🎯 **Flawless** | A wrong word sends you back to the start. |
  | 💀 **Sudden Death** | One wrong word and you're out. First to finish, or last one standing, wins. |
- **Host settings** – mode, time limit (30–120 s), quote length (short / medium / long) and max players.
- **Spectator mode** – join a race that already started and watch it live; you join as a player on the next round.
- **Rematch** – the host starts another round in the same room.

### Social
- **Lobby chat** and **emoji reactions** that float across everyone's screen.
- **Ranked scoreboard** with medals, winner banner and WPM.

### Polish
- **Neon-arcade UI** – animated background, glowing buttons, countdown pop, entrance animations.
- **Winner celebration** – confetti, sound effects and haptic feedback (with a mute button).
- **Resilient connections** – a dropped player has 15 seconds to reconnect and keep their place; leaving players are removed cleanly and the host role is passed on.

## 🖼️ Screenshots

<!--
  Paste your screenshots here. Example:
  <img src="PASTE_IMAGE_URL" alt="Home" width="260" />
-->

| Home | Create / Join | Lobby |
|:---:|:---:|:---:|
| _screenshot_ | _screenshot_ | _screenshot_ |

| Race | Spectator | Results |
|:---:|:---:|:---:|
| _screenshot_ | _screenshot_ | _screenshot_ |

## 🧱 Tech Stack

| Layer | Technology |
|---|---|
| App | Flutter, Provider, socket_io_client, flutter_animate, google_fonts, confetti, audioplayers |
| Server | Node.js, Express, Socket.IO |
| Database | MongoDB with Mongoose |
| Quotes | [API Ninjas Quotes API](https://api-ninjas.com/api/quotes) (with an offline fallback sentence) |

## 🏗️ Architecture

```
 Flutter app                                Node server
┌─────────────────────────┐  Socket.IO  ┌──────────────────────────────┐
│ Screens / Widgets       │◄───────────►│ sockets/   parse + emit      │
│   ▲ read                │             │ services/  game rules        │
│ Providers (state)       │             │ MongoDB    game documents    │
│   ▲ write               │             │ api/       quote fetching    │
│ SocketMethods           │             └──────────────────────────────┘
└─────────────────────────┘
```

The **server owns the game**. The app sends intent (create, join, start, typed a word) and renders the state the server broadcasts (`updateGame`, `timer`). Red/green letter feedback on the client is only a visual hint; whether a word is correct is always decided by the server.

### Folder structure

```
type_racer/                      # Flutter project
├── lib/
│   ├── main.dart
│   ├── theme/                   # colour palette + theme
│   ├── screens/                 # home, create room, join room, game
│   ├── widgets/                 # race lane, scoreboard, chat, settings, buttons...
│   ├── providers/               # game state, client state, chat
│   ├── models/                  # GameState
│   └── utils/                   # socket client/methods, sounds, helpers
├── assets/sounds/               # sound effects
└── server/                      # Node.js backend
    ├── index.js                 # bootstrap
    ├── config/                  # constants (modes, limits...)
    ├── sockets/                 # game, chat and connection event handlers
    ├── services/                # game, timer, chat and reconnect logic
    ├── Models/Game.js           # Mongoose schema
    ├── api/getSentence.js       # quote fetching + cleaning
    └── utils/
```

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Node.js](https://nodejs.org/) (v18+) and npm
- A [MongoDB](https://www.mongodb.com/atlas) connection string (a free Atlas cluster works)
- A free [API Ninjas](https://api-ninjas.com/) key

### 1. Clone
```bash
git clone https://github.com/Ketan-Verma21/Type_Racer.git
cd Type_Racer
```

### 2. Start the server
```bash
cd server
npm install
```
Create a `.env` file in `server/`:
```env
PORT=3000
MONGO_URL=your_mongodb_connection_string
API_URL=https://api.api-ninjas.com/v2/quotes
API_KEY=your_api_ninjas_key
```
Run it:
```bash
node index.js
```

### 3. Run the app
Make sure the socket client points to your server's address (use your computer's LAN IP, not `localhost`, when testing on a phone), then:
```bash
flutter pub get
flutter run
```

Open the app on two devices (or two browser tabs), create a room on one, and join with the code on the other.

## 🔌 Socket Events

| Event | Direction | Purpose |
|---|---|---|
| `create-game` / `join-game` | client → server | Create a room / join it (as a spectator if it already started) |
| `update-settings` | client → server | Host changes mode, time, length, max players |
| `timer` | client → server | Host starts the countdown |
| `userInput` | client → server | A typed word |
| `rematch` | client → server | Host starts another round |
| `chat-message` / `reaction` | both | Lobby chat and emoji reactions |
| `leave-game` / `rejoin-game` | client → server | Leave, or reattach after a reconnect |
| `updateGame` | server → client | Full game state, broadcast on every change |
| `timer` | server → client | Countdown and remaining time |
| `notCorrectGame` | server → client | Error message (invalid code, room full...) |

## 🗺️ Roadmap

- [ ] Login and player profiles
- [ ] Global leaderboard and match history
- [ ] Dockerised server, Nginx reverse proxy with HTTPS
- [ ] CI/CD with Codemagic
- [ ] Unit tests for the game services
- [ ] Redis adapter for horizontal scaling
- [ ] Power-ups

## 🤝 Contributing

Contributions are welcome!

1. Fork the repository
2. Create a branch: `git checkout -b feature/your-feature-name`
3. Commit your changes: `git commit -m "Add some feature"`
4. Push the branch: `git push origin feature/your-feature-name`
5. Open a Pull Request

## ☕ Support

If you enjoy the project, you can support me here:

<a href="https://buymeacoffee.com/vrm_ketan" target="_blank">
  <img src="https://img.buymeacoffee.com/button-api/?text=Buy me a coffee&emoji=☕&slug=vrm_ketan&button_colour=FFDD00&font_colour=000000&font_family=Cookie&outline_colour=000000&coffee_colour=ffffff" alt="Buy Me A Coffee" height="48" />
</a>

## 📬 Contact

- **Email:** try.vrmketan@gmail.com
- **GitHub:** [Ketan-Verma21](https://github.com/Ketan-Verma21)
- **Buy Me a Coffee:** [buymeacoffee.com/vrm_ketan](https://buymeacoffee.com/vrm_ketan)
