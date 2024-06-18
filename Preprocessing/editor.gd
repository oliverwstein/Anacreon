@tool
extends EditorScript

func _run():
	print("Run!")
	var scene_path = "res://Overworld/tile_map.tscn"  # Path to your scene file
	var new_scene_path = "res://Overworld/tile_map_simplified.tscn"  # Path to your scene file
	var scene = load(scene_path)  # Load the scene resource
	if scene:
		var node = scene.instantiate()  # Create an instance of the scene
		var tile_map = scene.get_local_scene().duplicate(true) # Find the TileMap node in the scene
		if tile_map and tile_map.tile_set:
			tile_map.tile_set = process_tileset(tile_map.tile_set.duplicate(true))  # Duplicate and process the TileSet
			var tile_set = tile_map.tile_set as TileSet
			save_scene(tile_map, new_scene_path)  # Save the modified scene
			open_scene_in_editor(new_scene_path)  # Optionally open the modified scene in the editor
		else:
			print("TileMap or TileSet not found in the scene.")
	else:
		print("Failed to load the scene.")

func save_scene(node, path):
	var packed_scene = PackedScene.new()
	packed_scene.pack(node)
	if packed_scene.pack(node) == 0:
		var error = ResourceSaver.save(packed_scene, path)
		if error == OK:
			print("Scene saved successfully to:", path)
		else:
			print("Failed to save the scene:", error)
	else:
		print("Failed to pack the scene.")

func open_scene_in_editor(path):
	EditorInterface.open_scene_from_path(path)
	print("Scene opened in editor:", path)

var reference_tiles = {
		"water": Vector2i(0, 0),
		"field": Vector2i(9,0),
		"forest": Vector2i(10, 1),
		"mountain": Vector2i(12, 11),
		"cliff": Vector2i(13, 7),
		"sand": Vector2i(2, 15),
		"road": Vector2i(16, 4),
	}
var reference_dists = {}

func process_tileset(tileset: TileSet):
	print("process_tileset, ", tileset)
	var atlas = tileset.get_source_count()  # Get all tile IDs
	print("atlas, ", atlas)
	#tileset.add_physics_layer()
	var tile_source = tileset.get_source(0) as TileSetAtlasSource
	print(tile_source)
	print("tile_count, ", tile_source.get_tiles_count())
	var image = tile_source.get_texture().get_image() as Image
	for category in reference_tiles.keys():
		var tile_id_vec = reference_tiles[category]
		var texture_region = tile_source.get_tile_texture_region(tile_id_vec)
		reference_dists[category] = get_color_distribution(image.get_region(tile_source.get_tile_texture_region(tile_id_vec)))

	for id in range(0, tile_source.get_tiles_count()):
		var tile_id_vec = tile_source.get_tile_id(id)
		var texture_region = tile_source.get_tile_texture_region(tile_id_vec)
		var tile_image = image.get_region(texture_region)
		var category = _process_tile(tile_image, reference_dists)
		#print(tile_id_vec, category)
		tile_source.get_tile_data(tile_id_vec, 0).set_custom_data("tileType", category[0])
		var frequency_matrix = find_pixel_frequencies(tile_image, reference_dists[category[0]])
		var inclusion_matrix = initialize_inclusion_matrix(frequency_matrix)
		prune_negative_values(frequency_matrix, inclusion_matrix)
		var hull = find_largest_convex_hull_from_components(inclusion_matrix)
		if hull != null:
			tile_source.get_tile_data(tile_id_vec, 0).set_collision_polygons_count(0, 1)
			tile_source.get_tile_data(tile_id_vec, 0).set_collision_polygon_points(0, 0, adjust_contour_points(hull))
			
		#var polygon = adjust_contour_points(pavlidis_contour_tracing(inclusion_matrix))
		#tile_source.get_tile_data(tile_id_vec, 0).set_collision_polygons_count(0, 1)
		#tile_source.get_tile_data(tile_id_vec, 0).set_collision_polygon_points(0, 0, polygon)
		
	
	return tileset

func _process_tile(tileImage: Image, reference_dists: Dictionary):
	var colorDist = get_color_distribution(tileImage)
	var best_match_value = INF#6
	var best_match = ""
	for ref in reference_dists.keys():
		var emd = calculate_emd(colorDist, reference_dists[ref])
		if emd < best_match_value:
			best_match = ref
			best_match_value = emd
	return [best_match, best_match_value]
	

func get_color_distribution(image: Image):
	# Dictionary to store color counts
	var color_distribution = {}
	var width = image.get_width()
	var height = image.get_height()
	# Iterate over each pixel in the image
	for x in range(width):
		for y in range(height):
			var color = image.get_pixel(x, y).to_rgba32()  # Convert color to a unique integer key
			# Increment the count for this color in the distribution
			if color in color_distribution:
				color_distribution[color] += 1
			else:
				color_distribution[color] = 1
	var total = sum(color_distribution.values())
	var normed_distribution = normalize_distribution(color_distribution, total)
	return normed_distribution

static func sum(array):
	var sum = 0.0
	for element in array:
		sum += element
	return sum
	
static func get_unique_elements(arr):
	var unique_dict = {}  # Use a dictionary to track unique elements
	var unique_list = []  # List to store the unique elements

	# Iterate over each element in the array
	for element in arr:
		if not unique_dict.has(element):
			unique_dict[element] = true
			unique_list.append(element)

	return unique_list
	
