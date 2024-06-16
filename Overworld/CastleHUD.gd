extends Control

@export var label_path: NodePath = "CastleName"  # Path to the Label inside the HUD
@export var banner_path: NodePath = "Banner"  # Path to the Sprite2D for the banner
@onready var Arrow = preload("res://Overworld/Arrow.gd")
@onready var label = get_node(label_path)
@onready var banner = get_node_or_null(banner_path)  # Use get_node_or_null to handle cases where the node might be missing
func update(castle: Node2D):
	$CastleName.text = castle.name
	if banner:
		var sprite_color = castle.get_node("Sprite2D").modulate

		# Convert sprite color to a color vector
		var base_color = Color(sprite_color.r, sprite_color.g, sprite_color.b)

		# Set the shader parameter for the marble color
		var shader_material = banner.material as ShaderMaterial
		if shader_material:
			shader_material.set("shader_parameter/base_color", base_color)

func _on_selected_castle_change(castle):
	update(castle)
	generate_arrows(castle)

func generate_arrows(castle: Castle) -> void:
	# Generate new arrows
	if castle.up: add_arrow(castle, castle.up)
	if castle.down: add_arrow(castle, castle.down)
	if castle.left: add_arrow(castle, castle.left)
	if castle.right: add_arrow(castle, castle.right)

func add_arrow(start_castle: Castle, target_castle: Castle) -> void:
	var arrow = Arrow.new()
	arrow.start_castle = start_castle
	arrow.end_castle = target_castle
	start_castle.add_child(arrow)
	start_castle.arrows.append(arrow)
	
