# InputManager.gd
extends Node

var menu_stack: Array = []

func push_scene(scene: Node):
	menu_stack.append(scene)

func pop_scene():
	if menu_stack.is_empty():
		return
	var current_scene = menu_stack.pop_back()

func _input(event):
	if menu_stack.size() > 0:
		if menu_stack.back().has_method("_handle_input"):
			menu_stack.back()._handle_input(event)
		else:
			handle_default_input(event)
	else:
		handle_default_input(event)

func handle_default_input(event):
	# Check if the event corresponds to the 'ui_escape' action and if it was just pressed
	if event.is_action_pressed("ui_end"):
		print("End action triggered!")
		get_tree().quit()  # Quit the game or perform any necessary action
