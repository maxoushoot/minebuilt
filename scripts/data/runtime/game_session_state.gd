extends Resource
class_name GameSessionState

@export var village: VillageState = VillageState.new()
@export var template_catalog: TemplateCatalogState = TemplateCatalogState.new()

# Separate voxel data stores for compatibility with both future modes.
@export var world_voxel_state: VoxelBuildState = VoxelBuildState.new()
@export var template_voxel_state: VoxelBuildState = VoxelBuildState.new()
