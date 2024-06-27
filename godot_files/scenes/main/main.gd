extends Node

var rotating = false

var base_platform : Object
var parallel_platforms: Object
var player : Object

func _ready():
	set_game_paused(true)
	
	determine_object_variables()

func _physics_process(delta):
	if (Input.is_action_just_pressed("action_key_pause") and is_game_paused()):
		set_game_paused(false)
	elif (Input.is_action_just_pressed("action_key_pause") and !is_game_paused()):
		set_game_paused(true)
	
	move_platforms()

func determine_object_variables() -> void:
	base_platform = get_node("Levels/TestPlatform/MainPlatform/BasePlatform")
	parallel_platforms = get_node("Levels/TestPlatform/ParallelPlatform")
	
	player = get_node("Player")

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

func move_platforms() -> void:
	var amount_to_change : float = clampf(player.get_relative_z_distance(), -45.0, 5.0)
	
	#base_platform.set_position(Vector3((base_platform.get_position().x), (base_platform.get_position().y), (amount_to_change)))
	parallel_platforms.set_position(Vector3((parallel_platforms.get_position().x), (parallel_platforms.get_position().y), (amount_to_change * 2.0)))
