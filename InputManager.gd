# InputManager.gd
extends Node

var menu_stack: Array = []

func push_scene(scene: Node):
	menu_stack.append(scene)
	# optionally, disable input processing on the previous scene
	if menu_stack.size() > 1:
		get_scene_under(scene).set_process_input(false)

func pop_scene():
	var current_scene = menu_stack.pop_back()
	current_scene.queue_free()  # or just hide it based on your use case
	# re-enable input processing on the new current scene
	if menu_stack.size() >= 1:
		get_scene_under(menu_stack.back()).set_process_input(true)

func get_scene_under(scene):
	return menu_stack[menu_stack.find(scene) - 1]

func _input(event):
	if menu_stack.size() > 0:
		menu_stack.back().input(event)  # forward input to the top scene
