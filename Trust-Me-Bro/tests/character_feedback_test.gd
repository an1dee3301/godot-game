extends SceneTree
## Godot --headless --path . --script res://tests/character_feedback_test.gd
var checks: int = 0
var failures: int = 0
var events: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("CHARACTER FEEDBACK: " + message)

func frames(count: int) -> void:
	for i: int in count:
		await physics_frame
	await process_frame

func record_event(_actor: Node, event: String, _intensity: float) -> void:
	events[event] = int(events.get(event, 0)) + 1

func _run() -> void:
	var stage: Node3D = Node3D.new()
	root.add_child(stage)
	var floor: StaticBody3D = StaticBody3D.new()
	floor.collision_layer = 1
	var collision: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(24.0, 0.3, 24.0)
	collision.shape = box
	floor.add_child(collision)
	floor.position.y = -0.15
	stage.add_child(floor)
	var actor: RigidBody3D = load("res://scripts/contestant.gd").new()
	actor.setup(0, "POSE TEST", Color("f87471"), 0)
	actor.position.y = 1.0
	stage.add_child(actor)
	actor.controls_enabled = true
	actor.feedback_requested.connect(record_event)
	await frames(35)
	check(actor._eyes.size() == 2, "Both Blender eyes retain independent blink pivots")
	check(actor._ground.is_colliding(), "The test contestant settles on the physical floor")
	actor.request_jump()
	await frames(5)
	check(actor.linear_velocity.y > 1.5, "Visual anticipation preserves immediate jump response")
	check(int(events.get("jump", 0)) == 1, "A physical jump emits one feedback cue")
	check(actor._visual.scale.y > 1.01, "Airborne pose stretches the puppet")
	await frames(100)
	check(int(events.get("land", 0)) == 1, "A physical landing emits one feedback cue")
	check(absf(actor._visual.scale.y - 1.0) < 0.025, "The landing pose settles back to its rest scale")
	check(actor.scale == Vector3.ONE and (actor.get_child(0) as CollisionShape3D).scale == Vector3.ONE, "Puppet animation never scales the rigid body or collider")
	actor.perform_shove()
	await frames(2)
	check(actor._right_arm.rotation.x > 0.0, "The shove briefly loads the arms back")
	await frames(6)
	check(actor._right_arm.rotation.x < -0.8, "The shove visibly extends both hands")
	actor.apply_knockback(Vector3(6.0, 1.0, 0.0))
	await frames(3)
	check(actor._hit_left > 0.0 and int(events.get("hit", 0)) == 1, "Knockback triggers a brief, single hit reaction")
	check(actor.linear_velocity.x > 1.0, "Hit animation preserves physical knockback")
	actor.celebrate(0.5)
	await frames(8)
	check(actor._left_arm.rotation.z < -1.5 and actor._right_arm.rotation.z > 1.5, "Celebration reads with both hands raised")
	actor.freeze = true
	actor.set_showcase(true)
	await frames(15)
	check(actor._visual.scale.x > 1.08, "Menu showcase enlarges only the visual puppet")
	actor.set_showcase(false)
	await frames(45)
	check(absf(actor._visual.scale.x - 1.0) < 0.025, "Leaving showcase restores ordinary gameplay proportions")
	check(actor._name_label.text == "P1 ▼", "A local contestant has a concise identification marker")
	# Results can last indefinitely; an immediate replay must clear that pose.
	actor.celebrate(30.0)
	await frames(8)
	check(actor._right_arm.rotation.z > 1.5, "The results winner is visibly celebrating before replay")
	actor.respawn(Vector3(0.0, 0.92, 0.0), false)
	await frames(14)
	check(actor._celebrate_left == 0.0 and absf(actor._left_arm.rotation.z) < 0.4 and absf(actor._right_arm.rotation.z) < 0.4, "An immediate replay clears results celebration and restores gameplay arm poses")
	var replica: RigidBody3D = load("res://scripts/contestant.gd").new()
	replica.setup(1, "REPLICA", Color("79c9ef"))
	stage.add_child(replica)
	replica.configure_network(2, 2, true)
	replica.feedback_requested.connect(record_event)
	replica.apply_network_snapshot({"position":Vector3(4.0, 0.92, 0.0), "owner":2, "is_bot":false})
	await frames(16)
	var shoves_before: int = int(events.get("shove", 0))
	replica.apply_network_snapshot({"position":Vector3(4.0, 0.92, 0.0), "owner":2, "is_bot":false, "shove_left":0.24})
	replica.apply_network_snapshot({"position":Vector3(4.0, 0.92, 0.0), "owner":2, "is_bot":false, "shove_left":0.24})
	check(int(events.get("shove", 0)) == shoves_before + 1, "Repeated network snapshots do not duplicate shove feedback")
	check(replica.freeze and replica.collision_layer == 0 and replica.collision_mask == 0, "Replica presentation retains host authority")
	check(replica._name_label.text == "YOU ▼", "An online local player is immediately identifiable")
	var feedback: Node3D = load("res://scripts/party_feedback.gd").new()
	stage.add_child(feedback)
	for i: int in 60:
		feedback.emit_event(Vector3.ZERO, Color.CORAL, "land", 1.0)
	check(feedback.get_child_count() <= feedback.MAX_BURSTS, "Simultaneous feedback bursts are bounded")
	feedback.popup_score(Vector3.ZERO, 100, Color.CORAL)
	await create_timer(1.3).timeout
	check(feedback.get_child_count() == 0, "All feedback and score popups clean themselves up")
	stage.queue_free()
	await process_frame
	print("CHARACTER FEEDBACK TEST: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
