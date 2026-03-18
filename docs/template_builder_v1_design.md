# Template Builder V1 — Design technique

## 1) Design technique

### Objectif
Créer un mode dédié au prototypage de bâtiments, indépendant de la map principale, avec:
- sélection d'un archétype,
- construction voxel,
- placement d'objets fonctionnels,
- validation métier,
- sauvegarde dans une bibliothèque de templates runtime.

### Architecture retenue
- **Mode dédié**: `template_builder` routé par `AppState`/`GameRootController`.
- **État isolé**: `GameSessionState.template_voxel_state` pour les blocs du builder.
- **Catalogue runtime**: `TemplateCatalogState.templates` pour les templates validés.
- **Validation métier**: `TemplateValidationService`.
- **Contrôleur d'orchestration**: `TemplateBuilderController`.

### Flux fonctionnel
1. Le joueur entre en mode Template Builder.
2. Il choisit un archétype (maison, école, mairie, ferme, marché, pont, décor).
3. Il place des blocs (même service voxel que le reste du jeu).
4. Il bascule en mode objet et place des objets fonctionnels.
5. Il lance la validation.
6. Le système liste explicitement les manques.
7. Si valide, il sauvegarde et le template apparaît dans la bibliothèque.

### Règles de validation V1
- Nombre minimum de blocs par archétype.
- Présence des catégories d'objets requises par archétype.

---

## 2) Ressources nécessaires

### Définitions d'archétypes (`data/definitions/archetypes`)
- `house_archetype.tres` (Maison)
- `school_archetype.tres` (École)
- `townhall_archetype.tres` (Mairie)
- `farm_archetype.tres` (Ferme)
- `market_archetype.tres` (Marché)
- `bridge_archetype.tres` (Pont)
- `decor_archetype.tres` (Décor)

### Définitions d'objets fonctionnels (`data/definitions/objects`)
- `bed_basic.tres` (lit)
- `desk_basic.tres` (bureau)
- `board_basic.tres` (tableau)
- `admin_desk_basic.tres` (bureau administratif)
- `storage_basic.tres` (stockage)
- `stall_basic.tres` (étal)
- `field_basic.tres` (champ)

### Évolution des structures de données
- `TemplateArchetypeDefinition`: ajout `minimum_block_count`.
- `BuildingTemplateDefinition`: ajout `object_instances` (format V1), conservation `object_placements` (legacy).

---

## 3) Scènes et scripts

### Scène
- `scenes/template_builder/template_builder_mode.tscn`
  - Zone 3D avec pelouse 100x100.
  - UI: sélection archétype, sélection objet, validation, sauvegarde, clear, bibliothèque.

### Contrôleur
- `scripts/controllers/template_builder_controller.gd`
  - Gestion input, placement voxels, placement objets.
  - Validation + messages de feedback détaillés.
  - Sauvegarde vers la bibliothèque runtime.

### Services et data
- `scripts/services/template_validation_service.gd`
  - Vérification des prérequis par archétype.
- `scripts/data/definitions/*.gd`
  - Contrats de ressources runtime.

---

## 4) Code (résumé des points clés)

### Placement voxel
- Toujours via `AppServices.block_placement`.
- Ghost preview + bornes strictes 100x100x32.

### Placement objets fonctionnels
- Mode édition toggle (TAB): blocs / objets.
- Placement à la cellule avec rotation.
- Rendu des objets en `MeshInstance3D` colorés par catégorie.

### Validation
- Génération d'un `BuildingTemplateDefinition` runtime.
- Appel `AppServices.template_validation.validate_template(...)`.
- Retour explicite: succès ou liste d'erreurs (manques).

### Sauvegarde bibliothèque
- Sauvegarde autorisée uniquement si validation OK.
- Ajout dans `AppServices.session.template_catalog.templates`.
- Affichage immédiat dans `TemplateLibraryList`.

---

## 5) Tests manuels à faire

1. **Accès mode template**
   - Depuis le menu principal, cliquer "Template Builder Mode".
   - Vérifier affichage de la zone vide 100x100.

2. **Sélection d'archétype**
   - Changer l'archétype dans la liste.
   - Vérifier que le statut affiche le bon archétype.

3. **Placement blocs**
   - Poser/supprimer des blocs (LMB/RMB).
   - Changer type bloc (1-3), couche (Q/E), rotation (R).

4. **Placement objets**
   - Passer en mode objets (TAB).
   - Poser/supprimer des objets (LMB/RMB).
   - Vérifier blocage si cellule déjà occupée par un objet.

5. **Validation**
   - Lancer validation sans exigences satisfaites.
   - Vérifier que le message liste clairement les catégories/conditions manquantes.
   - Compléter le template puis relancer validation -> succès.

6. **Sauvegarde**
   - Essayer de sauvegarder template invalide -> refus explicite.
   - Sauvegarder template valide -> entrée ajoutée à la bibliothèque.

7. **Régression navigation**
   - Retour menu / ouverture World Mode toujours fonctionnels.
