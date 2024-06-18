extends TextEdit

func _ready():
	self.editable = false


func _on_edit_button_toggled(toggled_on):
	if toggled_on:
		InputManager.push_scene(self)
		self.editable = true
		self.grab_focus()
		print("Text when editable:", self.text)
	else:
		InputManager.pop_scene()
		self.editable = false
		self.release_focus()
		print("Text when read-only:", self.text)
