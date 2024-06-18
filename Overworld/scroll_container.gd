extends ScrollContainer

@onready var castleDescription = $CastleDescription

func _ready():
	# Check if running in debug mode
	if OS.is_debug_build():
		# Create and setup the toggle button
		var toggle_button = Button.new()
		toggle_button.text = "Toggle Edit"
		add_child(toggle_button)  # Add the button as a child to the parent node
		castleDescription.editable = true  # Start with the description being read-only

		# Connect the 'pressed' signal using a Callable
		castleDescription.connect("pressed", Callable(self, "_on_toggle_edit_pressed"))

func _on_toggle_edit_pressed():
	# Toggle the read-only status of the TextEdit
	castleDescription.editable = !castleDescription.editable
