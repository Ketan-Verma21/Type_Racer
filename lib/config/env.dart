/// Server address, chosen at build/run time (no trailing slash):
///   flutter run -d chrome --dart-define=SERVER_URL=http://localhost:8080
/// Without --dart-define the app uses the hosted server.
const String kServerUrl = String.fromEnvironment(
  'SERVER_URL',
  defaultValue: 'https://typ-racer-server.onrender.com',
);
