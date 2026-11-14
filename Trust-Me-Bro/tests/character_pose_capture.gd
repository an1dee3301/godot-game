extends SceneTree
## A conventional game-engine render for checking the Blender cast's poses.
func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(1280, 720)
	var scene: Node3D = Node3D.new()
	root.add_child(scene)
	var world: WorldEnvironment = WorldEnvironment.new()
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("bed9d7")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("fff5db")
	environment.ambient_light_energy = 0.8
	world.environment = environment
	scene.add_child(world)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45.0, -28.0, 0.0)
	sun.light_energy = 1.8
	scene.add_child(sun)
	var camera: Camera3D = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 9.2
	scene.add_child(camera)
	camera.position = Vector3(0.0, 4.5, 10.0)
	camera.look_at(Vector3(0.0, 0.8, 0.0))
	var actors: Array[Node3D] = []
	var colors: Array[Color] = [Color("ff8777"), Color("6bc5e4"), Color("efbe4e"), Color("85c788")]
	var names: Array[String] = ["IDLE / BLINK", "SHOVE", "JUMP", "CELEBRATE"]
	for i: int in 4:
		var actor: RigidBody3D = load("res://scripts/contestant.gd").new()
		actor.setup(i, names[i], colors[i])
		actor.position = Vector3((i - 1.5) * 2.05, 0.92, 0.0)
		scene.add_child(actor)
		actor.freeze = true
		actors.append(actor)
		var label: Label3D = Label3D.new()
		label.text = names[i]
		label.font_size = 44
		label.pixel_size = 0.009
		label.outline_size = 0
		label.modulate = Color("25475a")
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = Vector3(actor.position.x, -0.45, 0.0)
		scene.add_child(label)
		var floor: StaticBody3D = StaticBody3D.new()
		floor.position = Vector3(actor.position.x, -0.08, 0.0)
		floor.collision_layer = 1
		var collision: CollisionShape3D = CollisionShape3D.new()
		var shape: BoxShape3D = BoxShape3D.new()
		shape.size = Vector3(1.7, 0.16, 1.7)
		collision.shape = shape
		floor.add_child(collision)
		scene.add_child(floor)
	for i: int in 25:
		await physics_frame
	actors[1].perform_shove()
	actors[2].linear_velocity = Vector3.UP * 4.0
	actors[3].celebrate()
	for i: int in 8:
		await physics_frame
	await process_frame
	RenderingServer.force_draw(false)
	var target: String = "/tmp/trust-cast-poses.png"
	root.get_texture().get_image().save_png(target)
	print("CAPTURED ", target)
	quit()
