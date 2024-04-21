extends CharacterBody3D

signal player_died

# Variable for normal acceleration applied by the player
@export var applied_normal_acceleration_scalar : Dictionary = {"x" = 20, "y" = 200, "z" = 20}
#Variable for added acceleration alongside normal acceleration (for larger jumps, quicker changes in direction, and so on)
@export var applied_added_acceleration_scalar : Dictionary = {"x" = 20, "y" = 10, "z" = 20}

# Variable for acceleration due to friction (calculated only when player is not "applying" any acceleration)
@export var friction_acceleration_scalar : int = 50
# Variable for acceleration due to gravity (on the y axis and calculated when player is not "applying" any acceleration along the y axis (as of writing this the player can only do this through jumping)
@export var gravity_acceleration_scalar : int = 5
# Variable for acceleration added alongside the downwards acceleration from gravity (this is when the player holds the jump action key for longer, leaving the player up in the air for longer)
@export var lower_gravity_scalar : int = 2

# Variables for the maximum velocity for the player
@export var max_velocity_scalar : Dictionary = {"x" = 8, "y" = 100, "z" = 8}

# if the player is looking above 60 degrees
@export var lookingup : bool

# Variable for the player's "net" acceleration
var target_acceleration : Dictionary = {"x" = 0, "y" = 0, "z" = 0}

# Variable for the player's target velocity (to be passed to the proper "velocity" variable be used for move_and_slide() to complete the remaining physics processes)
var target_velocity : Dictionary = {"x" = 0, "y" = 0, "z" = 0}

var camera_marker : Object
var camera : Object
var main : Object

var fall_detector : String = "FallDetector"

const input_negative_value : Dictionary = {"x" = "move_left", "y" = 0, "z" = "move_forward"}
const input_positive_value : Dictionary = {"x" = "move_right", "y" = 0, "z" = "move_back"}

# if the game is paused or not
var movement_paused : bool

# vertical and horizontal mouse sensitivity
var mousesensx : float = 0.2
var mousesensy : float = 0.1

func _ready():
	camera_marker = get_node("PlayerCameraMarker")
	camera = get_node("PlayerCameraMarker/Camera3D")
	main = get_parent()
	
	get_node('PlayerMesh').set_visible(true)
	
	velocity = Vector3.ZERO

func is_movement_paused():
	return movement_paused

func set_movement_paused(input_value : bool):
	movement_paused = input_value

func reset_player_movement():
	target_acceleration = {"x" = 0, "y" = 0, "z" = 0}
	target_velocity = {"x" = 0, "y" = 0, "z" = 0}

