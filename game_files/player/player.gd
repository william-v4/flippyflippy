extends CharacterBody3D

#Variable for normal acceleration applied by the player
@export var applied_normal_acceleration_scalar : Dictionary = {"x" = 20, "y" = 30, "z" = 20}
#Variable for added acceleration alongside normal acceleration (for larger jumps, quicker changes in direction, and so on)
@export var applied_added_acceleration_scalar : Dictionary = {"x" = 20, "y" = 10, "z" = 20}

# Variable for acceleration due to friction (calculated only when player is not "applying" any acceleration)
@export var friction_acceleration_scalar : int = 25
# Variable for acceleration due to gravity (on the y axis and calculated when player is not "applying" any acceleration along the y axis (as of writing this the player can only do this through jumping)
@export var gravity_acceleration_scalar : int = 1

# Variables for the maximum velocity for the player
@export var max_velocity_scalar : Dictionary = {"x" = 8, "y" = 20, "z" = 8}

# Variable for the player's "net" acceleration
var target_acceleration : Dictionary = {"x" = 0, "y" = 0, "z" = 0}

# Variable for the player's target velocity (to be passed to the proper "velocity" variable be used for move_and_slide() to complete the remaining physics processes)
var target_velocity : Dictionary = {"x" = 0, "y" = 0, "z" = 0}

const input_negative_value : Dictionary = {"x" = "move_left", "y" = 0, "z" = "move_forward"}
const input_positive_value : Dictionary = {"x" = "move_right", "y" = 0, "z" = "move_back"}

func _init():
	velocity = Vector3.ZERO

func calculate_ground_velocity(delta : float):
	for plane in ["x", "z"]:
		if (target_velocity[plane] < 0) and (target_velocity[plane] >= -(max_velocity_scalar[plane])):
			print("velocity " + plane + " is less than 0 and more than or equal to negative max")
			target_acceleration[plane] = determine_ground_input(delta, plane, input_negative_value[plane], input_positive_value[plane], 0, applied_added_acceleration_scalar[plane])
		elif target_velocity[plane] == 0:
			print("velocity " + plane + " is 0")
			target_acceleration[plane] = determine_ground_input(delta, plane, input_negative_value[plane], input_positive_value[plane], 0, 0)
		elif (target_velocity[plane] > 0) and (target_velocity[plane] <= max_velocity_scalar[plane]):
			print("velocity " + plane + " is more than 0 and less than or equal to positive max")
			target_acceleration[plane] = (determine_ground_input(delta, plane, input_negative_value[plane], input_positive_value[plane], -(applied_added_acceleration_scalar[plane]), 0))
	
	print("target acceleration is " + str(target_acceleration))
	
	if pow((pow(target_acceleration["x"], 2) + pow(target_acceleration["z"], 2)), 1/2.0) == 0:
		calculate_friction(delta)
	else:
		target_velocity["x"] = (target_acceleration["x"] * delta) + target_velocity["x"]
		target_velocity["z"] = (target_acceleration["z"] * delta) + target_velocity["z"]
		
		print("resultant target velocity is " + str(pow(pow(target_velocity["x"], 2) + pow(target_velocity["z"], 2), (1/2.0))))
		
		if pow((pow(target_velocity["x"], 2) + pow(target_velocity["z"], 2)), 1/2.0) > max_velocity_scalar["x"]:
			lower_resultant_velocity()

func determine_ground_input(delta : float, plane : String, negative_input : String, positive_input : String, added_acceleration_negative : int, added_acceleration_positive : int):
	var acceleration_to_determine : float
	
	acceleration_to_determine = 0
	
	print(plane + " applied acceleration:")
	if Input.is_action_pressed(negative_input) == true:
		acceleration_to_determine = (-(applied_normal_acceleration_scalar[plane]) + added_acceleration_negative)
	elif Input.is_action_pressed(positive_input) == true:
		acceleration_to_determine = (applied_normal_acceleration_scalar[plane] + added_acceleration_positive)
	elif (abs(target_velocity[plane]) - ((applied_normal_acceleration_scalar[plane] + applied_added_acceleration_scalar[plane]) * delta)) < 0:
		acceleration_to_determine = -(target_velocity[plane]) / delta
	else:
		acceleration_to_determine = (target_velocity[plane] / abs(target_velocity[plane]) * -1) * (applied_normal_acceleration_scalar[plane] + applied_added_acceleration_scalar[plane])
	
	print("acceleration from input:" + str(acceleration_to_determine))
	
	return acceleration_to_determine

func calculate_friction(delta : float):
	print("calculating friction")
	if (pow((pow(target_velocity["x"], 2) + pow(target_velocity["z"], 2)), 1/2.0) - (friction_acceleration_scalar * delta)) < 0:
		target_velocity["x"] = 0
		target_velocity["z"] = 0
	else:
		print("atan: " + str(rad_to_deg(atan2(target_velocity["z"], target_velocity["x"]))))
		target_velocity["x"] = cos(atan2(target_velocity["z"], target_velocity["x"])) * (pow((pow(target_velocity["x"], 2) + pow(target_velocity["z"], 2)), 1/2.0) - (friction_acceleration_scalar * delta))
		target_velocity["z"] = sin(atan2(target_velocity["z"], target_velocity["x"])) * (pow((pow(target_velocity["x"], 2) + pow(target_velocity["z"], 2)), 1/2.0) - (friction_acceleration_scalar * delta))

func lower_resultant_velocity():
	print("fixing diagonal velocity")
	target_velocity["x"] = cos(atan2(target_velocity["z"], target_velocity["x"])) * max_velocity_scalar["x"]
	target_velocity["z"] = sin(atan2(target_velocity["z"], target_velocity["x"])) * max_velocity_scalar["x"]

func calculate_y_velocity(delta : float):
	if (Input.is_action_pressed("jump")) and is_on_floor():
		target_acceleration["y"] = applied_normal_acceleration_scalar["y"]
	else:
		target_acceleration["y"] = -(gravity_acceleration_scalar)
		if is_on_floor():
			# This represents the normal force
			target_acceleration["y"] = 0
			target_velocity["y"] = 0
		elif abs(target_velocity["y"]) > max_velocity_scalar["y"]:
			target_velocity["y"] = max_velocity_scalar["y"] * (abs(target_velocity["y"]) / target_velocity["y"])
	
	target_velocity["y"] += target_acceleration["y"]

func _physics_process(delta):
	print(str(is_on_floor()))
	calculate_ground_velocity(delta)
	calculate_y_velocity(delta)
	
	velocity.x = target_velocity["x"]
	velocity.y = target_velocity["y"]
	velocity.z = target_velocity["z"]
	
	print("final velocity is " + str(velocity))
	
	move_and_slide()
	print("")
