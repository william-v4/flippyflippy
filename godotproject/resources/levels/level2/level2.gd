extends Node3D
func _ready():
	$split1/currentmovecube1/AnimationPlayer.play("move")
	$split1/currentmovepad1/AnimationPlayer.play("move")
	$split1/currentrotator1/AnimationPlayer.play("move")
	$split1/parallelmovecube1/AnimationPlayer.play("move")
	$split1/parallelmovepad1/AnimationPlayer.play("move")
	$split2/RigidBody3D/AnimationPlayer.play("move")
	$split3/current3/RigidBody3D/AnimationPlayer.play("move")
	$split3/parallel3/RigidBody3D/AnimationPlayer.play("move")
	
	
