# SupaClean — Flutter MVVM Starter

Flutter/Dart implementation of the SupaClean designs (splash screen,
Welcome Back / Login, Create Your Account) using MVVM architecture.

## Running the app

```
flutter pub get
flutter run                          # phone, emulator
flutter run -d chrome --web-port 5050   # Chrome
```

The app talks to the ASP.NET API at `ApiConfig.defaultBaseUrl`
(`lib/core/api_config.dart`), a Dev Tunnel to the API running on one team
laptop. It only answers while that laptop has the API and the tunnel running
(see `run-supaclean.ps1`), and the tunnel expires after about 30 days.

- **"The server took too long" / "Could not reach the server"**: the laptop
  with the API is off or asleep. Ask its owner to start it.
- **Chrome**: use `--web-port 5050`. The API only allows that origin, and a
  different port is blocked by the browser and looks like a server error.
- **Another API** (for example your own on the same Wi-Fi):
  `flutter run --dart-define=API_BASE_URL=http://192.168.0.20:5000`

## Architecture (MVVM)

```
lib/
├── main.dart                    # App entry, theme, Provider setup
├── core/
│   └── constants.dart           # AppColors, AppStrings
├── models/
│   └── user_model.dart          # UserModel (data layer)
├── viewmodels/
│   └── auth_viewmodel.dart      # AuthViewModel — validation + auth logic
├── views/
│   ├── splash_screen.dart       # Splash → auto-navigates to Login
│   ├── login_screen.dart        # Welcome Back / Login
│   └── signup_screen.dart       # Create Your Account
└── widgets/
    ├── app_logo.dart            # SupaClean brand text
    └── primary_button.dart      # Rounded pink button with loading state
```

- **Model** — `UserModel` holds user data (full name, email, phone, password).
- **ViewModel** — `AuthViewModel` extends `ChangeNotifier`; exposes `isLoading`,
  `errorMessage`, `currentUser`, plus `login()` and `register()` which validate
  input and simulate a network call (replace the `Future.delayed` with a real
  API such as Supabase or Firebase).
- **View** — screens observe the ViewModel via `provider` (`context.watch` /
  `context.read`) and contain no business logic.

## Run it

```bash
flutter create .          # only if starting from an empty folder
flutter pub get
flutter run
```

## Features

- Splash screen with auto-navigation (3 s)
- Login screen matching the design (logo, Welcome Back, email + password with
  show/hide toggle, Forgot Password, LOGIN button, Create Account link)
- Create Account screen (full name, email, phone, password, confirm password)
- Form validation with snackbar error messages
- Loading indicator on buttons during "authentication"
