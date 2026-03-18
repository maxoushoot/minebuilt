# Bootstrap Godot 4 - Ossature technique

## 1) Structure de dossiers

```text
res://
├─ scenes/
│  ├─ root/
│  │  └─ game_root.tscn
│  ├─ menu/
│  │  └─ main_menu.tscn
│  ├─ world/
│  │  └─ world_mode.tscn
│  ├─ template_builder/
│  │  └─ template_builder_mode.tscn
│  └─ immersion/
│     └─ immersion_mode.tscn
├─ scripts/
│  ├─ core/
│  │  ├─ app_state.gd
│  │  └─ app_services.gd
│  ├─ controllers/
│  │  ├─ game_root_controller.gd
│  │  ├─ main_menu_controller.gd
│  │  ├─ world_mode_controller.gd
│  │  ├─ template_builder_controller.gd
│  │  └─ immersion_mode_controller.gd
│  ├─ services/
│  │  ├─ world_generation_service.gd
│  │  ├─ template_validation_service.gd
│  │  ├─ population_service.gd
│  │  ├─ logistics_service.gd
│  │  └─ grid_pathfinding_service.gd
│  └─ data/
│     ├─ definitions/
│     │  ├─ block_definition.gd
│     │  ├─ functional_object_definition.gd
│     │  ├─ template_archetype_definition.gd
│     │  └─ building_template_definition.gd
│     └─ runtime/
│        ├─ game_session_state.gd
│        ├─ village_state.gd
│        └─ template_catalog_state.gd
├─ data/
│  └─ definitions/
│     ├─ blocks/grass_block.tres
│     ├─ objects/bed_basic.tres
│     ├─ archetypes/house_archetype.tres
│     └─ templates/sample_house_template.tres
├─ docs/
│  ├─ architecture_overview.md
│  └─ bootstrap_skeleton.md
└─ project.godot
```

## 2) Fichiers clés ajoutés/modifiés

- Ajout `scripts/core/app_services.gd` (registre central services + session runtime).
- Ajout `scripts/data/runtime/game_session_state.gd` (racine d'état runtime).
- Ajout de ressources `.tres` minimales dans `data/definitions/**`.
- Mise à jour des contrôleurs pour brancher `AppServices` et transitions de mode.
- Mise à jour des scènes `main_menu`, `world_mode`, `template_builder_mode` avec HUD minimal de navigation.
- Mise à jour `project.godot` pour autoload `AppServices`.

## 3) Responsabilités

- `AppState`: changement de mode et signal global `mode_changed`.
- `AppServices`: point d'accès unique aux services métier + état de session.
- `GameRootController`: switch de scène active selon le mode.
- Contrôleurs de mode (`MainMenu`, `WorldMode`, `TemplateBuilder`): orchestration locale UI -> mode/services.
- Services: logique métier pure (stubs/implémentations minimales non couplées à l'UI).
- Runtime state: données mutables en mémoire prêtes pour save/load.

## 4) Ordre recommandé pour la suite

1. Ajouter un `DefinitionCatalogService` pour charger les `.tres` de manière centralisée.
2. Ajouter un `SaveLoadService` (JSON/binaire Godot `ResourceSaver`).
3. Structurer le tick simulation (`SimulationOrchestratorService`) sans encore détailler tous les sous-systèmes.
4. Introduire une grille world explicite (chunks/cells) et brancher progressivement le pathfinding.
5. Étendre Template Builder (placement ghost, contraintes structurelles).
6. Implémenter ensuite la logistique complète (jobs, transporteurs, priorités).

## 5) Validation attendue (socle)

- Démarrage projet sans erreur de dépendances script.
- Menu affichable au lancement.
- Navigation Menu -> World Mode.
- Navigation Menu -> Template Builder Mode.
- Navigation croisée World <-> Template Builder + retour Menu via HUD.
