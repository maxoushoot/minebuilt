# Architecture Overview

## Runtime Layers

1. **Definitions (`scripts/data/definitions`)**
   - Immutable `Resource` assets.
   - Block and functional object metadata.
   - Template archetype rules and template content.

2. **Runtime State (`scripts/data/runtime`)**
   - Mutable save-ready resources (`VillageState`, `TemplateCatalogState`).

3. **Services (`scripts/services`)**
   - Pure gameplay/business operations.
   - No direct UI manipulation.

4. **Controllers (`scripts/controllers`)**
   - Scene entry points.
   - Orchestrate services and update view state.

5. **Scenes/UI (`scenes`)**
   - Mode-specific compositions.
   - Present current simulation state.

## Scene Separation

- `main_menu.tscn`: mode entry points.
- `world_mode.tscn`: city-builder management loop.
- `template_builder_mode.tscn`: isolated template authoring space.
- `immersion_mode.tscn`: optional first-person visit mode.

`game_root.tscn` handles scene switching through `AppState` mode changes.

## Extensibility Notes

- Add save/load by serializing runtime resources.
- Add block/object catalogs as concrete `.tres` assets.
- Upgrade pathfinding into chunk-aware navigation as map scale grows.
- Add logistics jobs as explicit entities using existing service boundaries.
