extends CharacterBody3D

# Signal to indicate to other platforms to switch places
signal flip_platforms

# Variable for normal acceleration applied by the player
@export var applied_normal_acceleration_scalar : Dictionary = {"x" = 20, "y" = 600, "z" = 20}
#Variable for added acceleration alongside normal acceleration (for larger jumps, quicker changes in direction, and so on)
@export var applied_added_acceleration_scalar : Dictionary = {"x" = 20, "y" = 10, "z" = 20}

# Variable for acceleration due to friction (calculated only when player is not "applying" any acceleration)
@export var friction_acceleration_scalar : int = 50
# Variable for acceleration due to gravity (on the y axis and calculated when player is not "applying" any acceleration along the y axis (as of writing this the player can only do this through jumping)
@export var gravity_acceleration_scalar : int = 5

# Variables for the maximum velocity for the player
@export var max_velocity_scalar : Dictionary = {"x" = 8, "y" = 100, "z" = 8}

# if the player is looking above 60 degrees
@export var lookingup : bool

# Variable for the player's "net" acceleration
var target_acceleration : Dictionary = {"x" = 0, "y" = 0, "z" = 0}

# Variable for the player's target velocity (to be passed to the proper "velocity" variable be used for move_and_slide() to complete the remaining physics processes)
var target_velocity : Dictionary = {"x" = 0, "y" = 0, "z" = 0}

const input_negative_value : Dictionary = {"x" = "move_left", "y" = 0, "z" = "move_forward"}
const input_positive_value : Dictionary = {"x" = "move_right", "y" = 0, "z" = "move_back"}
# if the game is paused or not
@export var paused : bool
# vertical and horizontal mouse sensitivity
var mousesensx : float = 0.2
var mousesensy : float = 0.1

func _ready():
	velocity = Vector3.ZERO
	# capture the mouse cursor
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func calculate_ground_velocity(delta : float):
	# For each plane, determine which keys are being pressed, determining the applied acceleration from the player.
	for plane in ["x", "z"]:
		#if int(target_velocity[plane]) == 0 and int(target_acceleration[plane]) == 0:
			#print("snapping " + str(plane) + " to 0")
			#target_velocity[plane] == 0.0000000000000000000000000000000000000000000000000000000000000000000
			#target_acceleration[plane] == 0.000000000000000000000000000000000000000000000
		
		if (target_velocity[plane] < 0.0) and (target_velocity[plane] >= -(max_velocity_scalar[plane])):
			print(str(plane) + " velocity is less than 0 but more than or equal to negative_max")
			determine_ground_input(delta, plane, input_negative_value[plane], input_positive_value[plane], 0, applied_added_acceleration_scalar[plane])
		elif target_velocity[plane] == 0.0:
			print(str(plane) + " velocity is 0")
			determine_ground_input(delta, plane, input_negative_value[plane], input_positive_value[plane], 0, 0)
		elif (target_velocity[plane] > 0.0) and (target_velocity[plane] <= max_velocity_scalar[plane]):
			print(str(plane) + " velocity is more than 0 but less than or equal to positive_max")
			determine_ground_input(delta, plane, input_negative_value[plane], input_positive_value[plane], -(applied_added_acceleration_scalar[plane]), 0)
	
	print(str(target_velocity))
	print(str(target_acceleration))
	
	# If the player is not applying acceleration, begin applying friction.
	if pow((pow(target_acceleration["x"], 2) + pow(target_acceleration["z"], 2)), 1/2.0) == 0:
		calculate_friction(delta)
	else:
		# Change the velocity by the target acceleration.
		target_velocity["x"] = (target_acceleration["x"] * delta) + target_velocity["x"]
		target_velocity["z"] = (target_acceleration["z"] * delta) + target_velocity["z"]
		
		# If the resultant velocity is above the maximum velocity scalar defined above, lower the resultant velocity while maintaining the same direction.
		if pow((pow(target_velocity["x"], 2) + pow(target_velocity["z"], 2)), 1/2.0) > max_velocity_scalar["x"]:
			lower_resultant_velocity(target_velocity["x"], target_velocity["z"])
		
		if pow((pow(target_acceleration["x"], 2) + pow(target_acceleration["z"], 2)), 1/2.0) > applied_normal_acceleration_scalar["x"]:
			lower_resultant_acceleration(target_velocity["x"], target_velocity["z"])

