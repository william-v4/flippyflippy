extends CharacterBody3D

# Variable for normal acceleration applied by the player
@export var applied_normal_acceleration_scalar : Dictionary = {"x" = 20, "y" = 600, "z" = 20}
# Variable for added acceleration alongside normal acceleration (for larger jumps, quicker changes in direction, and so on)
@export var applied_added_acceleration_scalar : Dictionary = {"x" = 20, "y" = 10, "z" = 20}

# Variable for acceleration due to friction (calculated only when player is not "applying" any acceleration)
@export var friction_acceleration_scalar : int = 3
# Variable for acceleration due to gravity (on the y axis and calculated when player is not "applying" any acceleration along the y axis
#	(as of writing this the player can only do this through jumping)
@export var gravity_acceleration_scalar : int = 20
# Variable for acceleration added alongside the downwards acceleration from gravity (this is when the player holds the jump action key for longer, leaving the player up in the air for longer)
@export var lower_gravity_scalar : int = 8

# Variable for the maximum velocity for the player
@export var max_velocity_scalar : Dictionary = {"x" = 8, "y" = 100, "z" = 8}
## Variable for the maximum acceleration for the player
#@export var max_acceleration_scalar : Dictionary = {"x" = 40, "y" = 600, "z" = 40}

# Variable for the player's "net" acceleration
var target_acceleration : Dictionary = {"x" = 0, "y" = 0, "z" = 0}

# Variable for the player's target velocity (to be passed to the proper "velocity" variable be used for move_and_slide() to complete the remaining physics processes)
var target_velocity : Dictionary = {"x" = 0, "y" = 0, "z" = 0}

const input_negative_value : Dictionary = {"x" = "move_left", "y" = 0, "z" = "move_forward"}
const input_positive_value : Dictionary = {"x" = "move_right", "y" = 0, "z" = "move_back"}

func _return():
	velocity = Vector3.ZERO

func calculate_ground_velocity(delta : float):
	# Determine the velocity of target_velocity on the x and z axis, respectively.
	for plane in ["x", "z"]:
		if (target_velocity[plane] < 0) and (target_velocity[plane] >= -(max_velocity_scalar[plane])):
			determine_ground_input(plane, 0, applied_added_acceleration_scalar[plane])
		elif target_velocity[plane] == 0:
			determine_ground_input(plane, 0, 0)
		elif (target_velocity[plane] > 0) and (target_velocity[plane] <= max_velocity_scalar[plane]):
			determine_ground_input(plane, -(applied_added_acceleration_scalar[plane]), 0)
	
	# If the player is only applying acceleration on one plane, begin decelerating the other by (applied_normal_acceleration_scalar + applied_added_acceleration_scalar).
	if (abs(target_acceleration["z"]) > 0) and (target_acceleration["x"] == 0):
		decelerate_plane(delta, "x")
	elif (abs(target_acceleration["x"]) > 0) and (target_acceleration["z"] == 0):
		decelerate_plane(delta, "z")
	# If the player is not applying acceleration on either plane, begin applying friction.
	elif pow((pow(target_acceleration["x"], 2) + pow(target_acceleration["z"], 2)), 1/2.0) == 0:
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
	if pow((pow(target_velocity["x"], 2) + pow(target_velocity["z"], 2)), 1/2.0) > max_velocity_scalar["x"]:
		lower_resultant_velocity(target_velocity["x"], target_velocity["z"])

func determine_ground_input(plane : String, added_acceleration_negative : int, added_acceleration_positive : int):
	if Input.is_action_pressed(input_negative_value[plane]) == true:
		target_acceleration[plane] = (-(applied_normal_acceleration_scalar[plane]) + added_acceleration_negative)
	elif Input.is_action_pressed(input_positive_value[plane]) == true:
		target_acceleration[plane] = (applied_normal_acceleration_scalar[plane] + added_acceleration_positive)
	# If neither key for the given plane is being pressed, set target_acceleration to 0 as an indicator to the remaining processes in the frame.
	else:
		target_acceleration[plane] = 0

