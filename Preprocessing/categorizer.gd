@tool
extends EditorScript

var reference_tiles = {
		"wa_water": Vector2i(9, 3),
		"fl_field": Vector2i(9,0),
		"tr_tree": Vector2i(6, 3),
		"mt_mountain": Vector2i(11, 11),
		"hl_hill": Vector2i(15, 9),
		"gc_grass_cliff": Vector2i(21, 17),
		"dc_desert_cliff": Vector2i(4, 15),
		"sa_sand": Vector2i(16, 0),
		"rd_road": Vector2i(15, 5),
		"vl_village": Vector2i(15, 6),
		"cs_castle": Vector2i(16, 24)
	}

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

func process_tileset(tileset: TileSet):
	print("process_tileset, ", tileset)
	var tile_source = tileset.get_source(0) as TileSetAtlasSource
	print(tile_source)
	print("tile_count, ", tile_source.get_tiles_count())
	var image = tile_source.get_texture().get_image() as Image
	for key:String in reference_tiles.keys():
		var ref_tile_id_vec = reference_tiles[key]
		var texture_region = tile_source.get_tile_texture_region(ref_tile_id_vec)
		var tile_image = image.get_region(texture_region)
		reference_tiles[key] = get_colormap(get_image_pixel_array(tile_image))
		
	for id in range(0, tile_source.get_tiles_count()):
		var tile_id_vec = tile_source.get_tile_id(id)
		var texture_region = tile_source.get_tile_texture_region(tile_id_vec)
		var tile_image = image.get_region(texture_region)
		#var category = _process_tile(tile_image, reference_dists)
		print("tile: ", tile_id_vec)
		var pixel_matrix = Matrix.new(tile_image.get_height(), tile_image.get_width())
		for x in tile_image.get_width():
			for y in tile_image.get_height():
				pixel_matrix.set_value(x, y, _hue_classifier(tile_image.get_pixelv(Vector2i(x, y)).h*360))
		var region_matrix = region_grower(pixel_matrix, tile_image)
		var region_dict = calc_region_dict(region_matrix)
		#print("region_dict: ", region_dict)
		for code in region_dict.keys():
			var region_pixels = []
			for pixel_vector in region_dict[code]:
				region_pixels.append(tile_image.get_pixelv(pixel_vector))
			var tile_category = categorize_pixel_array(region_pixels, reference_tiles)
			region_matrix.replace(code, tile_category.split("_")[0])
		region_matrix.display()
		
		#var packed_region_dict = {}
		#for key in region_dict.keys():
			#packed_region_dict[key] = get_perimeter(region_dict[key])
		#var polyCount = 0
		#var polygonsTotal = 0
		#for key in packed_region_dict.keys():
			#for polygon in packed_region_dict[key]:
				#polygonsTotal += 1
		#tile_source.get_tile_data(tile_id_vec, 0).set_collision_polygons_count(0, polygonsTotal)
		#for key in packed_region_dict.keys():
			#print("key: ", key)
			#print("edges: ", packed_region_dict[key])
			#var polygon = adjust_contour_points(packed_region_dict[key])
			#tile_source.get_tile_data(tile_id_vec, 0).set_collision_polygon_points(0, polyCount, polygon)
			#polyCount += 1
			
	return tileset

func linearize(value: float) -> float:
	if value <= 0.04045:
		return value / 12.92
	else:
		return pow((value + 0.055) / 1.055, 2.4)
func cie_lab_helper(t: float) -> float:
	if t > 0.008856:
		return pow(t, 1.0/3.0)
	else:
		return (7.787 * t) + (16.0 / 116.0)
func rgb_to_lab(color: Color) -> Array:
	# Convert sRGB to linear RGB
	var r = linearize(color.r)
	var g = linearize(color.g)
	var b = linearize(color.b)

	# Convert linear RGB to XYZ
	var x = r * 0.4124564 + g * 0.3575761 + b * 0.1804375
	var y = r * 0.2126729 + g * 0.7151522 + b * 0.0721750
	var z = r * 0.0193339 + g * 0.1191920 + b * 0.9503041

	# Normalize for D65 white point
	x /= 95.047
	y /= 100.000
	z /= 108.883

	# Convert XYZ to LAB
	x = cie_lab_helper(x)
	y = cie_lab_helper(y)
	z = cie_lab_helper(z)

	var L = (116 * y) - 16
	var a = 500 * (x - y)
	b = 200 * (y - z)

	return [L, a, b, color.a]  # Preserving the alpha value
