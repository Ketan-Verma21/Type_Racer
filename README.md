# Type Racer

Welcome to **Type Racer**! This project is a thrilling multiplayer typing game where players compete in real-time to achieve the highest Words Per Minute (WPM). Built with Flutter for the front-end and Node.js with Socket.IO for the backend, Type Racer offers an engaging and competitive typing experience.

## Features

- **Real-time Multiplayer**: Compete against other players in real-time.
- **Words Per Minute (WPM) Calculation**: Get accurate WPM scores at the end of each game.
- **Live Leaderboard**: See your ranking in real-time as you type.
- **Chat Functionality**: Communicate with other players during the game.
- **User Authentication**: Secure sign up and log in to track your progress and scores.
- **Responsive Design**: Enjoy a seamless experience across different devices.

## Screenshots

<div style="display: flex; overflow-x: auto; padding: 10px; gap: 50px;">
  <img src="https://github.com/Ketan-Verma21/Type_Racer/assets/106913278/b8636cff-05c7-4782-a555-9669c0870df1" alt="Home" width="450" />
  <img src="https://github.com/Ketan-Verma21/Type_Racer/assets/106913278/fdad498e-99f8-4dae-9910-c9cc2c8adb9c" alt="Create Room Screen" width="450" />
  
<img src="https://github.com/Ketan-Verma21/Type_Racer/assets/106913278/7338e13c-1adc-4e81-95c4-5d4d55a2dbe1" alt="Game Start" width="450" />
  <img src="https://github.com/Ketan-Verma21/Type_Racer/assets/106913278/d81da2ce-62cb-4763-b909-2198234fcda1" alt="Game Code Copied" width="450" />
  <img src="https://github.com/Ketan-Verma21/Type_Racer/assets/106913278/36bf42ec-50fb-41c1-b919-d6466af83fd7" alt="Starting of Game" width="450" />
<img src="https://github.com/Ketan-Verma21/Type_Racer/assets/106913278/a8201d84-d98e-48d1-992a-b4dbdb1a1d63" alt="End of Game" width="450" />




</div>

## Getting Started

To get a copy of the project up and running on your local machine, follow these simple steps.

### Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) SDK
- [Node.js](https://nodejs.org/) and [npm](https://www.npmjs.com/)
- [Android Studio](https://developer.android.com/studio) or [Visual Studio Code](https://code.visualstudio.com/)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Ketan-Verma21/typeracer.git
   cd type_racer
   ```

2. **Backend Setup:**
   - Navigate to the backend directory:
     ```bash
     cd server
     ```
   - Install the dependencies:
     ```bash
     npm install
     ```
   - Start the server:
     ```bash
     node server.js
     ```

3. **Frontend Setup:**
   - Navigate to the Flutter project directory:
     ```bash
     cd type_racer
     ```
   - Install the dependencies:
     ```bash
     flutter pub get
     ```
   - Run the app:
     ```bash
     flutter run
     ```

## Folder Structure
```
typeracer/
|- backend
|  |- api
|  |- models
|  |- node_modules
|  |- package.json
|  |- index.js
|- frontend
|  |- android
|  |- build
|  |- ios
|  |- lib
|  |- test
|  |- pubspec.yaml
```

- **backend**: Contains the Node.js server and Socket.IO implementation.
- **frontend**: Contains the Flutter project with all the screens and UI components.

## Contributing

We welcome contributions to enhance the Type Racer app! To contribute:

1. Fork the repository.
2. Create a new branch (`git checkout -b feature/your-feature-name`).
3. Commit your changes (`git commit -am 'Add some feature'`).
4. Push to the branch (`git push origin feature/your-feature-name`).
5. Create a new Pull Request.


## Contact

If you have any questions or feedback, feel free to reach out:

- **Email**: try.vrmketan@gmail.com
- **GitHub**: [Ketan-Verma21](https://github.com/Ketan-Verma21)

