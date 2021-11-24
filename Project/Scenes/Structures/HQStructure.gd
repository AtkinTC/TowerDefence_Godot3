extends DestructableStructure
class_name HQStructure

func get_class() -> String:
	return "DestructableStructure"
	
func _ready() -> void:
	self.add_to_group(faction+"_hq", true)
	self.add_to_group("hq", true)