func map_colors_to_indices(rgba_matrix:Matrix) -> Matrix:
	var color_map = {}
	var index = 0
	var indexed_color_matrix = Matrix.new(rgba_matrix.cols, rgba_matrix.rows, null)

	# Create a mapping from RGBA to index
	for row in range(rgba_matrix.rows):
		for col in range(rgba_matrix.cols):
			var color = rgba_matrix.get_value(row, col)
			if not color_map.has(color):
				color_map[color] = index
				index += 1
			indexed_color_matrix.set_value(row, col, color_map[color])
	return indexed_color_matrix
	
class Matrix:

	# Properties for storing matrix data
	var data = []
	var rows = 0
	var cols = 0
	# Constructor to initialize the matrix with dimensions rows x cols and optional fill value
	func _init(rows: int, cols: int, fill_value: Variant = 0):
		self.rows = rows
		self.cols = cols
		data.resize(rows)
		for i in range(rows):
			data[i] = []
			data[i].resize(cols)
			for j in range(cols):
				data[i][j] = fill_value
				
	func set_value(row: int, col: int, value: Variant):
		if row >= 0 and row < rows and col >= 0 and col < cols:
			data[row][col] = value
		else:
			push_error("Index out of range: (" + str(row) + ", " + str(col) + ")")

	func get_value(row: int, col: int) -> Variant:
		if row >= 0 and row < rows and col >= 0 and col < cols:
			return data[row][col]
		else:
			push_error("Index out of range: (" + str(row) + ", " + str(col) + ")")
			return null

	func display():
		# First determine the maximum string length in each column
		var column_widths = []
		for i in range(cols):
			var max_length = 0
			for j in range(rows):
				var length = str(data[j][i]).length()
				if length > max_length:
					max_length = length
			column_widths.append(max_length)

		# Now print each row with proper spacing
		for row in data:
			var line = ""
			for i in range(row.size()):
				var cell = str(row[i])
				# Pad the string to the length of the longest string in the column
				var padded_cell = cell.rpad(column_widths[i] + 1)  # Add space for padding
				line += padded_cell
			print(line)
	
	func flatten()-> Array:
		var list = []
		for col in range(cols):
			for row in range(rows):
				list.append(get_value(row, col))
		return list
		
	func replace(target_val: Variant, new_val: Variant):
		for i in range(rows):
			for j in range(cols):
				if typeof(data[i][j]) == typeof(target_val):
					if data[i][j] == target_val:
						data[i][j] = new_val

	func get_dimensions() -> Vector2:
		return Vector2(rows, cols)
	
	func calculate_frequencies() -> Dictionary:
		var frequencies = {}
		for row in data:
			for element in row:
				if frequencies.has(element):
					frequencies[element] += 1
				else:
					frequencies[element] = 1
		return frequencies
	
func get_image_pixel_array(image:Image) -> Array:
	var pixel_array = []
	var width = image.get_width()
	var height = image.get_height()
	# Iterate over each pixel in the image
	for x in range(width):
		for y in range(height):
			pixel_array.append(image.get_pixel(x, y))
	return pixel_array
	
func get_colormap(pixels:Array):
	var color_distribution = {}
	for p in pixels:
		var color = p.to_rgba32()
		if color in color_distribution:
			color_distribution[color] += 1
		else:
			color_distribution[color] = 1
	var total = sum(color_distribution.values())
	var normed_distribution = normalize_distribution(color_distribution, total)
	return normed_distribution
	
func categorize_pixel_array(pixel_array:Array, reference_dists: Dictionary) -> String:
	var colorDist = get_colormap(pixel_array)
	var best_match_value = INF
	var best_match = "??"
	for ref in reference_dists.keys():
		var emd = calculate_emd(colorDist, reference_dists[ref])
		if emd < best_match_value:
			best_match = ref
			best_match_value = emd
	return best_match
	
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

static func find_min_value_entry(dictionary: Dictionary) -> Array:
	var min_key = null
	var min_value = INF  # Use INF as a placeholder for infinity

	# Iterate over each item in the dictionary
	for key in dictionary.keys():
		if dictionary[key] < min_value:
			min_value = dictionary[key]
			min_key = key

	# Return both the key and the value of the smallest entry
	return [min_key, min_value]
	
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

