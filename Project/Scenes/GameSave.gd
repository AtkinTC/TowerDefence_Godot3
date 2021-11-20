extends Resource
class_name GameSave

const SAVE_VAR_SAVE_NAME = "save_name"
const SAVE_VAR_LEVEL_COMPLETION_RECORDS = "level_completion_records"

export(String) var save_name

# dictionary of LevelCompletionRecord
export(Dictionary) var level_completion_records

