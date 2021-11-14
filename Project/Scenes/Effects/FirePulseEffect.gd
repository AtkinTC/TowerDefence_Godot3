extends Effect

onready var particles: Particles2D = get_node("Particles2D")

var duration_timer: Timer
var source: Node2D
var radius: float
var max_duration: float
var particles_running: bool

onready var tween: Tween = $Tween

func setup_from_attribute_dictionary(_attribute_dict: Dictionary):	
	.setup_from_attribute_dictionary(_attribute_dict)
	source = _attribute_dict.get("source")
	radius = _attribute_dict.get("radius", 0)
	max_duration = _attribute_dict.get("duration", -1)

func _ready() -> void:
	var texture_width: float = particles.get_texture().get_size().x
	var scale: float = radius * 1.5 / (texture_width / 2.0)
	
	particles.get_process_material().scale = scale
	particles.one_shot = true
	particles.emitting = true
	particles_running = true
	
	if(max_duration >= 0):
		duration_timer = Timer.new()
		duration_timer.set_one_shot(true)
		duration_timer.connect("timeout", self, "_on_duration_timeout")
		add_child(duration_timer)
		duration_timer.start(max_duration)
		

func _process(delta) -> void:
	update()
	
#func _physics_process(delta) -> void:
	#current_radius += 1	

func _on_duration_timeout() -> void:
	if(particles_running):
		#stop the emitter and then delay before deleting the effect
		#to give particles time to fade naturallt
		particles_running = false
		particles.emitting = false
		duration_timer.start(1)
	else:
		self.visible = false
		self.queue_free()
