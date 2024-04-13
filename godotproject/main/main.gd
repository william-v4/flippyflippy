extends Node
# current platform of the level (see Platform enum for values)
var current_platform : int

var current_level_path : String

# stops further rotation while the level is rotating
var rotating : bool = false

enum Platform {MAIN, PARALLEL}

const main_base_platform_collision_shape : String = "LevelComponents/MainPlatform/BasePlatform/PlatformCollisionShape"
const main_spikes_collision_shape : String = "LevelComponents/MainPlatform/HarmfulObjects/Spikes/SpikesCollisionShape"

const parallel_base_platform_collision_shape : String = "LevelComponents/ParallelPlatform/BasePlatform/PlatformCollisionShape"
const parallel_spikes_collision_shape : String = "LevelComponents/ParallelPlatform/HarmfulObjects/Spikes/SpikesCollisionShape"

const transition_platform_collision_shape : String = "TransitionPlatform/PlatformCollisionShape"

func _ready():
	current_level_path = "Levels/TutorialLevel/"
	
	get_node(current_level_path + main_base_platform_collision_shape).set_deferred("disabled", false)
	get_node(current_level_path + main_spikes_collision_shape).set_deferred("disabled", false)
	
	get_node(current_level_path + parallel_base_platform_collision_shape).set_deferred("disabled", false)
	get_node(current_level_path + parallel_spikes_collision_shape).set_deferred("disabled", false)
	
	get_node(current_level_path + transition_platform_collision_shape).set_deferred("disabled", true)

func disable_platform_physics(level_platform_state : bool, transition_platform_state : bool):
	get_node(current_level_path + main_base_platform_collision_shape).set_deferred("disabled", level_platform_state)
	get_node(current_level_path + main_spikes_collision_shape).set_deferred("disabled", level_platform_state)
	
	get_node(current_level_path + parallel_base_platform_collision_shape).set_deferred("disabled", level_platform_state)
	get_node(current_level_path + parallel_spikes_collision_shape).set_deferred("disabled", level_platform_state)
	
	get_node(current_level_path + transition_platform_collision_shape).set_deferred("disabled", transition_platform_state)

func _process(delta):
	# tell the level it is moving
	if (get_node("Levels/TutorialLevel/AnimationPlayer").is_playing()):
		rotating = true
	else: 
		rotating = false
		if (get_node(current_level_path + main_base_platform_collision_shape).is_disabled()):
			disable_platform_physics(false, true)

func _unhandled_input(event):
	if (Input.is_action_just_pressed("action_key_a") and (current_platform == Platform.MAIN) and !rotating and !get_node("Player").paused):
		disable_platform_physics(true, false)
		
		get_node("Levels/TutorialLevel/AnimationPlayer").play("rotatetoparallel")
		current_platform = Platform.PARALLEL
	elif (Input.is_action_just_pressed("action_key_a") and (current_platform == Platform.PARALLEL) and !rotating and !get_node("Player").paused): 
		disable_platform_physics(true, false)
		
		get_node("Levels/TutorialLevel/AnimationPlayer").play_backwards("rotatetoparallel")
		current_platform = Platform.MAIN