func get_pixel_panels(image: Image, span: int) -> Dictionary:
	var panels = Dictionary()

	# Iterate through each pixel in the image
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			# Calculate the sub-image bounds
			var min_x = max(x - span, 0)
			var max_x = min(x + span, image.get_width() - 1)
			var min_y = max(y - span, 0)
			var max_y = min(y + span, image.get_height() - 1)
			
			# Create a new sub-image for these bounds
			var sub_image = image.get_region(Rect2(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1))
			var sub_image_pixel_list = []
			for i in range(sub_image.get_height()):
				for j in range(sub_image.get_width()): 
					sub_image_pixel_list.append(sub_image.get_pixelv(Vector2(j, i)))
			panels[Vector2(x, y)] = sub_image_pixel_list

	return panels
	
func _process_tile_by_pixel(tileImage: Image) -> Matrix:
	var pixel_colormap_matrix = Matrix.new(tileImage.get_height(), tileImage.get_width(), -1)
	var panels = get_pixel_panels(tileImage, 1)
	for y in range(tileImage.get_height()):
		for x in range(tileImage.get_width()):
			pixel_colormap_matrix.set_value(x, y, get_colormap(panels[Vector2(x, y)]))
	return pixel_colormap_matrix

func region_grower(pixel_matrix:Matrix, tile_image:Image) -> Matrix: 
	var visited = Matrix.new(pixel_matrix.cols, pixel_matrix.rows, false)
	var regions_matrix = Matrix.new(pixel_matrix.cols, pixel_matrix.rows, false)
	var directions = [Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1)]
	var regionCounter = 0
	# Main loop
	while true:
		var seed = _find_seed(pixel_matrix, visited)
		if seed == null:
			break
		var new_region = _grow_region(seed, pixel_matrix, visited, directions, tile_image)
		for vec in new_region:
			regions_matrix.set_value(vec.y, vec.x, regionCounter)
		regionCounter += 1
	consolidate_regions(regions_matrix)
	return regions_matrix
	
func consolidate_regions(region_matrix: Matrix):
	var region_sizes = region_matrix.calculate_frequencies()

	# Define the offsets for checking the neighbors (up, down, left, right)
	var neighbor_offsets = [
		Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0), Vector2(1, 0)
	]
	if len(region_sizes.values()) <= 1:
		return
	while region_sizes.values().min() < 4:
		# Find the smallest region
		var min_region = null
		var min_size = INF
		for key in region_sizes:
			if region_sizes[key] < min_size:
				min_size = region_sizes[key]
				min_region = key

		# Store the frequencies of neighbor regions for cells in the smallest region
		var neighbor_frequencies = {}
		for i in range(region_matrix.rows):
			for j in range(region_matrix.cols):
				if region_matrix.get_value(i, j) == min_region:
					# Check each neighbor
					for offset in neighbor_offsets:
						var neighbor_pos = Vector2(i, j) + offset
						if _is_valid_index(Vector2(neighbor_pos.x, neighbor_pos.y), region_matrix):
							var neighbor_value = region_matrix.get_value(neighbor_pos.x, neighbor_pos.y)
							if neighbor_value != min_region:
								if neighbor_frequencies.has(neighbor_value):
									neighbor_frequencies[neighbor_value] += 1
								else:
									neighbor_frequencies[neighbor_value] = 1

		# Find the most common neighboring region
		var most_common_neighbor = null
		var highest_frequency = 0
		for region in neighbor_frequencies:
			if neighbor_frequencies[region] > highest_frequency:
				highest_frequency = neighbor_frequencies[region]
				most_common_neighbor = region

		# Replace all cells in the smallest region with the most common neighboring region
		for i in range(region_matrix.rows):
			for j in range(region_matrix.cols):
				if region_matrix.get_value(i, j) == min_region:
					region_matrix.set_value(i, j, most_common_neighbor)

		# Update region sizes
		if most_common_neighbor in region_sizes:
			region_sizes[most_common_neighbor] += region_sizes[min_region]
		region_sizes.erase(min_region)

		# Recalculate the smallest size
		region_sizes = region_matrix.calculate_frequencies()
		
func calc_region_dict(region_matrix: Matrix) -> Dictionary:
	var region_dict = {}
	for col in range(region_matrix.cols):
		for row in range(region_matrix.rows):
			if region_dict.has(region_matrix.get_value(row, col)):
				region_dict[region_matrix.get_value(row, col)].append(Vector2(col, row))
			else:
				region_dict[region_matrix.get_value(row, col)] = [Vector2(col, row)]
	return region_dict
	
