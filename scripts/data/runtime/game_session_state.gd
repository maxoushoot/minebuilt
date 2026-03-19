# GameSessionState
# -----------------------------------------------------------------------------
# Architecture role: Runtime Data (session root, canonical ownership boundary).
# Responsibilities:
# - Groups the mutable runtime state for a play session.
# - Exposes canonical world voxels and template-builder voxels as separate
#   stores to avoid cross-mode coupling.
# - Provides access to village-level simulation state and template catalog data.
# Dependencies:
# - VillageState, TemplateCatalogState, VoxelBuildState.
# Canonical vs transient:
# - world_voxel_state and template_voxel_state are canonical voxel stores.
# - Any compatibility mirrors (ex: VillageState.placed_blocks) are derived from
#   these canonical structures and must be synchronized externally.
extends Resource
class_name GameSessionState

@export var village: VillageState = VillageState.new()
@export var template_catalog: TemplateCatalogState = TemplateCatalogState.new()

# Canonical source of truth for world voxels used by world mode runtime.
@export var world_voxel_state: VoxelBuildState = VoxelBuildState.new()
# Canonical source of truth for template builder voxels.
@export var template_voxel_state: VoxelBuildState = VoxelBuildState.new()
