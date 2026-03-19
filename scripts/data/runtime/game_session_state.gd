extends Resource
class_name GameSessionState

@export var village: VillageState = VillageState.new()
@export var template_catalog: TemplateCatalogState = TemplateCatalogState.new()

# Canonical source of truth for world voxels used by world mode runtime.
@export var world_voxel_state: VoxelBuildState = VoxelBuildState.new()
# Canonical source of truth for template builder voxels.
@export var template_voxel_state: VoxelBuildState = VoxelBuildState.new()
