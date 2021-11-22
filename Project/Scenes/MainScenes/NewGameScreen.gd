extends Control
class_name NewGameScreen

const CLASS_NAME = "NewGameScreen"

func get_class() -> String:
	return CLASS_NAME

signal selected_back_to_main()
signal created_new_game()

var profile_name_input: TextEdit

func _ready():
	profile_name_input = get_tree().get_nodes_in_group("ProfileNameInput")[0]

func verify_and_submit_new_profile():
	var profile_name_input_string: String = profile_name_input.get_text()
	
	if(profile_name_input_string == null || profile_name_input_string.length() == 0):
		print("NewGameScene: no profile name entered")
		return false
	if(!profile_name_input_string.is_valid_filename()):
		print("NewGameScene: profile name invalid")
		return false
		
	SaveGameController.create_new_game_save(profile_name_input_string)
	emit_signal("created_new_game")
	
func _on_B_Submit_pressed() -> void:
	verify_and_submit_new_profile()

func _on_B_BackToMain_pressed() -> void:
	emit_signal("selected_back_to_main")
