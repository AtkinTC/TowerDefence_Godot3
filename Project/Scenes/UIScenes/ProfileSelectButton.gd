extends TextureButton
class_name ProfileSelectButton

onready var profile_name_label: Label = get_node("V/ProfileNameLabel")
onready var profile_date_label: Label = get_node("V/ProfileDateLabel")

func set_profile_name_label_text(_text: String):
	profile_name_label.text = _text

func set_profile_date_label_text(_text: String):
	profile_date_label.text = _text
