extends Control
class_name LevelSelectMenu

signal selected_back_to_main()
signal selected_level(level_id)

export(PackedScene) var level_button_scene: PackedScene

func _ready() -> void:
	var level_buttons_container: Control = get_tree().get_nodes_in_group("LevelButtonsContainer")[0]
	for child in level_buttons_container.get_children():
		child.queue_free()
	for level_id in GameData.WAVE_DATA.keys():
		var level_button: LevelSelectButton = level_button_scene.instance()
		level_buttons_container.add_child(level_button)
		level_button.set_level_label_text(level_id)
		level_button.connect("pressed", self, "_on_level_button_pressed", [level_id])

func _on_level_button_pressed(_level: String):
	emit_signal("selected_level", _level)

func _on_B_BackToMain_pressed() -> void:
	emit_signal("selected_back_to_main")
