extends Control
class_name PostLevelMenu

signal selected_restart_level()
signal selected_back()
signal selected_quit()

onready var background_sprite: Sprite = get_node_or_null("BackgroundSprite")
var background_image: Image

func _ready() -> void:
	if(background_sprite != null && background_image != null):
		set_background_image(background_image)
	
func set_background_image(_background_image: Image):
	background_image = _background_image
	if(background_sprite != null):
		var new_texture = ImageTexture.new()
		new_texture.create_from_image(_background_image)
		background_sprite.set_texture(new_texture)

func _on_B_Retry_pressed() -> void:
	emit_signal("selected_restart_level")

func _on_B_Back_pressed() -> void:
	emit_signal("selected_back")

func _on_B_Quit_pressed() -> void:
	emit_signal("selected_quit")
