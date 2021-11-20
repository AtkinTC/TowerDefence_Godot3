extends TextureButton
class_name LevelSelectButton

onready var completion_icon : ColorRect = get_node("CompletionIcon")
onready var level_label: Label = get_node("LevelLabel")

func set_level_label_text(_text: String):
	level_label.text = _text

func set_level_completion(_completed: bool):
	if(_completed):
		completion_icon.color = Color.blue
	else:
		completion_icon.color = Color.red
