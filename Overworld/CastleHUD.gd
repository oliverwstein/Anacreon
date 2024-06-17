extends Control

@export var label_path: NodePath = "CastleName"  # Path to the Label inside the HUD
@export var banner_path: NodePath = "Banner"  # Path to the Sprite2D for the banner
@onready var label = get_node(label_path)
@onready var banner = get_node(banner_path)

@export var base_color: Color = Color.BLUE

func update(castle: Castle):
	$CastleName.text = castle.name
	if banner:
		var sprite_color = castle.get_node("Sprite2D").modulate

		# Convert sprite color to a color vector
		base_color = Color(sprite_color.r, sprite_color.g, sprite_color.b)

		# Set the shader parameter for the marble color
		var shader_material = banner.material as ShaderMaterial
		if shader_material:
			shader_material.set("shader_parameter/base_color", base_color)


func _ready():
	# Set the shader parameter for the marble color
	var shader_material = banner.material as ShaderMaterial
	if shader_material:
		shader_material.set("shader_parameter/base_color", base_color)
		
func _on_selected_castle_changed(castle):
	update(castle)
	