func calculate_ground_velocity(delta : float):
	# Determine the velocity of target_velocity on the x and z axis, respectively.
	for plane in ["x", "z"]:
		if ((target_velocity[plane] < 0) and (target_velocity[plane] >= -(max_velocity_scalar[plane]))):
			determine_ground_input(plane, 0, applied_added_acceleration_scalar[plane])
		elif (target_velocity[plane] == 0):
			determine_ground_input(plane, 0, 0)
		elif ((target_velocity[plane] > 0) and (target_velocity[plane] <= max_velocity_scalar[plane])):
			determine_ground_input(plane, -(applied_added_acceleration_scalar[plane]), 0)
	
	# If the player is only applying acceleration on one plane, begin decelerating the other by (applied_normal_acceleration_scalar + applied_added_acceleration_scalar).
	if (abs(target_acceleration["z"]) > 0) and (target_acceleration["x"] == 0):
		decelerate_plane(delta, "x")
	elif (abs(target_acceleration["x"]) > 0) and (target_acceleration["z"] == 0):
		decelerate_plane(delta, "z")
	# If the player is not applying acceleration on either plane, begin applying friction.
	elif (pow((pow(target_acceleration["x"], 2) + pow(target_acceleration["z"], 2)), 1/2.0) == 0):
		apply_friction(delta)
	
	# If the target_acceleration on both planes are accelerating at applied_normal_acceleration_scalar, then lower the resultant target_acceleration
	#	to applied_normal_acceleration_scalar, while maintaining the same direction.
	if pow((pow(target_acceleration["x"], 2) + pow(target_acceleration["z"], 2)), 1/2.0) == pow((pow(applied_normal_acceleration_scalar["x"], 2) + pow(applied_normal_acceleration_scalar["x"], 2)), 1/2.0):
		lower_resultant_acceleration(target_acceleration["x"], target_acceleration["z"], applied_normal_acceleration_scalar["x"])
	
	# If the target_acceleration on one plane is applied_normal_acceleration_scalar, with the other one accelerating at the combined value of
	#	applied_normal_acceleration_scalar and applied_added_acceleration_scalar, lower the resultant target_acceleration to the combined value
	#	of applied_normal_acceleration_scalar and applied_added_acceleration_scalar, while maintaining the same direction.
	if pow((pow(target_acceleration["x"], 2) + pow(target_acceleration["z"], 2)), 1/2.0) >= pow((pow(applied_normal_acceleration_scalar["x"], 2) + pow((applied_normal_acceleration_scalar["x"] + applied_added_acceleration_scalar["x"]), 2)), 1/2.0):
		lower_resultant_acceleration(target_acceleration["x"], target_acceleration["z"], (applied_normal_acceleration_scalar["x"] + applied_added_acceleration_scalar["x"]))
	
	# Change the velocity by the target acceleration. Functions apply_friction() or decelerate_plane() have the ability to change target_velocity() of a given plane directly,
	#	but in both cases, target_acceleration() for that plane is already set to 0, meaning there's no change after running these two commands.
	target_velocity["x"] = (target_acceleration["x"] * delta) + target_velocity["x"]
	target_velocity["z"] = (target_acceleration["z"] * delta) + target_velocity["z"]
	
	# If the resultant velocity is above the maximum velocity scalar defined above, lower the resultant velocity while maintaining the same direction.
	if (pow((pow(target_velocity["x"], 2) + pow(target_velocity["z"], 2)), 1/2.0) > max_velocity_scalar["x"]):
		lower_resultant_velocity(target_velocity["x"], target_velocity["z"])

func determine_ground_input(plane : String, added_acceleration_negative : int, added_acceleration_positive : int):
	if (Input.is_action_pressed(input_negative_value[plane])):
		target_acceleration[plane] = (-(applied_normal_acceleration_scalar[plane]) + added_acceleration_negative)
	elif (Input.is_action_pressed(input_positive_value[plane])):
		target_acceleration[plane] = (applied_normal_acceleration_scalar[plane] + added_acceleration_positive)
	# If neither key for the given plane is being pressed, set target_acceleration to 0 as an indicator to the remaining processes in the frame.
	else:
		target_acceleration[plane] = 0

func lower_resultant_acceleration(current_x_acceleration : int, current_z_acceleration : int, maximum_acceleration : int):
	target_acceleration["x"] = cos(atan2(current_z_acceleration, current_x_acceleration)) * maximum_acceleration
	target_acceleration["z"] = sin(atan2(current_z_acceleration, current_x_acceleration)) * maximum_acceleration

func apply_friction(delta : float):
	# If changing target_velocity by the friction acceleration value will result in a non-zero value, set target_velocity and target_acceleration of that plane to 0.
	if ((pow((pow(target_velocity["x"], 2) + pow(target_velocity["z"], 2)), 1/2.0) - (friction_acceleration_scalar * delta)) < 0):
		target_velocity["x"] = 0
		target_velocity["z"] = 0
	else:
		target_velocity["x"] = cos(atan2(target_velocity["z"], target_velocity["x"])) * (pow((pow(target_velocity["x"], 2) + pow(target_velocity["z"], 2)), 1/2.0) - (friction_acceleration_scalar * delta))
		target_velocity["z"] = sin(atan2(target_velocity["z"], target_velocity["x"])) * (pow((pow(target_velocity["x"], 2) + pow(target_velocity["z"], 2)), 1/2.0) - (friction_acceleration_scalar * delta))

func decelerate_plane(delta : float, plane_to_lower : String):
	if ((abs(target_velocity[plane_to_lower]) - ((applied_normal_acceleration_scalar[plane_to_lower]) * delta)) < 0):
		target_velocity[plane_to_lower] = 0
	else:
		target_acceleration[plane_to_lower] = (target_velocity[plane_to_lower] / abs(target_velocity[plane_to_lower]) * -1) * (applied_normal_acceleration_scalar[plane_to_lower])

