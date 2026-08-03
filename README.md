<div align="center">

# OpenTrail

<p align="center">
  <img src="assets/image.png" alt="OpenTrail Banner" width="100%">
</p>

**Real-time convoy tracking and navigation for motorcycle and cycling groups.**

<p>
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black" />
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white" />
  <img src="https://img.shields.io/badge/Status-Active%20Development-blue" />
</p>

</div>

---

## Overview

OpenTrail is a Flutter application built for coordinating motorcycle and cycling group rides. It enables riders to share live locations, navigate to a common destination, and stay connected throughout the ride.

## Features

- Live rider tracking
- Group ride management
- Shared destination navigation
- Interactive map
- Firebase Authentication
- Cloud Firestore synchronization

## Tech Stack

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Flutter Map
- OpenRouteService
- Geolocator

## Getting Started

Clone the repository.

```bash
git clone https://github.com/<your-username>/OpenTrail.git
cd OpenTrail
```

Install dependencies.

```bash
flutter pub get
```

Create a `.env` file.

```env
MAPBOX_ACCESS_TOKEN=YOUR_MAPBOX_TOKEN
ORS_API_KEY=YOUR_ORS_API_KEY
```

Run the application.

```bash
flutter run
```

## Project Structure

```
lib/
├── core/
├── features/
├── models/
├── services/
├── widgets/
└── main.dart
```

## Screenshots

<div align="center">

| Login | Home | Navigation |
|------|------|------------|
| <img src="assets/login_page.png" width="220"> | <img src="assets/home_page.png" width="220"> | <img src="assets/map_page.png" width="220"> |

</div>

---

<div align="center">

Made with ❤️ using Flutter & Firebase

</div>
