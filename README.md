# Torbox Client (Yupp VibeCoded)

A simple, unofficial Flutter based client for managing your Torbox account.

## Features

- **Secure Login:** Securely log in using your API key, which is stored locally on your device.
- **Torrent Management:** View your active and completed torrents in a clean, collapsible list.
- **User Details:** View your account information, including your email, customer ID, and premium status.
- **Theme Switching:** Switch between light and dark mode.

## Getting Started

### Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install)
- An account with [Torbox.app](https://torbox.app)

### Installation

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/MrP00L420/TorBoxClient.git
    cd TorBoxClient
    ```

2.  **Install dependencies:**

    ```bash
    flutter pub get
    ```

3.  **Run the app:**

    ```bash
    flutter run
    ```

## Project Structure

```
lib
├── api.dart
├── main.dart
├── models
│   └── user.dart
├── screens
│   ├── home_screen.dart
│   ├── login_screen.dart
│   └── settings_screen.dart
└── storage_service.dart
```
