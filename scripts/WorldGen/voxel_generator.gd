class_name VoxelGenerator

var map : MappingData
var map_dict = {}
const sides = 6

func generate_chunk(_map : MappingData, radius, prism_size : float, height: float) -> Mesh:
	map = _map
	var verts = PackedVector3Array()
	var indices = PackedInt32Array()
	var uvs = PackedVector2Array()
	var normals = PackedVector3Array() 
	
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)

	for pos in map.positions:
		var next_position = pos.world_position
		verts.append_array(get_verts(next_position, prism_size, height, surface))
		map_dict[pos.grid_position] = pos.world_position

	create_uvs(uvs, verts.size(), map.positions.size())
	build_geometry(verts, indices, normals, map.positions.size())
	
	# Create & assign mesh
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_NORMAL] = normals
	surface.create_from_arrays(arrays, Mesh.PRIMITIVE_TRIANGLES)
	surface.generate_normals(false)
	surface.generate_tangents()
	return surface.commit()

func build_geometry(verts: PackedVector3Array, indices: PackedInt32Array, normals: PackedVector3Array, prism_count: int):
	# Construct edges and faces
	for prism in range(prism_count):
		var first_prism_vert = prism * 13  # Each prism has 13 vertices
		var current_prism = map.positions[prism]
		
		## Construct sides
		for i in range(WorldMap.HEXAGONAL_NEIGHBOR_DIRECTIONS.size()):
			var neighbor = current_prism.grid_position + WorldMap.HEXAGONAL_NEIGHBOR_DIRECTIONS[i]
			if not map_dict.has(neighbor):
				var bottom_vert = first_prism_vert + i
				var next_bottom_vert = first_prism_vert + ((i + 1) % sides)
				var top_vert = first_prism_vert + 6 + i
				var next_top_vert = first_prism_vert + 6 + ((i + 1) % sides)
				
				# First triangle of the quad (base to top)
				indices.append(bottom_vert)        # Bottom vertex
				indices.append(next_bottom_vert)   # Next bottom vertex
				indices.append(top_vert)           # Top vertex
				
				# Second triangle of the quad (top to next base)
				indices.append(next_bottom_vert)   # Next bottom vertex
				indices.append(next_top_vert)      # Next top vertex
				indices.append(top_vert)           # Top vertex
			else:
				print("prism at : ", current_prism.grid_position)
				print("Found neighbor at: ", neighbor)
				
			
		## Construct top
		var top_center_vert = first_prism_vert + 12  # Index of the top center vertex
		for i in range(sides):
			var top_vert = first_prism_vert + 6 + i
			var next_top_vert = first_prism_vert + 6 + ((i + 1) % sides)
			
			# Add triangles for the top face
			indices.append(top_vert)           # Top vertex
			indices.append(next_top_vert)      # Next top vertex
			indices.append(top_center_vert)    # Top center vertex


func create_uvs(uvs: PackedVector2Array, verts: int, prism_count: int) -> void:
	for prism in range(prism_count):
		var first_prism_vert = prism * 13  # Each prism has 13 vertices
		
		# UVs for the bottom vertices (sides)
		for i in range(sides):
			var angle = (float(i) / float(sides)) * 2.0 * PI
			var u = 0.5 + 0.5 * cos(angle)  # Map to 0..1 range
			uvs.append(Vector2(u, 0.0))  # Bottom vertex UV
		
		# UVs for the top vertices (top face)
		for i in range(sides):
			var angle = (float(i) / float(sides)) * 2.0 * PI
			var u = 0.5 + 0.5 * cos(angle)  # Map to 0..1 range
			var v = 0.5 + 0.5 * sin(angle)  # Map to 0..1 range
			uvs.append(Vector2(u, v))  # Top face vertex UV
		
		# UV for the top center vertex
		uvs.append(Vector2(0.5, 0.5))  # Center of the top face


# Function to get the vertices for the base and top hexagon
func get_verts(position : Vector3, size : float, height: float, surface) -> PackedVector3Array:
	# Define the base hexagon
	var base_vertices = [
	Vector3(size * 0.5, 0.0, size * -0.866),  # Left
	Vector3(size, 0.0, 0.0),  # Top-right
	Vector3(size * 0.5, 0.0, size * 0.866),  # Bottom-right
	Vector3(-size * 0.5, 0.0, size * 0.866),  # Bottom-left
	Vector3(-size, 0.0, 0.0),  # Left
	Vector3(-size * 0.5, 0.0, size * -0.866)  # Top-left
	]

	var verts = PackedVector3Array()
	
	# Append base vertices
	for v in base_vertices:
		surface.set_smooth_group(-1)
		verts.append(v + position)  # Base vertices
	
	# Append top vertices (translated by height)
	for v in base_vertices:
		surface.set_smooth_group(-1)
		verts.append(v + Vector3(0.0, height, 0.0) + position)  # Top vertices
	
	# append top center vert
	surface.set_smooth_group(-1)
	verts.append(position + Vector3(0.0, height, 0.0)) # Top center vertex
	
	return verts
