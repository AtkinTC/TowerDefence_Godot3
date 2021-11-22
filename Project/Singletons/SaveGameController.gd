extends Node

const CLASS_NAME = "ProfileNameInput"

var demo_save_directory: String = "res://Saves/"
var demo_save_filename_pre: String = "save_"
var demo_save_filename_post: String = ".tres"

var current_game_save: GameSave

func reset_game_save():
	current_game_save = null

# create a new game save, set intial values, and trigger save
func create_new_game_save(_profile_name):
	current_game_save = GameSave.new()
	current_game_save.set(GameSave.SAVE_VAR_SAVE_NAME, _profile_name)
	current_game_save.set(GameSave.SAVE_VAR_CREATION_DATE_TIME, OS.get_datetime())
	save_current_game()

# add records of a completed level to the current game save
func add_level_completion_record(_level_id: String, _record: Dictionary):
	if(!current_game_save):
		reset_game_save()
	var level_completetion_records: Dictionary = current_game_save.get(GameSave.SAVE_VAR_LEVEL_COMPLETION_RECORDS)
	level_completetion_records[_level_id] = _record
	current_game_save.set(GameSave.SAVE_VAR_LEVEL_COMPLETION_RECORDS, level_completetion_records)

# retrieve levels completion record from the current game save
func get_level_completion_record(_level_id: String) -> Dictionary:
	if(!current_game_save):
		reset_game_save()
	var level_completetion_records: Dictionary = current_game_save.get(GameSave.SAVE_VAR_LEVEL_COMPLETION_RECORDS)
	return level_completetion_records.get(_level_id, {})

# trigger save to file of the current game save
func save_current_game():
	var METHOD_NAME = "save_current_game"
	var dir = Directory.new()
	if(!dir.dir_exists(demo_save_directory)):
		dir.make_dir_recursive(demo_save_directory)
		
	current_game_save.set(GameSave.SAVE_VAR_SAVE_DATE_TIME, OS.get_datetime())
	var profile_name: String = current_game_save.get(GameSave.SAVE_VAR_SAVE_NAME)
	var file_name: String = demo_save_filename_pre+profile_name+demo_save_filename_post
	ResourceSaver.save(demo_save_directory+file_name, current_game_save)
	print(CLASS_NAME + " : " + METHOD_NAME +  " : save_game complete for file : " + demo_save_directory+file_name)

# load a game save from a file
func load_game(_file_name: String) -> GameSave:
	var METHOD_NAME = "load_game"
	var dir = Directory.new()
	if(!dir.file_exists(demo_save_directory+_file_name)):
		print(CLASS_NAME + " : " + METHOD_NAME + " : no file found for profile name")
		return null
		
	var loaded_save: Resource = load(demo_save_directory+_file_name)
	if(loaded_save is GameSave):
		print(CLASS_NAME + " : " + METHOD_NAME +  " : load complete for file : " + demo_save_directory+_file_name)
		return (loaded_save as GameSave)
	return null

# load a game save as the current save
func load_as_current_game(_profile_name: String):
	var METHOD_NAME = "load_as_current_game"
	var file_name = demo_save_filename_pre + _profile_name + demo_save_filename_post
	var loaded_game = load_game(file_name)
	if(loaded_game is GameSave):
		current_game_save = loaded_game
		return true
	return false

# get array of all found game saves in the save directory
func get_all_save_games() -> Array:
	var METHOD_NAME = "get_all_save_games"
	var dir = Directory.new()
	if(!dir.dir_exists(demo_save_directory)):
		print(CLASS_NAME + " : " + METHOD_NAME + " : save directory doesn't exist")
		return []
	
	var saves = []
	
	#loop through all files in the directory
	if(dir.open(demo_save_directory) == OK):
		dir.list_dir_begin()
		var file_name = null
		while file_name != "":
			file_name = dir.get_next()
			if(dir.current_is_dir()):
				#current is a directory
				continue
			if(file_name.begins_with(demo_save_filename_pre) && file_name.ends_with(demo_save_filename_post)):
				#current is a potential save file
				var loaded_file = load_game(file_name)
				if(loaded_file is GameSave):
					saves.append(loaded_file)
	
	return saves
