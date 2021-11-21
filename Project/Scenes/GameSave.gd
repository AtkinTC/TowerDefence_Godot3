extends Resource
class_name GameSave

const SAVE_VAR_SAVE_NAME = "save_name"
const SAVE_VAR_CREATION_DATE_TIME = "creation_date_time"
const SAVE_VAR_SAVE_DATE_TIME = "save_date_time"
const SAVE_VAR_LEVEL_COMPLETION_RECORDS = "level_completion_records"

export(String) var save_name: String

export(Dictionary) var creation_date_time: Dictionary
export(Dictionary) var save_date_time : Dictionary

# dictionary of LevelCompletionRecord
export(Dictionary) var level_completion_records: Dictionary

