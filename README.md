# Voxel Village Builder (Godot 4)

Base technique Godot 4 pour un city-builder voxel orienté données, avec séparation claire entre modes de jeu.

## Modes disponibles

1. **Menu**: point d'entrée principal.
2. **World Mode**: boucle de gestion (stub minimal, génération terrain simplifiée).
3. **Template Builder Mode**: atelier séparé pour créer/valider des templates de bâtiments.
4. **Immersion Mode** (optionnel dans ce socle): vue FPS de test.

## Principes du socle

- `Resource` de définitions immuables (`scripts/data/definitions` + `data/definitions`).
- État runtime mutable isolé (`scripts/data/runtime`).
- Services métier centralisés (`scripts/services`) et exposés via `AppServices` (autoload).
- Routing de modes centralisé via `AppState` (autoload) + `GameRootController`.
- Contrôleurs de scènes fins (`scripts/controllers`) et HUD minimal.

## Structure rapide

- `scenes/`: composition des scènes (menu, world, template_builder, immersion, root).
- `scripts/core`: état global app + branchement des services.
- `scripts/services`: logique métier stubée et testable.
- `scripts/data/definitions`: classes de définitions (`Resource`).
- `scripts/data/runtime`: état mutable de session.
- `data/definitions`: premiers assets `.tres` de référence.
- `docs/`: documentation d'architecture.

## Objectif actuel

Ce repository fournit un squelette compilable et maintenable, prêt pour les prochaines briques (simulation détaillée, logistique complète, pathfinding avancé), sans implémenter ces systèmes dès maintenant.
