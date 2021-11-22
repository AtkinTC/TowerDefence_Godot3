extends Control
class_name ProfileSelectScreen

const CLASS_NAME: String = "ProfileSelectScreen"

func get_class() -> String:
	return CLASS_NAME

signal selected_back_to_main()
signal loaded_continue_profile()

var save_games: Array

export(PackedScene) var profile_button_scene: PackedScene 

func _ready() -> void:
	var profile_buttons_container: Control = get_tree().get_nodes_in_group("ProfileButtonsContainer")[0]
	
	for child in profile_buttons_container.get_children():
		child.queue_free()
	
	save_games = SaveGameController.get_all_save_games()
	for save in save_games:
		var profile_name: String = (save as GameSave).get(GameSave.SAVE_VAR_SAVE_NAME)
		if(profile_name == null || profile_name == ""):
			profile_name = "- - -"
		var profile_date_time: Dictionary = (save as GameSave).get(GameSave.SAVE_VAR_SAVE_DATE_TIME)
		
		var profile_date_time_string: String = ""
		if(profile_date_time.size() > 0):
			#year, month, day, hour, minute, second
			profile_date_time_string += str(profile_date_time["year"])
			profile_date_time_string += "-" + str(profile_date_time["month"])
			profile_date_time_string += "-" + str(profile_date_time["day"])
			profile_date_time_string += " " + str(profile_date_time["hour"])
			profile_date_time_string += ":" + str(profile_date_time["minute"])
			profile_date_time_string += ":" + str(profile_date_time["second"])
		
		print("game file : " + profile_name)
		
		var profile_button: ProfileSelectButton = profile_button_scene.instance()
		profile_buttons_container.add_child(profile_button)
		profile_button.set_profile_name_label_text(profile_name)
		profile_button.set_profile_date_label_text(profile_date_time_string)
		profile_button.connect("pressed", self, "_on_profile_button_pressed", [profile_name])
	
func _on_profile_button_pressed(_profile_id: String):
	if(SaveGameController.load_as_current_game(_profile_id)):
		emit_signal("loaded_continue_profile")
	else:
		print(CLASS_NAME + " : could not load profile : " + _profile_id)

func _on_B_BackToMain_pressed() -> void:
	emit_signal("selected_back_to_main")
