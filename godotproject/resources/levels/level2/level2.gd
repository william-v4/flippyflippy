extends Node3D
@export var previouslevel : NodePath
@export var nextlevel : NodePath

func _ready():
	$split1/currentmovecube1/AnimationPlayer.play("move")
	$split1/currentmovepad1/AnimationPlayer.play("move")
	$split1/currentrotator1/AnimationPlayer.play("move")
	$split1/parallelmovecube1/AnimationPlayer.play("move")
	$split1/parallelmovepad1/AnimationPlayer.play("move")
	$split2/RigidBody3D/AnimationPlayer.play("move")
	$split3/current3/RigidBody3D/AnimationPlayer.play("move")
	$split3/parallel3/RigidBody3D/AnimationPlayer.play("move")
	
func _process(delta):
	$frontview/frontviewcamera.global_position = global_position + Vector3(1, -8, 0)
	$backview/backviewcamera.global_position = global_position + Vector3(32, -8, 40)
