extends Control
class_name LevelSelectMenu

const CLASS_NAME = "LevelSelectMenu"

func get_class() -> String:
	return CLASS_NAME

signal selected_back()
signal selected_level(level_id)

export(PackedScene) var level_button_scene: PackedScene

func _ready() -> void:
	var level_buttons_container: Control = get_tree().get_nodes_in_group("LevelButtonsContainer")[0]
	for child in level_buttons_container.get_children():
		child.queue_free()
	for level_id in GameData.WAVE_DATA.keys():
		var level_completion_record: Dictionary = SaveGameController.get_level_completion_record(level_id)
		var level_button: LevelSelectButton = level_button_scene.instance()
		level_buttons_container.add_child(level_button)
		level_button.set_level_completion(level_completion_record.get("completed", false))
		level_button.set_level_label_text(level_id)
		level_button.connect("pressed", self, "_on_level_button_pressed", [level_id])

func _on_level_button_pressed(_level_id: String):
	emit_signal("selected_level", _level_id)

func _on_B_BackToMain_pressed() -> void:
	emit_signal("selected_back")
