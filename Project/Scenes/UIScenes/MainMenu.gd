extends Control
class_name MainMenu

signal selected_new_game()
signal selected_continue()
signal selected_settings()
signal selected_quit()

func _on_B_NewGame_pressed():
	emit_signal("selected_new_game")
	
func _on_B_Continue_pressed():
	emit_signal("selected_continue")

func _on_B_Settings_pressed():
	emit_signal("selected_settings")

func _on_B_Quit_pressed():
	emit_signal("selected_quit")
