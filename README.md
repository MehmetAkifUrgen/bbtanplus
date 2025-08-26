Project Overview:
Create a BBTAN-style arcade game using Flutter and the Flame framework. The game replicates BBTAN's core mechanics: the player launches a ball at an angle to break numbered bricks, which descend each turn, and the game ends if bricks reach the bottom. Enhance the game with new features, modern visuals, and optional 3D elements using flame_3d. The game should run on Android, iOS, and optionally macOS, delivering a unique experience compared to BBTAN.
Objectives:

Implement BBTAN's core mechanics (ball launching, brick breaking, descending bricks).
Add innovative brick types, power-ups, and gameplay mechanics.
Optionally include 3D visuals using flame_3d or enhance 2D with advanced effects.
Build a modern UI with Flutter (main menu, score screen, settings).
Increase replayability with a story, mission system, or randomized content.

Requirements:

Framework: Flutter, Flame (flame: ^1.10.0), optionally flame_3d: ^0.1.1.
Platforms: Android, iOS, optionally macOS.
Language: Dart.
Core Mechanics:

Player launches a ball from the bottom at a chosen angle (via touch/mouse).
Bricks have numbers indicating hits needed to break; they descend each turn.
Ball bounces off walls and bricks; game ends if bricks reach the bottom.


Visuals: Colorful bricks, animated ball, collision effects (particles or animations).
Audio: Background music and sound effects (e.g., brick break, power-up collection).

New Features:

New Brick Types:

Explosive Brick: Destroys nearby bricks on impact.
Time Brick: Slows down gameplay briefly when hit.
Teleport Brick: Teleports to a random position on impact.


New Power-Ups:

Time Freeze: Stops bricks from descending for 3 seconds.
Clone Ball: Splits the ball into two, each moving at different angles.
Laser Ball: Destroys bricks in one hit.


3D Option:

Use flame_3d to render bricks as 3D cubes or crystals.
Add simple 3D camera controls (e.g., slight rotation or zoom).
Include 3D collision effects (e.g., particle bursts on brick break).


Mission System:

Levels with unique brick layouts or themes (e.g., space, neon).
Missions like breaking a set number of bricks or collecting power-ups.


Customization:

Allow players to choose ball or brick themes (e.g., neon, metallic).
Dynamic backgrounds (e.g., moving stars in a space theme).


Device Motion (Optional):

Use device gyroscope to control ball angle.



Technical Requirements:

Flame Mechanics:

Ball: SpriteComponent or 3D model with flame_3d.
Bricks: PositionComponent (2D) or 3D models with hit points.
Collisions: Use CollisionCallbacks for ball-brick and ball-wall interactions.
Power-Ups: Visualize with SpriteComponent or ParticleSystemComponent.


UI:

Flutter-based main menu, settings, and score screen.
Embed Flame game using GameWidget.


Performance:

Target 60 FPS for 2D; optimize 3D with low-poly models and shaders.


Storage:

Save player progress and customization using SharedPreferences or a local database.



Development Steps:

Setup: Create a Flutter project, add flame and optionally flame_3d, enable Impeller (e.g., FLTEnableImpeller: true in Info.plist for macOS).
Core Mechanics: Build a FlameGame with ball movement, brick layout, and collision logic; implement angle selection via touch/mouse.
New Features: Create classes for new brick types (e.g., ExplosiveBrick extends PositionComponent) and a PowerUpManager for random power-ups.
UI & Visuals: Design Flutter UI for menus; add particle effects with ParticleSystemComponent and audio with flame_audio.
Testing: Test gameplay on Android/iOS; optimize 3D performance if used.

Optional Features:

Multiplayer: Local split-screen mode for two players on one device.
Leaderboard: Global scores using Firebase or similar.
Roguelike Elements: Random brick layouts or power-ups via a LevelGenerator.

Deliverables:

A working Flutter project (GitHub repo or zip).
Playable game with BBTAN mechanics, at least 2 new brick types, and 2 new power-ups.
Flutter-based UI (main menu, score screen).
Optional: 3D scenes with flame_3d and a sample 3D brick layout.
Basic documentation (e.g., README with setup and gameplay instructions).

Example Game Name: "Crystal Breaker 3D"

Theme: Space-based, breaking crystals with a spaceship.
Visuals: Neon colors, 3D crystals, particle effects.
Feature: A giant crystal boss every 10 levels.

Notes:

Keep code modular and readable; use separate classes for mechanics (e.g., Ball, Brick, PowerUp).
Account for flame_3d’s experimental status; test performance with low-poly models.
Refer to Flame’s Discord or GitHub for community support.
If a feature is unclear, propose a simple, creative solution.