func _find_seed(pixel_matrix:Matrix, visited:Matrix):
	var unvisited_pixels = []
	
	# Gather all unvisited pixels
	for x in range(pixel_matrix.cols):
		for y in range(pixel_matrix.rows):
			if not visited.get_value(y, x):
				unvisited_pixels.append(Vector2(x, y))
	
	# Randomly select a seed from unvisited pixels
	if unvisited_pixels.size() > 0:
		var random_index = randi() % unvisited_pixels.size()
		return unvisited_pixels[random_index]
	else:
		return null  # Return null if no unvisited pixels are left
		
func _grow_region(seed:Vector2, pixel_matrix:Matrix, visited:Matrix, directions:Array, tile_image: Image) -> Array:
	var stack = []
	var region = []
	stack.push_back(seed)
	while !stack.is_empty():
		var point = stack.pop_back()
		if visited.get_value(point.y, point.x) == false:
			visited.set_value(point.y, point.x, true)
			region.append(point)
			for dir in directions:
				var neighbor = point + dir
				if _is_valid_index(neighbor, pixel_matrix):
					if visited.get_value(neighbor.y, neighbor.x) == false:
						if _is_similar(point, neighbor, tile_image):
							if neighbor not in stack:
								stack.push_back(neighbor)
	return region
func _hue_classifier(hue:float):
	if hue < 45:
		return "r"
	else: if hue < 80:
		return "y"
	else: if hue < 180:
		return "g"
	else: if hue < 240:
		return "c"
	else: if hue < 300:
		return "b"
	else:
		return "m"
func _is_similar(point1:Vector2, point2:Vector2, tile_image: Image) -> bool:
	var color1: Color = tile_image.get_pixelv(point1)
	var color2: Color = tile_image.get_pixelv(point2)
	if _hue_classifier(color1.h*360) == _hue_classifier(color2.h*360):
		return true
	else:
		return false
func _is_valid_index(index: Vector2, grid: Matrix) -> bool:
	# Check if y is within the range of the grid's outer array
	if index.y >= 0 and index.y < grid.cols:
		# Check if x is within the range of the inner array at the y-th position
		if index.x >= 0 and index.x < grid.rows:
			return true
	return false

func is_collinear(p1: Vector2, p2: Vector2, p3: Vector2) -> bool:
	return (p3.y - p2.y) * (p2.x - p1.x) == (p2.y - p1.y) * (p3.x - p2.x)

func _create_edge_map(tiles) -> Dictionary:
	var edges = {}
	var directions = [
		Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1)
	]
	for tile in tiles:
		for dir in directions:
			var neighbor = tile + dir
			if neighbor not in tiles:
				edges.merge(_create_edge(tile, dir))
	return edges
	
func _create_edge(tile: Vector2, direction: Vector2):
	if direction == Vector2(0, -1):  # Up
		return {Vector2(tile.x, tile.y): Vector2(tile.x + 1, tile.y)}
	elif direction == Vector2(0, 1):  # Down
		return {Vector2(tile.x + 1, tile.y + 1): Vector2(tile.x, tile.y + 1)}
	elif direction == Vector2(-1, 0):  # Left
		return {Vector2(tile.x, tile.y + 1): Vector2(tile.x, tile.y)}
	elif direction == Vector2(1, 0):  # Right
		return {Vector2(tile.x + 1, tile.y): Vector2(tile.x + 1, tile.y + 1)}
		
func get_perimeter(tiles) -> PackedVector2Array:
	var edges = _create_edge_map(tiles)
	var starting_point = edges.keys()[0] # It shouldn't matter which one this is.
	var perimeter = [starting_point]
	var current_point = edges[starting_point]
	while current_point != starting_point:
		if !is_collinear(perimeter.back(), current_point, edges[current_point]):
			perimeter.append(current_point)
			current_point = edges[current_point]
		else:
			current_point = edges[current_point]
	if is_collinear(perimeter.back(), starting_point, edges[starting_point]):
		perimeter.pop_front()
		perimeter.append(perimeter[0])
	else:
		perimeter.append(current_point)
	return PackedVector2Array(perimeter)
	
func calculate_area(perimeter: PackedVector2Array) -> float:
	var area: float = 0.0
	var n: int = perimeter.size()
	if n < 3:
		print("Not enough vertices to form a polygon.")
		return 0.0

	# Implementing the Shoelace formula
	for i in range(n):
		var j: int = (i + 1) % n  # Next vertex index, wraps around
		var xi: float = perimeter[i].x
		var yi: float = perimeter[i].y
		var xj: float = perimeter[j].x
		var yj: float = perimeter[j].y
		area += xi * yj - yi * xj

	return abs(area / 2.0)
	
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
