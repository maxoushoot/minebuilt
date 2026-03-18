# Architecture Overview

## Runtime Layers

1. **Definitions (`scripts/data/definitions` + `data/definitions`)**
   - Classes `Resource` immuables (`BlockDefinition`, `FunctionalObjectDefinition`, etc.).
   - Assets `.tres` de base servant de catalogue de départ.

2. **Runtime State (`scripts/data/runtime`)**
   - État mutable de session (`GameSessionState`) encapsulant:
     - `VillageState`
     - `TemplateCatalogState`

3. **Services (`scripts/services`)**
   - Opérations métier pures et modulaires.
   - Exposées globalement via `AppServices` (autoload) pour éviter les couplages scène-à-scène.

4. **Controllers (`scripts/controllers`)**
   - Points d'entrée de scènes.
   - Pilotent les services et transitions de mode.

5. **Scenes/UI (`scenes`)**
   - Compositions visuelles par mode.
   - HUD minimal pour navigation et statut.

## Core Singletons (autoload)

- `AppState`
  - Source de vérité du mode courant.
  - Émet `mode_changed(previous, next)`.
- `AppServices`
  - Instancie les services centraux.
  - Héberge l'état runtime (`session`).
  - Expose `reset_session()` pour repartir sur une base propre.

## Mode Routing

- `game_root.tscn` + `GameRootController` gèrent l'injection de la scène active selon `AppState.current_mode`.
- Modes supportés:
  - `menu`
  - `world`
  - `template_builder`
  - `immersion` (optionnel)

## Extensibility Notes

- Ajouter save/load en sérialisant `GameSessionState`.
- Étendre les catalogues `.tres` sans modifier la logique runtime.
- Remplacer les stubs de services par des implémentations complètes (jobs logistiques, pathfinding avancé, simulation population).
