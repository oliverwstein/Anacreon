# WorldMapRoot.gd
extends Node2D

@onready var castleManager = $CastleManager
@onready var cursor = $Cursor
@onready var castleHUD = $HUDLayer/CastleHUD

signal zoom_changed(new_zoom)
@export var zoom: float = 1.0:  # Assuming initial zoom level
	get:
		return zoom
	set(value):
		zoom = clampf(value, 0.25, 4)
		emit_signal("zoom_changed", zoom)

signal cursor_moved(new_position: Vector2)
var lerp_speed = 5  # This can be adjusted to control the speed of the lerp
var lerp_progress = 0.0
var completed_movement = true
var target_position = Vector2()

func _ready():
	cursor.position = castleManager.selected_castle.position
	InputManager.push_scene(self)

func _handle_input(event):
	if event is InputEventKey and event.pressed:
		if event.is_action("ui_up") and castleManager.selected_castle.up:
			castleManager.selected_castle = castleManager.selected_castle.up
		elif event.is_action("ui_down") and castleManager.selected_castle.down:
			castleManager.selected_castle = castleManager.selected_castle.down
		elif event.is_action("ui_left") and castleManager.selected_castle.left:
			castleManager.selected_castle = castleManager.selected_castle.left
		elif event.is_action("ui_right") and castleManager.selected_castle.right:
			castleManager.selected_castle = castleManager.selected_castle.right
		elif event.is_action("ui_accept") and castleManager.selected_castle:
			castleManager.open_castle()
		elif event.is_action("ui_zoom_in"):
			zoom *= 2
		elif event.is_action("ui_zoom_out"):
			zoom /= 2
		elif event.is_action("ui_save"):
			for castle in castleManager.get_children():
				if castle is Castle:
					castleManager.save_castle_to_json(castle)
		elif event.is_action("ui_load"):
			castleManager.load_all_castles()
