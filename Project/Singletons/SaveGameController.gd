extends Node

var demo_save_directory: String = "res://Saves/"
var demo_save_filename: String = "save_001.tres"

var current_game_save: GameSave

func reset_game_save():
	current_game_save = GameSave.new()

func add_level_completion_record(_level_id: String, _record: Dictionary):
	if(!current_game_save):
		reset_game_save()
	var level_completetion_records: Dictionary = current_game_save.get(GameSave.SAVE_VAR_LEVEL_COMPLETION_RECORDS)
	level_completetion_records[_level_id] = _record
	current_game_save.set(GameSave.SAVE_VAR_LEVEL_COMPLETION_RECORDS, level_completetion_records)
	
func get_level_completion_record(_level_id: String) -> Dictionary:
	if(!current_game_save):
		reset_game_save()
	var level_completetion_records: Dictionary = current_game_save.get(GameSave.SAVE_VAR_LEVEL_COMPLETION_RECORDS)
	return level_completetion_records.get(_level_id, {})

func save_game():
	var dir = Directory.new()
	if(!dir.dir_exists(demo_save_directory)):
		dir.make_dir_recursive(demo_save_directory)
	ResourceSaver.save(demo_save_directory+demo_save_filename, current_game_save)
	print("save_game complete for file : " + demo_save_directory+demo_save_filename)

func load_game():
	var dir = Directory.new()
	if(!dir.file_exists(demo_save_directory+demo_save_filename)):
		return false
	var loaded_save: Resource = load(demo_save_directory+demo_save_filename)
	if(loaded_save is GameSave):
		current_game_save = loaded_save
		print("load_game complete for file : " + demo_save_directory+demo_save_filename)
