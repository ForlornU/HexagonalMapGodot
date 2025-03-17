extends Resource
class_name GenerationSettings

enum shape {HEXAGONAL, RECTANGULAR, DIAMOND, CIRCLE}

@export_category("Map")
@export var map_shape : shape = shape.HEXAGONAL
@export var map_seed : int
@export_range(0, 64, 1) var radius: int = 5
@export_range(1, 32, 1) var max_height: int = 3
@export_range(0, 8) var terrace_steps = 1
@export var remove_overhang = true
@export_range(0.0, 1.0) var noise_height_bias : float = 0.5
@export_range(0.0, 1.0) var ground_to_air_ratio : float = 0.5
@export var flat_buffer = true
@export var debug : bool = false
@export var noise : FastNoiseLite

@export_category("Voxel")
@export_range(0.1, 5) var voxel_size : float = 1 # Size scalar
@export_range(0.1, 5) var voxel_height : float = 1 #height of voxels
## -1 For flat-shading. 0 for smooth
@export_range(-1, 0) var shading : int = -1
@export var material : Material
## 2 == 2x2 atlas eg.
#@export var atlas_size = 2

@export_category("Villages")
@export var spawn_villages = true
@export var map_edge_buffer = 2
@export_range(1, 99) var spacing = 6
