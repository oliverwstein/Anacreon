extends Line2D

@export var start_castle: Castle
@export var end_castle: Castle
@export var arrow_thickness: float = 5.0
@export var arrow_color: Color = Color(1, 0.843, 0, 1)  # Golden color
@export var shortening_factor: float = 20.0  # Pixels to shorten from each end

func _ready():
	width = arrow_thickness
	default_color = arrow_color
	update_arrow()
	visible = true
	apply_golden_shader()

func update_arrow():
	clear_points()
	if start_castle and end_castle:
		var local_start_position = to_local(start_castle.global_position)
		var local_end_position = to_local(end_castle.global_position)
		
		# Calculate direction and shorten the line
		var direction = (local_end_position - local_start_position).normalized()
		local_start_position += direction * shortening_factor
		local_end_position -= direction * shortening_factor
		
		# Update points
		clear_points()
		add_point(local_start_position)
		add_point(local_end_position)
		queue_redraw()  # Force redraw to reflect changes
	else:
		print("Lacking start or end castle", start_castle, end_castle)

func apply_golden_shader():
	# Create a new ShaderMaterial
	var shader_material = ShaderMaterial.new()
	
	# Assign a shader to it
	var shader = Shader.new()
	shader.code = """
	shader_type canvas_item;
	void fragment() {
		float noise = sin(UV.x * 40.0 + UV.y * 40.0 + TIME * 2.0) * 0.5 + 0.5;
		COLOR = vec4(mix(vec3(1.0, 0.8, 0.0), vec3(1.0), noise), 1.0);
	}
	"""
	shader_material.shader = shader
	self.material = shader_material
