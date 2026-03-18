# Voxel Village Builder (Godot 4)

Base architecture for a voxel city-builder with two core loops:

1. **World Mode**: top-down management simulation on a 3D grid.
2. **Template Builder Mode**: separate sandbox to craft reusable building templates.

## V1 Principles

- Data-driven design with `Resource` definitions for blocks, functional objects and templates.
- Strict separation between data, business services, controllers and UI scenes.
- Functional object logic is independent from voxel block visuals.
- Cellular pathfinding and simple logistics/population services prepared for iteration.

## Folder Structure

- `scenes/`: scene composition (`menu`, `world`, `template_builder`, `immersion`, `root`).
- `scripts/data/definitions`: reusable gameplay definitions.
- `scripts/data/runtime`: mutable runtime state resources.
- `scripts/services`: business logic services (generation, validation, pathfinding, simulation).
- `scripts/controllers`: thin scene controllers.

## Current Scope

This baseline focuses on architecture and mode routing. It intentionally keeps gameplay systems simple and modular for incremental implementation.
