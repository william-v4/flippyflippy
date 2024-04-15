extends Node

var player : Object
var player_camera_marker : Object
var camera : Object
var player_tracker : Object
var main_camera_marker : Object
var main_camera_marker_animation_player : Object
var platform_animation_player : Object
var black_screen_animation_player : Object

var menu_elements : Object
var black_screen : Object
var menu_label : Object

var paused : bool = true
var game_over : bool = false

var current_level_path : String = "Levels/TutorialLevel/"
# current platform of the level (see Platform enum for values)
var current_platform : int

# stops further rotation while the level is rotating
var rotating : bool = false
var transition_status : int
var screen_status : int

enum Platform {MAIN, PARALLEL}
enum Transition {NONE, ZOOM_OUT, ZOOM_IN}
enum Screen {STANDARD, FADE_OUT, FADE_IN}
enum Message {INTRO, PAUSE, RESTART}

const main_base_platform_collision_shape : String = "LevelComponents/MainPlatform/BasePlatform/PlatformCollisionShape"
const main_spikes_collision_shape : String = "LevelComponents/MainPlatform/HarmfulObjects/Spikes/SpikesCollisionShape"

const parallel_base_platform_collision_shape : String = "LevelComponents/ParallelPlatform/BasePlatform/PlatformCollisionShape"
const parallel_spikes_collision_shape : String = "LevelComponents/ParallelPlatform/HarmfulObjects/Spikes/SpikesCollisionShape"

const transition_platform_collision_shape : String = "TransitionPlatform/PlatformCollisionShape"

func _ready():
	get_node_names()
	
	player.set_movement_paused(true)
	player.player_died.connect(_on_player_died)
	
	screen_status = Screen.STANDARD
	transition_status = Transition.NONE
	
	menu_label.set_visible(false)
	
	disable_platform_physics(false, true)
	request_pause_menu(Message.INTRO)

func get_node_names():
	player = get_node("Player")
	player_camera_marker = get_node("Player/PlayerCameraMarker")
	camera = get_node("Player/PlayerCameraMarker/Camera3D")
	player_tracker = get_node("PlayerTracker")
	main_camera_marker = get_node("PlayerTracker/MainCameraMarker")
	main_camera_marker_animation_player = get_node("PlayerTracker/MainCameraMarker/AnimationPlayer")
	platform_animation_player = get_node("Levels/TutorialLevel/AnimationPlayer")
	black_screen_animation_player = get_node("MenuElements/BlackScreen/AnimationPlayer")
	
	menu_elements = get_node("MenuElements")
	black_screen = get_node("MenuElements/BlackScreen")
	menu_label = get_node("MenuElements/MenuLabel")

func fade_out():
	black_screen_animation_player.play("fade_out")
	screen_status = Screen.FADE_OUT

func fade_in():
	black_screen_animation_player.play_backwards("fade_out")
	screen_status = Screen.FADE_IN

func zoom_out():
	main_camera_marker_animation_player.play("move_marker_to_menu")
	transition_status = Transition.ZOOM_OUT

func zoom_in():
	main_camera_marker_animation_player.play_backwards("move_marker_to_menu")
	transition_status = Transition.ZOOM_IN

# tell the level it is moving
func check_rotation_status():
	if (!platform_animation_player.is_playing()): 
		rotating = false
		if (get_node(current_level_path + main_base_platform_collision_shape).is_disabled()):
			disable_platform_physics(false, true)

