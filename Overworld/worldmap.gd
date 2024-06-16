extends Node2D

@onready var castleManager = $CastleManager
@onready var cursor = $Cursor
@onready var castleHUD = $HUDLayer/CastleHUD
@onready var SelectedCastle = $CastleManager/Chalphy

signal selected_castle_changed(castle: Node2D)



signal zoom_changed(new_zoom)
@export var zoom: float = float() :
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
	cursor.position = SelectedCastle.position
	emit_signal("selected_castle_changed", SelectedCastle)

func _process(delta):
	if Input.is_action_just_pressed("ui_up") and SelectedCastle.up:
		start_movement(SelectedCastle.up)
	if Input.is_action_just_pressed("ui_down") and SelectedCastle.down:
		start_movement(SelectedCastle.down)
	if Input.is_action_just_pressed("ui_left") and SelectedCastle.left:
		start_movement(SelectedCastle.left)
	if Input.is_action_just_pressed("ui_right") and SelectedCastle.right:
		start_movement(SelectedCastle.right)
	elif Input.is_action_just_pressed("ui_zoom_in"):
		zoom = zoom * 2
	elif Input.is_action_just_pressed("ui_zoom_out"):
		zoom = zoom / 2

	if not completed_movement:
		lerp_progress += lerp_speed * delta
		cursor.position = cursor.position.lerp(target_position, lerp_progress)
		if lerp_progress >= 1.0 or cursor.position.distance_to(target_position) < 1.0:
			cursor.position = target_position
			completed_movement = true
			lerp_progress = 0.0
	
	emit_signal("cursor_moved", cursor.position)  # Emit the cursor moved signal

func start_movement(targetCastle:Castle):	
	target_position = targetCastle.global_position
	completed_movement = false
	lerp_progress = 0.0
	for arrow in SelectedCastle.arrows:
		SelectedCastle.remove_child(arrow)
	SelectedCastle.arrows.clear()
	SelectedCastle = targetCastle
	emit_signal("selected_castle_changed", SelectedCastle)
