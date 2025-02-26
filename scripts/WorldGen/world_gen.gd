@tool
extends Node

# Dependencies
@export var settings : GenerationSettings
@export_category("Dependencies")
@export var object_placer : ObjectPlacer
@export var tile_parent : Node3D

# Test-only!
@export var pfinder : Pathfinder
@export var proto_unit : PackedScene


## Starting point: Generate a random seed, create the tiles, place POI's
func _ready() -> void:
	init_seed()
	generate_world()
	
	#test_generate_voxel()
	#create_starting_units(floor(settings.radius/2))  ## prototyping pathfinding and units


func test_generate_voxel():
	var vg = VoxelGenerator.new()
	var count = 25
	var size = 0.25  # Distance from center to vertex
	var depth = 1.0
	
	var hex_width = sqrt(3) * size  # Horizontal distance between hexagons
	var hex_height = 1.5 * size  # Vertical distance between hexagons
	
	# Load material
	#var mat = load("res://assets/Materials/spotty_mat.tres") #Custom
	var mat = load("res://assets/Materials/voxel_mat.tres")
	
	# Generate hexagonal grid
	#for col in range(count):
		#for row in range(count):
	# Generate hexagonal prism
	var prism = vg.generate_hex_prism(size, depth)
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.material_override = mat
	mesh_instance.mesh = prism
	add_child(mesh_instance)
			
			## Calculate position
			#var x_offset = col * hex_width
			#var z_offset = row * hex_height
			#
			## Offset every alternate row
			#if row % 2 != 0:
				#x_offset += hex_width / 2
			#
			#var noise = settings.biome_noise.get_noise_2d(x_offset, z_offset) * 5
			#var y = snapped(noise, 1)
#
			#mesh_instance.position = Vector3(x_offset, y, z_offset)


# Randomize if no seed has been set
func init_seed():
	if settings.map_seed == 0 or settings.map_seed == null:
		print("Randomizing seed")
		settings.biome_noise.seed = randi() #New map_seed for this generation
		settings.heightmap_noise.seed = randi()
		settings.ocean_noise.seed = randi()
	else:
		settings.biome_noise.seed = settings.map_seed
		settings.heightmap_noise.seed = settings.map_seed
		settings.ocean_noise.seed = settings.map_seed


## placeholder functionality for placing units onto the map
func create_starting_units(count : int):
	var safety_count = 0 #Add safety counter in case no valid tiles
	## Test pathfinder
	while count > 0 and safety_count < 50:
		var r_tile : Tile = WorldMap.map.pick_random()
		if r_tile.mesh_data.type == Tile.biome_type.Ocean or r_tile.occupier != null:
			safety_count += 1
			continue
		var unit : Unit = proto_unit.instantiate()
		add_child(unit)
		unit.place_unit(r_tile.position, r_tile)
		unit.occupy_tile(r_tile)
		count -= 1


## Start of world_generation, time each step
func generate_world():
	var starttime = Time.get_ticks_msec()
	var interval = {"Start of Generation!" : starttime}
	
	## Get all positions through the gridmapper
	var mapper = GridMapper.new()
	var positions = mapper.calculate_map_positions(settings)
	interval["Calculate Map Positions -- "] = Time.get_ticks_msec()
	
	var mat = load("res://assets/Materials/voxel_mat.tres")
	var vg = VoxelGenerator.new()
	var chunk = vg.generate_chunk(positions, settings.radius, 1, 1)
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.material_override = mat
	mesh_instance.mesh = chunk
	add_child(mesh_instance)
	interval["Create Voxel Grid -- "] = Time.get_ticks_msec()
	#
	### Create the tiles
	#var factory = TileFactory.new()
	#factory.init_factory(settings, tile_parent)
	#var map = factory.create_map(positions)
	#WorldMap.set_map(map)
	#interval["Create Map -- "] = Time.get_ticks_msec()
#
	### Fill all gaps
	#if settings.modify_height:
		#factory.modify_terrain()
		#interval["Modify terrain and fill Gaps -- "] = Time.get_ticks_msec()
	#
	### Spawn villages
	#if settings.spawn_villages:
		#var placeable = get_placeable_tiles()
		#object_placer.place_villages(placeable, settings.spacing)
		#interval["Spawn Villages -- "] = Time.get_ticks_msec()
	
	print_generation_results(starttime, interval)


## This mess of a function loops through the timing results of generate_world and prints them
func print_generation_results(start : float, dict : Dictionary):
	print("\n")
	var last_val = start
	var total = 0
	for key in dict:
		var val = dict[key]
		if val == start:
			print(key)
			continue
		var passed = val - last_val
		print(key, str(passed) + "ms")
		last_val = val
		total += passed
	var s = "ms"
	if total > 999: 
		s = "s"
		total *= 0.001
	print("Total completion time: ", total, s)


## Ignore buffer and ocean to return for object placer
func get_placeable_tiles() -> Array[Tile]:
	var placeable_tiles : Array[Tile] = []
	for tile : Tile in WorldMap.map:
		if tile.pos_data.buffer or not tile.placeable:
			continue
		placeable_tiles.append(tile)
	print(str(placeable_tiles.size()) + " placeable tiles")
	return placeable_tiles