func check_menu_transition_status():
	# If the first part of the transition to the menu is finished, where the fade_out animation is
	#	finished and is ready to finish the rest of the transition.
	if (transition_status == Transition.ZOOM_OUT and !black_screen_animation_player.is_playing() and screen_status == Screen.FADE_OUT):
		print("step two of pause")
		connect_to_new_parent(player_camera_marker, player, self)
		connect_to_new_parent(camera, player_camera_marker, player_tracker)
		connect_to_new_parent(camera, player_tracker, main_camera_marker)
		
		if (game_over):
			player.reset_position()
			player.reset_rotation()
			player_tracker.set_position(Vector3((player.get_position().x), 1.5, (player.get_position().z)))
		
		zoom_out()
		
		fade_in()
	# If the second part of the transition to the menu is finished, where the fade_in animation is
	#	finished and is ready to reset the screen_status variable.
	elif (transition_status == Transition.ZOOM_OUT and !black_screen_animation_player.is_playing() and screen_status == Screen.FADE_IN):
		print("step three of pause, reset screen var")
		screen_status = Screen.STANDARD
	# If the third part of the transition to the menu is finished, where the zoom_out animation is
	#	finished and is ready to make menu_label visible and reset the transition_status variable.
	elif (transition_status == Transition.ZOOM_OUT and !main_camera_marker_animation_player.is_playing() and screen_status == Screen.STANDARD):
		print("step four of pause, reset transition var, ready to return")
		menu_label.set_visible(true)
		transition_status = Transition.NONE
	
	# If the first part of the transition back to the game is finished, where the camera's zoom_in
	#	animation is finished and is ready to fade_out the screen.
	if (transition_status == Transition.ZOOM_IN and !main_camera_marker_animation_player.is_playing() and screen_status == Screen.STANDARD):
		print("step two of resume")
		fade_out()
	# If the second part of the transition back to the game is finished, where the fade_out animation
	#	is finished and is ready to link back the camera to the player and begin the fade_in animation.
	elif (transition_status == Transition.ZOOM_IN and !black_screen_animation_player.is_playing() and screen_status == Screen.FADE_OUT):
		print("step three of resume")
		connect_to_new_parent(camera, main_camera_marker, player_tracker)
		connect_to_new_parent(camera, player_tracker, player_camera_marker)
		connect_to_new_parent(player_camera_marker, self, player)
		
		fade_in()
	# If the third part of the transition back to the game is finished, where the fade_in animation
	#	is finished and is ready to set paused to false and unlock player movement and reset
	#	screen_status and, finally, transition_status.
	elif (transition_status == Transition.ZOOM_IN and !black_screen_animation_player.is_playing() and screen_status == Screen.FADE_IN):
		print("step four of resume, ready to pause")
		paused = false
		player.set_movement_paused(false)
		
		screen_status = Screen.STANDARD
		transition_status = Transition.NONE

func rotate_if_requested():
	if (Input.is_action_just_pressed("action_key_a") and (current_platform == Platform.MAIN) and !rotating and !player.movement_paused):
		disable_platform_physics(true, false)
		platform_animation_player.play("rotatetoparallel")
		rotating = true
		current_platform = Platform.PARALLEL
	elif (Input.is_action_just_pressed("action_key_a") and (current_platform == Platform.PARALLEL) and !rotating and !player.movement_paused): 
		disable_platform_physics(true, false)
		platform_animation_player.play_backwards("rotatetoparallel")
		rotating = true
		current_platform = Platform.MAIN

# pausing the game and capturing/releasing the cursor
func switch_menu_if_requested():
	if (Input.is_action_just_pressed("return") and !paused and transition_status == Transition.NONE and screen_status == Screen.STANDARD):
		print("pause requested")
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		player.reset_player_movement()
		player.set_movement_paused(true)
		request_pause_menu(Message.PAUSE)
		paused = true
	elif (Input.is_action_just_pressed("return") and paused and transition_status == Transition.NONE and screen_status == Screen.STANDARD):
		print("resume requested")
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		request_resume()

func request_pause_menu(message : int):
	# Get x and z value of player to be used during transition
	player_tracker.set_position(Vector3((player.get_position().x), 1.5, (player.get_position().z)))
	# Set the transition_status variable to Transition.ZOOM_OUT even if the animation itself has not yet started.
	transition_status = Transition.ZOOM_OUT
	
	# If the screen is configured to be the start menu, keep the screen in its initial state (black)
	# and set screen_status to Screen.FADE_OUT, as if the animation was already done.
	match message:
		Message.INTRO:
			screen_status = Screen.FADE_OUT
			menu_label.set_text("Codename flippyflippy\nPress ESC to start")
		Message.PAUSE:
			fade_out()
			menu_label.set_text("Game paused\nPress ESC to resume")
		Message.RESTART:
			fade_out()
			menu_label.set_text("You died\nPress ESC to restart")
	
	print("step one of pause")

func request_resume():
	zoom_in()
	menu_label.set_visible(false)
	print("step one of resume")

func request_death_screen():
	pass

func disable_platform_physics(level_platform_state : bool, transition_platform_state : bool):
	get_node(current_level_path + main_base_platform_collision_shape).set_deferred("disabled", level_platform_state)
	get_node(current_level_path + main_spikes_collision_shape).set_deferred("disabled", level_platform_state)
	
	get_node(current_level_path + parallel_base_platform_collision_shape).set_deferred("disabled", level_platform_state)
	get_node(current_level_path + parallel_spikes_collision_shape).set_deferred("disabled", level_platform_state)
	
	get_node(current_level_path + transition_platform_collision_shape).set_deferred("disabled", transition_platform_state)

func connect_to_new_parent(object_to_reparent : Object, old_parent : Object, new_parent : Object):
	old_parent.remove_child(object_to_reparent)
	new_parent.add_child(object_to_reparent)

func _process(delta):
	rotate_if_requested()
	switch_menu_if_requested()
	
	check_rotation_status()
	check_menu_transition_status()

func _on_player_died():
	print("reset_requested")
	print(screen_status)
	print(transition_status)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player.reset_player_movement()
	player.set_movement_paused(true)
	request_pause_menu(Message.RESTART)
	game_over = true
	paused = true