func determine_ground_input(delta : float, plane : String, negative_input : String, positive_input : String, added_acceleration_negative : int, added_acceleration_positive : int):
	if Input.is_action_pressed(negative_input) == true:
		target_acceleration[plane] = (-(applied_normal_acceleration_scalar[plane]) + added_acceleration_negative)
	elif Input.is_action_pressed(positive_input) == true:
		target_acceleration[plane] = (applied_normal_acceleration_scalar[plane] + added_acceleration_positive)
	#If neither key for the given plane is being pressed, then begin decelerating in that plane.
	elif abs(target_velocity[plane]) > 0 and (abs(target_velocity[plane]) - ((applied_normal_acceleration_scalar[plane] + applied_added_acceleration_scalar[plane]) * delta)) < 0:
		target_velocity[plane] = 0
		target_acceleration[plane] = 0
		print("snapped accel this, acceleration is now " + str(plane) + str(target_acceleration))
	elif abs(target_velocity[plane]) > 0:
		target_acceleration[plane] = (target_velocity[plane] / abs(target_velocity[plane]) * -1) * (applied_normal_acceleration_scalar[plane] + applied_added_acceleration_scalar[plane])
		print("standard deccel this, acceleration is now " + str(plane) + str(target_acceleration))
	else:
		target_acceleration[plane] = 0
		print("else function, accel is " + str(target_acceleration))

func calculate_friction(delta : float):
	if (pow((pow(target_velocity["x"], 2) + pow(target_velocity["z"], 2)), 1/2.0) - (friction_acceleration_scalar * delta)) < 0:
		target_velocity["x"] = 0
		target_velocity["z"] = 0
	else:
		target_velocity["x"] = cos(atan2(target_velocity["z"], target_velocity["x"])) * (pow((pow(target_velocity["x"], 2) + pow(target_velocity["z"], 2)), 1/2.0) - (friction_acceleration_scalar * delta))
		target_velocity["z"] = sin(atan2(target_velocity["z"], target_velocity["x"])) * (pow((pow(target_velocity["x"], 2) + pow(target_velocity["z"], 2)), 1/2.0) - (friction_acceleration_scalar * delta))

func lower_resultant_velocity(current_x_velocity : float, current_z_velocity : float):
	target_velocity["x"] = cos(atan2(current_z_velocity, current_x_velocity)) * max_velocity_scalar["x"]
	target_velocity["z"] = sin(atan2(current_z_velocity, current_x_velocity)) * max_velocity_scalar["z"]

func lower_resultant_acceleration(current_x_acceleration : float, current_z_acceleration : float):
	target_acceleration["x"] = cos(atan2(current_z_acceleration, current_x_acceleration)) * applied_normal_acceleration_scalar["x"]
	target_acceleration["z"] = sin(atan2(current_z_acceleration, current_x_acceleration)) * applied_normal_acceleration_scalar["x"]

func calculate_y_velocity(delta : float):
	# If nothing else below this instruction changes the target acceleration along the y axis, the acceleration due to gravity will bring the player back to the ground.
	target_acceleration["y"] = -(gravity_acceleration_scalar)
	
	if is_on_floor() == true:
		target_acceleration["y"] = 0
		target_velocity["y"] = 0
	
	if (Input.is_action_pressed("jump") == true) and (is_on_floor() == true):
		target_acceleration["y"] = applied_normal_acceleration_scalar["y"]
	
	# If the player continues to press the "jump" action after starting the jump from the floor, lower the (scalar) acceleration due to gravity to provide the player more time in the air.
	if  (Input.is_action_pressed("jump") == true) and (is_on_floor() == false) and (target_velocity["y"] > 0):
		target_acceleration["y"] = (-(gravity_acceleration_scalar)) + 15
	
	if abs((target_acceleration["y"] * delta) + target_velocity["y"]) > max_velocity_scalar["y"]:
		target_velocity["y"] = (abs(target_velocity["y"])/target_velocity["y"]) * max_velocity_scalar["y"]
	else:
		target_velocity["y"] = (target_acceleration["y"] * delta) + target_velocity["y"]

func checklookingup():
	if $Pivot/Marker3D.rotation_degrees.x >= 60:
		lookingup = true

# pausing the game and capturing/releasing the cursor
func pauser():
	if !paused and Input.is_action_just_pressed("pause"):
		paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if paused and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		paused = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# runs whenever input is received
func _input(event):
	# camera movement with mouse
	if event is InputEventMouseMotion and !paused:
		# rotate the player left and right
		rotate_y(-deg_to_rad(event.relative.x) * mousesensx)
		# rotate camera up and down
		$Pivot/Marker3D.rotate_x(-deg_to_rad(event.relative.y) * mousesensy)
		# make sure player doesn't break their neck (rotating over 90 degrees)
		$Pivot/Marker3D.rotation_degrees.x = clamp($Pivot/Marker3D.rotation_degrees.x, -90, 90)
	pauser()

# runs continuously
func _physics_process(delta):
	print("")
	print("")
	print("start of new frame")
	print("target accel at start of frame is " + str(target_acceleration))
	
	calculate_ground_velocity(delta)
	calculate_y_velocity(delta)
	
	# Apply the target velocity to the velocity variable to be used by move_and_slide().
	velocity.x = target_velocity["x"]
	velocity.y = target_velocity["y"]
	velocity.z = target_velocity["z"]
	
	if Input.is_action_just_pressed("action_key_a"):
		flip_platforms.emit()
	
	#print(str((-(target_velocity["x"]) / delta) * delta))
	#print(str(target_velocity))
	# stop movement when paused
	if !paused:
		move_and_slide()
		checklookingup()
