extends Node

var rotating = false

func _ready():
	set_game_paused(true)

func _physics_process(delta):
	if (Input.is_action_just_pressed("action_key_pause") and is_game_paused()):
		set_game_paused(false)
	elif (Input.is_action_just_pressed("action_key_pause") and !is_game_paused()):
		set_game_paused(true)

func is_game_paused() -> bool:
	if (Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and get_node("Player").is_movement_paused()):
		return true
	elif (Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and !(get_node("Player").is_movement_paused())):
		return false
	else:
		return false

func set_game_paused(pause_requested : bool) -> void:
	if (pause_requested):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_node("Player").set_movement_paused(true)
	elif (!pause_requested):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_node("Player").set_movement_paused(false)
