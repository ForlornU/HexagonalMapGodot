extends Object
class_name GridMapper


## Main entry point, Get all positions to spawn tiles on
func calculate_map_positions() -> Array[Voxel]:
	var voxels : Array[Voxel]

	## Diamond and Circle also use the rectangular bounds. They carve our their shape from that rectangle
	## using their individual shape filters 
	var stagger : bool
	match WorldMap.world_settings.map_shape:
		0:
			stagger = false
			voxels = generate_map(hexagonal_bounds(), stagger, hexagonal_buffer_filter)
		1:
			stagger = true
			voxels = generate_map(rectangle_bounds(), stagger, rectangular_buffer_filter)
		2:
			stagger = true
			voxels = generate_map(rectangle_bounds(), stagger, diamond_buffer_filter, diamond_shape_filter)
		3:
			stagger = true
			voxels = generate_map(rectangle_bounds(), stagger, circular_buffer_filter, circle_shape_filter)

	print("Created ", voxels.size(), " positions")
	#map.noise_data = find_noise_caps(positions)
	WorldMap.is_map_staggered = stagger
	return voxels


func generate_map(bounds: Callable, stagger: bool, buffer_filter: Callable, shape_filter: Callable = Callable()) -> Array[Voxel]:
	var voxel_array: Array[Voxel] = []
	for c in bounds.call():
		for r in bounds.call(c):
			for h in range(WorldMap.world_settings.max_height):
				if shape_filter and not shape_filter.call(c, r):
					continue
				var pos = Vector3(c, h, r) #column, height, row
				var voxel = generate_voxel(pos, stagger)
				modify_voxel(voxel, buffer_filter) #Hills, ocean, buffer
				voxel_array.append(voxel)
	return voxel_array


func generate_voxel(pos, stagger) -> Voxel:
	var new_pos = Voxel.new()
	new_pos.world_position = tile_to_world(pos, stagger)
	new_pos.grid_position = Vector3(pos.x, pos.y, pos.z)
	return new_pos


## Apply ocean noise, hills noise and find buffer tiles
func modify_voxel(voxel : Voxel, buffer_filter):
	var c = voxel.grid_position.x
	var r = voxel.grid_position.z
	voxel.noise = noise_at_tile(voxel.grid_position, WorldMap.world_settings.noise)
	
	if buffer_filter.call(c, r, WorldMap.world_settings.radius - WorldMap.world_settings.map_edge_buffer):
		voxel.buffer = true
	
	# Bottom layer must always be solid
	if voxel.grid_position.y != 0:
		if voxel.noise < 0: ## Transparancy test
			voxel.type = Voxel.biome.AIR

		
	##We prioritize water since hills cannot be created with surrounding ocean anyway
	#if settings.create_water and noise_at_tile(c, r, settings.ocean_noise) > settings.ocean_treshold:
		#pos.water = true
	#elif noise_at_tile(c, r, settings.heightmap_noise) > settings.heightmap_treshold:
		#pos.hill = true



func tile_to_world(pos, stagger: bool) -> Vector3:
	var SQRT3 = sqrt(3)
	var x: float = 3.0 / 2.0 * pos.x  # Horizontal spacing
	var z: float
	if stagger:
		z = pos.z * SQRT3 + ((int(pos.x) % 2 + 2) % 2) * (SQRT3 / 2)
	else:
		z = (pos.z * SQRT3 + (int(pos.x) * SQRT3 / 2))
	return Vector3(x * WorldMap.world_settings.tile_size, pos.y, z * WorldMap.world_settings.tile_size)


## Get noise at position of tile
func noise_at_tile(grid_position : Vector3, texture : FastNoiseLite) -> float:
	var value : float = texture.get_noise_3dv(grid_position)
	return value
	#return (value + 1) / 2 # normalize [0, 1]


func find_noise_caps(positions) -> Vector2:
	var min_max_noise = Vector2(999999.0, -999999.0)
	for pos in positions:
		if pos.noise < min_max_noise.x:
			min_max_noise.x = pos.noise
		if pos.noise > min_max_noise.y:
			min_max_noise.y = pos.noise
	return min_max_noise


### Bounds
### # Specific bounds functions for each shape

func hexagonal_bounds() -> Callable:
	return func(col = null):
		if col == null:
			return range(-WorldMap.world_settings.radius, WorldMap.world_settings.radius + 1)
		else:
			return range(max(-WorldMap.world_settings.radius, -col - WorldMap.world_settings.radius), min(WorldMap.world_settings.radius, -col + WorldMap.world_settings.radius) + 1)


func rectangle_bounds() -> Callable:
	return func(_col = null):
		return range(-WorldMap.world_settings.radius, WorldMap.world_settings.radius + 1)


### Filters
### # Filters positions to keep only tiles inside a shape

func circle_shape_filter(col: int, row: int) -> bool:
	var dist = sqrt(col * col + row * row)
	return dist < WorldMap.world_settings.radius


func diamond_shape_filter(col: int, row: int) -> bool:
	var adjusted_row = row
	if col % 2 != 0:
		adjusted_row += 0.5 
	return abs(adjusted_row) + abs(col) < WorldMap.world_settings.radius


### Buffer-filters!
### Filter out buffer tiles

func hexagonal_buffer_filter(col: int, row: int, limit: int) -> bool:
	return abs(col + row) > limit or abs(col) > limit or abs(row) > limit


func rectangular_buffer_filter(col: int, row: int, limit: int) -> bool:
	return abs(col) > limit or abs(row) > limit


func diamond_buffer_filter(col: int, row: int, limit: int) -> bool:
	return abs(row) + abs(col) >= limit


func circular_buffer_filter(col: int, row: int, limit: int) -> bool:
	return col * col + row * row > limit * limit