# Calculates the Earth Mover's Distance (EMD) between two distributions
func calculate_emd(distribution1, distribution2):
	var keys1 = distribution1.keys()
	var keys2 = distribution2.keys()
	
	# All unique keys/colors from both distributions
	var all_keys = get_unique_elements(keys1 + keys2)
	# Normalize distributions
	var total1 = sum(distribution1.values())
	var total2 = sum(distribution2.values())
	var norm1 = normalize_distribution(distribution1, total1)
	var norm2 = normalize_distribution(distribution2, total2)

	# Calculate the cumulative distribution functions (CDFs)
	var cdf1 = calculate_cdf(norm1, all_keys)
	var cdf2 = calculate_cdf(norm2, all_keys)

	# Calculate the EMD
	var emd = 0.0
	for i in range(all_keys.size()):
		emd += abs(cdf1[i] - cdf2[i])
	return emd

# Normalize a distribution
func normalize_distribution(distribution, total):
	var normalized = {}
	for key in distribution.keys():
		normalized[key] = distribution[key] / total
	return normalized

# Calculate cumulative distribution function (CDF) for the normalized distribution
func calculate_cdf(norm_distribution, all_keys):
	var cdf = []
	var cumulative = 0.0
	for key in all_keys:
		cumulative += norm_distribution.get(key, 0)  # Use 0 if the key is not present
		cdf.append(cumulative)
	return cdf

func find_pixel_frequencies(image: Image, reference_distribution: Dictionary) -> Array:
	var width = image.get_width()
	var height = image.get_height()
	var frequency_matrix = Array()

	# Initialize the frequency matrix with default value -0.1
	for y in range(height):
		var row = []
		for x in range(width):
			row.append(-0.1)  # Default value for unmatched pixels
		frequency_matrix.append(row)

	# Populate the frequency matrix with values from the reference distribution
	for x in range(width):
		for y in range(height):
			var pixel_color = image.get_pixel(x, y).to_rgba32()
			if reference_distribution.has(pixel_color):
				frequency_matrix[y][x] = reference_distribution[pixel_color]
			else:
				frequency_matrix[y][x] = -0.1  # This line is optional since it's already initialized

	return frequency_matrix
	
func initialize_inclusion_matrix(frequency_matrix):
	var inclusion_matrix = []
	for i in range(frequency_matrix.size()):
		var row = []
		for j in range(frequency_matrix[i].size()):
			row.append(1)  # Start with all points included
		inclusion_matrix.append(row)
	return inclusion_matrix

func prune_negative_values(frequency_matrix, inclusion_matrix):
	var changes = true
	while changes:
		changes = false
		for i in range(frequency_matrix.size()):
			for j in range(frequency_matrix[i].size()):
				if inclusion_matrix[i][j] == 1 and frequency_matrix[i][j] < 0:
					# Check if setting this point to 0 increases the total value
					if can_remove_point(frequency_matrix, inclusion_matrix, i, j):
						inclusion_matrix[i][j] = 0
						changes = true

func can_remove_point(frequency_matrix, inclusion_matrix, i, j):
	# Additional checks can be added here to decide if removing a point is beneficial
	return true  # Simplistic approach for now
	
func get_points_from_matrix(inclusion_matrix):
	var points = PackedVector2Array()
	for y in range(inclusion_matrix.size()):
		for x in range(inclusion_matrix[y].size()):
			if inclusion_matrix[y][x] == 1:
				points.append(Vector2(x, y))
	return points
	
func find_largest_convex_hull(inclusion_matrix):
	var points = get_points_from_matrix(inclusion_matrix)
	var hull = Geometry2D.convex_hull(points)
	# Optionally, find convex hulls for all components if you have multiple disconnected components
	# This would require segmenting the points by connectedness first, which is not covered here
	return hull
	
func calculate_hull_area(hull: PackedVector2Array) -> float:
	var area = 0.0
	var n = hull.size()
	for i in range(n):
		var j = (i + 1) % n  # Wrap around to the first vertex
		area += hull[i].x * hull[j].y - hull[j].x * hull[i].y
	return abs(area) / 2.0
	
func find_largest_convex_hull_from_components(inclusion_matrix):
	var points = get_points_from_matrix(inclusion_matrix)
	var largest_hull = null
	var max_area = -1.0
	
	# Assuming components were separated (if you handle multiple disconnected parts)
	# var components = segment_into_components(points) # This needs implementation if needed
	# for component in components:
	#     var hull = Geometry.convex_hull(component)
	#     var area = calculate_hull_area(hull)
	#     if area > max_area:
	#         max_area = area
	#         largest_hull = hull
	
	# For single component scenario:
	var hull = Geometry2D.convex_hull(points)
	var area = calculate_hull_area(hull)
	if area > max_area:
		max_area = area
		largest_hull = hull
	
	return largest_hull
#
func calculate_offsets(contour):
	var min_x = float('inf')
	var max_x = float('-inf')
	var min_y = float('inf')
	var max_y = float('-inf')
	
	for point in contour:
		min_x = min(min_x, point.x)
		max_x = max(max_x, point.x)
		min_y = min(min_y, point.y)
		max_y = max(max_y, point.y)
	
	var width = max_x - min_x
	var height = max_y - min_y
	
	return Vector2(width / 2 + min_x, height / 2 + min_y)  # Return the offsets for x and y
	
func adjust_contour_points(contour):
	var offsets = calculate_offsets(contour)
	var offset_x = offsets[0]
	var offset_y = offsets[1]
	
	var adjusted_contour = PackedVector2Array()
	for point in contour:
		var adjusted_point = Vector2(point.x - offset_x, point.y - offset_y)
		adjusted_contour.append(adjusted_point)
	
	return adjusted_contour
