# 🦕 Dino Game

A Flutter recreation of the classic Chrome dinosaur endless runner — built entirely from scratch using Flutter's Canvas API and a clean, system-oriented architecture. No game engine. No external game libraries. Just pure Dart and Flutter.

## 🎮 How to Play

Tap anywhere on the screen to **jump** over incoming cacti. The longer you survive, the faster the game gets. Hit an obstacle and it's game over — tap to try again.

## 🏗️ Architecture

The game is structured around a clear separation of concerns, inspired by Entity-Component-System (ECS) design:

| Layer | Responsibility |
|---|---|
| `GameLoop` | Drives the game forward every vsync frame using Flutter's `Ticker` |
| `GameController` | Owns all entities and coordinates systems each frame |
| `PhysicsSystem` | Simulates gravity and jump velocity (Euler integration) |
| `SpawnSystem` | Procedurally generates obstacles with increasing frequency |
| `CollisionSystem` | AABB (Axis-Aligned Bounding Box) collision detection |
| `GamePainter` | Renders the scene each frame using Flutter's `Canvas` API |
| `GameProvider` | Bridges the game engine to the Flutter widget tree via `ChangeNotifier` |

## ⚙️ Technical Highlights

- **vsync-locked game loop** — uses Flutter's `Ticker` to run in sync with the display refresh rate (≈60fps)
- **Delta-time physics** — frame-rate independent movement using `dt` (time since last frame), so the game runs consistently on any device
- **Difficulty scaling** — game speed and obstacle spawn rate both increase continuously as your score climbs
- **Forgiving hitboxes** — collision bounds are slightly inset from the visual rectangles, so near-misses feel fair
- **No unnecessary rebuilds** — only the `CustomPaint` canvas repaints each frame; score text and buttons are separate widgets unaffected by the 60fps update cycle

## 🛠️ Built With

- [Flutter](https://flutter.dev/) — cross-platform UI framework
- [Provider](https://pub.dev/packages/provider) — lightweight state management
- Flutter `Canvas` API — direct 2D rendering (no sprites or assets needed)

## 🚀 Getting Started

```bash
flutter pub get
flutter run
