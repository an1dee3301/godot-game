extends SceneTree
## Close-up renders of the terminal design kit (signs, furniture). Needs a window.
## Run: Godot --path . -s res://tests/design_booth.gd   (BP_SHOT_DIR=/abs/dir/)

var OUT := OS.get_environment("BP_SHOT_DIR") if OS.get_environment("BP_SHOT_DIR") != "" else "user://"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var env := AirportEnvironment.new()
	root.add_child(env)
	var stage := Node3D.new()
	stage.position = Vector3(-14.0, 0.0, -8.0)
	root.add_child(stage)
	Signage.panel(stage, Vector3(-2.0, 2.2, 0.0), "baggage_claim", {"arrow": "right"})
	Signage.panel(stage, Vector3(2.0, 2.2, 0.0), "gates", {"suffix": "A1–A12", "arrow": "left", "accent": DesignKit.SAGE})
	Signage.panel(stage, Vector3(0.0, 0.9, 0.0), "toilets", {"compact": true, "width": 2.6, "accent": DesignKit.INDIGO})
	var cam := Camera3D.new()
	cam.fov = 40.0
	root.add_child(cam)
	cam.global_position = stage.global_position + Vector3(0.4, 1.7, 5.2)
	cam.look_at(stage.global_position + Vector3(0.0, 1.6, 0.0))
	cam.current = true
	for i in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join("design_signs.png"))
	quit()