func lower_resultant_acceleration(current_x_acceleration : int, current_z_acceleration : int, maximum_acceleration : int):
	target_acceleration["x"] = cos(atan2(current_z_acceleration, current_x_acceleration)) * maximum_acceleration
	target_acceleration["z"] = sin(atan2(current_z_acceleration, current_x_acceleration)) * maximum_acceleration

func apply_friction(delta : float):
	# If changing target_velocity by the friction acceleration value will result in a non-zero value, set target_velocity and target_acceleration of that plane to 0.
	if (pow((pow(target_velocity["x"], 2) + pow(target_velocity["z"], 2)), 1/2.0) - (friction_acceleration_scalar * delta)) < 0:
		target_velocity["x"] = 0
		target_velocity["z"] = 0
	else:
		target_velocity["x"] = cos(atan2(target_velocity["z"], target_velocity["x"])) * (pow((pow(target_velocity["x"], 2) + pow(target_velocity["z"], 2)), 1/2.0) - (friction_acceleration_scalar * delta))
		target_velocity["z"] = sin(atan2(target_velocity["z"], target_velocity["x"])) * (pow((pow(target_velocity["x"], 2) + pow(target_velocity["z"], 2)), 1/2.0) - (friction_acceleration_scalar * delta))

func decelerate_plane(delta : float, plane_to_lower : String):
	if (abs(target_velocity[plane_to_lower]) - ((applied_normal_acceleration_scalar[plane_to_lower]) * delta)) < 0:
		target_velocity[plane_to_lower] = 0
	else:
		target_acceleration[plane_to_lower] = (target_velocity[plane_to_lower] / abs(target_velocity[plane_to_lower]) * -1) * (applied_normal_acceleration_scalar[plane_to_lower])

func lower_resultant_velocity(current_x_velocity : float, current_z_velocity : float):
	target_velocity["x"] = cos(atan2(current_z_velocity, current_x_velocity)) * max_velocity_scalar["x"]
	target_velocity["z"] = sin(atan2(current_z_velocity, current_x_velocity)) * max_velocity_scalar["z"]

func calculate_y_velocity(delta : float):
	# If nothing else below this instruction changes the target acceleration along the y axis, the acceleration due to gravity will be the only acceleration along the y axis, bringing the player back to the ground.
	target_acceleration["y"] = -(gravity_acceleration_scalar)

	if is_on_floor() == true:
		target_acceleration["y"] = 0
		target_velocity["y"] = 0
	
	# If the player is on the ground and presses the jump action key, begin a jump.
	if (Input.is_action_pressed("jump") == true) and (is_on_floor() == true):
		target_acceleration["y"] = applied_normal_acceleration_scalar["y"]
	
	# If the player continues to press the "jump" action after starting the jump from the floor, lower the (scalar) acceleration due to gravity to provide the player more time in the air.
	if  (Input.is_action_pressed("jump") == true) and (is_on_floor() == false) and (target_velocity["y"] > 0):
		target_acceleration["y"] = (-(gravity_acceleration_scalar)) + lower_gravity_scalar
	
	if abs((target_acceleration["y"] * delta) + target_velocity["y"]) > max_velocity_scalar["y"]:
		target_velocity["y"] = (abs(target_velocity["y"])/target_velocity["y"]) * max_velocity_scalar["y"]
	else:
		target_velocity["y"] = (target_acceleration["y"] * delta) + target_velocity["y"]

func _physics_process(delta):
	calculate_ground_velocity(delta)
	calculate_y_velocity(delta)
	
	# Apply the target velocity to the velocity variable to be used by move_and_slide().
	velocity.x = target_velocity["x"]
	velocity.y = target_velocity["y"]
	velocity.z = target_velocity["z"]
	
	print(str(pow((pow(target_acceleration["x"], 2) + pow(target_acceleration["z"], 2)), 1/2.0)))
	print(str(target_acceleration))
	print(str(pow((pow(target_velocity["x"], 2) + pow(target_velocity["z"], 2)), 1/2.0)))
	print("")
	print("")
	print("")
	
	move_and_slide()