extends Control
class_name ProfileMenu

const CLASS_NAME = "ProfileMenu"

func get_class() -> String:
	return CLASS_NAME

signal selected_level_select()
signal selected_back()
signal selected_quit()

func _on_B_LevelSelect_pressed() -> void:
	emit_signal("selected_level_select")

func _on_B_Back_pressed() -> void:
	emit_signal("selected_back")

func _on_B_Quit_pressed() -> void:
	emit_signal("selected_quit")
