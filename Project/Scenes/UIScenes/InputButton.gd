extends TextureButton
class_name InputButton

onready var input_label: Label = get_node_or_null("InputLabel")

func _ready() -> void:
	update_input_label()
	self.set_tooltip(self.name)
	if(input_label != null && input_label.get_text().length() != 0):
		self.set_tooltip(self.name + " : " + input_label.get_text())

#sets the input label to display the first mapped keyboard key
func update_input_label() -> void:
	if(input_label != null):
		var label_text: String = ""
		var input_shortcut: ShortCut = self.get_shortcut()
		var input_event : InputEvent = input_shortcut.get_shortcut()
		if(input_event is InputEventAction):
			var action_name: String = input_event.get_action()
			var action_inputs: Array = InputMap.get_action_list(action_name)
			for input in action_inputs:
				if(input is InputEventKey):
					label_text = input.as_text()
		input_label.set_text(label_text)
