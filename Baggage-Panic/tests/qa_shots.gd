extends SceneTree
## QA renders along a long invulnerable run: chase view + side views of the concourse.
## Run windowed: Godot --path . -s res://tests/qa_shots.gd   (BP_SHOT_DIR=/abs/dir/)

const MAIN := preload("res://scenes/main.tscn")
var OUT := OS.get_environment("BP_SHOT_DIR") if OS.get_environment("BP_SHOT_DIR") != "" else "user://"
var main: RunnerMain
var _saved_scores := PackedByteArray()


func _initialize() -> void:
	if FileAccess.file_exists(BP.SAVE_PATH):
		_saved_scores = FileAccess.get_file_as_bytes(BP.SAVE_PATH)
	call_deferred("_run")


func _run() -> void:
	main = MAIN.instantiate() as RunnerMain
	root.add_child(main)
	await _frames(20)
	main.start_run()
	main.player.hitbox.monitoring = false
	var side_cam := Camera3D.new()
	side_cam.fov = 60.0
	main.add_child(side_cam)
	for i in 12:
		await _frames(150)
		var seg := main.track.active_segments()
		var types := []
		for s in seg:
			types.append(s.segment_type)
		print("shot %02d z=%.0f types=%s" % [i, main.player.global_position.z, str(types)])
		await _shot("qa_%02d_chase.png" % i)
		if i % 3 == 1:
			var p := main.player.global_position
			for side in [-1.0, 1.0]:
				side_cam.global_position = Vector3(side * 5.5, 3.0, p.z - 4.0)
				side_cam.look_at(Vector3(side * 20.0, 2.5, p.z - 12.0))
				side_cam.current = true
				await _shot("qa_%02d_side_%s.png" % [i, "L" if side < 0.0 else "R"])
			main.camera.current = true
	if FileAccess.file_exists(BP.SAVE_PATH) or not _saved_scores.is_empty():
		if _saved_scores.is_empty():
			DirAccess.remove_absolute(ProjectSettings.globalize_path(BP.SAVE_PATH))
		else:
			FileAccess.open(BP.SAVE_PATH, FileAccess.WRITE).store_buffer(_saved_scores)
	quit()


func _frames(count: int) -> void:
	for i in count:
		# Keep the player on the belts so the run continues over gaps.
		if main.player.global_position.y < 0.0:
			main.player.global_position.y = 0.0
			main.player.velocity.y = 0.0
		await physics_frame


func _shot(file: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join(file))