func lower_resultant_velocity(current_x_velocity : float, current_z_velocity : float):
	target_velocity["x"] = cos(atan2(current_z_velocity, current_x_velocity)) * max_velocity_scalar["x"]
	target_velocity["z"] = sin(atan2(current_z_velocity, current_x_velocity)) * max_velocity_scalar["z"]

func calculate_y_velocity(delta : float):
	# If nothing else below this instruction changes the target acceleration along the y axis, the acceleration due to gravity will be the only acceleration along the y axis, bringing the player back to the ground.
	target_acceleration["y"] = -(gravity_acceleration_scalar)

	if (is_on_floor()):
		target_acceleration["y"] = 0
		target_velocity["y"] = 0
	
	# If the player is on the ground and presses the jump action key, begin a jump.
	if (Input.is_action_pressed("jump") and is_on_floor() and !get_parent().rotating):
		target_acceleration["y"] = applied_normal_acceleration_scalar["y"]
	
	# If the player continues to press the "jump" action after starting the jump from the floor, lower the (scalar) acceleration due to gravity to provide the player more time in the air.
	if  (Input.is_action_pressed("jump") and is_on_floor() and !get_parent().rotating and (target_velocity["y"] > 0)):
		target_acceleration["y"] = (-(gravity_acceleration_scalar)) + lower_gravity_scalar
	
	if (abs((target_acceleration["y"] * delta) + target_velocity["y"]) > max_velocity_scalar["y"]):
		target_velocity["y"] = (abs(target_velocity["y"])/target_velocity["y"]) * max_velocity_scalar["y"]
	else:
		target_velocity["y"] = (target_acceleration["y"] * delta) + target_velocity["y"]

func check_looking_up():
	if (camera_marker.rotation_degrees.x >= 60):
		lookingup = true

func reset_position():
	position = Vector3(0, 1, 0)

func reset_rotation():
	rotation = Vector3(0, 0, 0)
	camera_marker.set_rotation(Vector3(0, 0, 0))

# runs whenever input is received
func _input(event):
	# camera movement with mouse
	if ((event is InputEventMouseMotion) and !movement_paused):
		# rotate the player left and right
		rotate_y(-deg_to_rad(event.relative.x) * mousesensx)
		# rotate camera up and down
		camera_marker.rotate_x(-deg_to_rad(event.relative.y) * mousesensy)
		# make sure player doesn't break their neck (rotating over 90 degrees)
		camera_marker.rotation_degrees.x = clamp(camera_marker.rotation_degrees.x, -90, 90)
	if Input.is_action_just_pressed("action_key_a"):
		position.y += 2

# runs continuously
func _physics_process(delta):	
	if (!movement_paused):
		calculate_ground_velocity(delta)
		calculate_y_velocity(delta)
		
		# Apply the target velocity to the velocity variable to be used by move_and_slide(),
		#	taking into account the player's rotation.
		velocity.x = (cos(rotation.y) * target_velocity["x"]) + (sin(rotation.y) * target_velocity["z"])
		velocity.y = target_velocity["y"]
		velocity.z = (cos(rotation.y) * target_velocity["z"]) + (-(sin(rotation.y) * target_velocity["x"]))
		
		move_and_slide()
		#print(str(get_slide_collision_count()))
		check_looking_up()

func _on_object_detector_area_entered(area):
	var nodenameunwantedchars = [".","/"]
	var levelstring
	print(area)
	if (area.name == fall_detector):
		player_died.emit()
	if "start" in area.name:
		global_transform.origin = get_tree().get_root().get_node("Main").get_node("Levels").get_node(str(area.get_parent().previouslevel).replace("../", "")).get_node("end").global_position
	if "end" in area.name:
		global_transform.origin = get_tree().get_root().get_node("Main").get_node("Levels").get_node(str(area.get_parent().nextlevel).replace("../", "")).get_node("start").global_position


func _on_object_detector_body_entered(body):
	if "jumppad" in body.name:
		target_velocity["y"] += 15
