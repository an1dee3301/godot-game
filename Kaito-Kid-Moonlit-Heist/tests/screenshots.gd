extends SceneTree
## Renders gameplay screenshots (needs a window, not --headless).
## Run: Godot --path . -s res://tests/screenshots.gd   (KK_SHOT_DIR=/abs/dir/ optional)
## KK_SHOT_TOUR=1 also renders a tour of every guard route start and test point.

const MAIN := preload("res://scenes/main.tscn")
var OUT := OS.get_environment("KK_SHOT_DIR") if OS.get_environment("KK_SHOT_DIR") != "" else "user://"
var main: HeistMain
var _saved := PackedByteArray()


func _initialize() -> void:
	if FileAccess.file_exists(KK.SAVE_PATH):
		_saved = FileAccess.get_file_as_bytes(KK.SAVE_PATH)
	call_deferred("_run")


func _run() -> void:
	main = MAIN.instantiate() as HeistMain
	root.add_child(main)
	current_scene = main
	await _frames(90)
	await _shot("01_title.png")
	main.start_game()
	await _frames(60)
	await _shot("02_lobby.png")
	await _costume_shots()
	main.level.atmosphere().flash_now(1.0)
	await _frames(4)
	await _shot("03_lightning.png")

	await _guard_closeups()
	# Stand a few metres behind each guard and look at it.
	var i := 0
	for g: Guard in main.get_tree().get_nodes_in_group(KK.GROUP_GUARDS):
		var back := g.global_basis.z
		back.y = 0.0
		main.player.global_position = g.global_position + back.normalized() * 7.0
		main.player.look_at(g.global_position, Vector3.UP)
		main.camera_rig.snap_behind_target()
		await _frames(45)
		await _shot("04_guard_%d_%s.png" % [i, g.state_name()])
		i += 1
		if i >= 3 and OS.get_environment("KK_SHOT_TOUR") == "":
			break

	# Jewel close-up
	var jewel: Jewel = main.level.jewels()[0]
	main.player.global_position = jewel.global_position + Vector3(0, 0, 2.6)
	main.player.look_at(jewel.global_position, Vector3.UP)
	main.camera_rig.snap_behind_target()
	await _frames(40)
	await _shot("05_jewel.png")

	if OS.get_environment("KK_SHOT_TOUR") != "":
		var tp: Dictionary = main.level.test_points()
		for key: String in tp:
			main.player.global_position = tp[key]
			main.camera_rig.snap_behind_target()
			await _frames(30)
			await _shot("06_point_%s.png" % key)

	# Alarm + escape
	for j: Jewel in main.level.jewels():
		j.steal()
	await _frames(20)
	var exit := main.level.exit_node()
	main.player.global_position = exit.global_position + exit.global_basis.z * 5.0
	main.player.look_at(exit.global_position - exit.global_basis.z * 3.0, Vector3.UP)
	main.camera_rig.snap_behind_target()
	await _frames(90)
	await _shot("07_alarm_exit.png")
	main.player.global_position = exit.global_position - exit.global_basis.z * 2.5
	await _frames(200)
	await _shot("08_win.png")
	_restore()
	quit()


## Close-ups of the player model from several angles (for costume review).
func _costume_shots() -> void:
	var cam := Camera3D.new()
	cam.fov = 40.0
	main.add_child(cam)
	var p := main.player
	var views := {"front": Vector3(0, 1.3, -3.2), "side": Vector3(3.2, 1.3, 0), "back": Vector3(0.8, 1.6, 3.2)}
	for key: String in views:
		cam.global_position = p.global_position + p.global_basis * views[key]
		cam.look_at(p.global_position + Vector3.UP * 1.0, Vector3.UP)
		cam.current = true
		await _frames(20)
		await _shot("02_costume_%s.png" % key)
	p.anim.play("run")
	cam.global_position = p.global_position + p.global_basis * Vector3(2.6, 1.2, -1.8)
	cam.look_at(p.global_position + Vector3.UP * 1.0, Vector3.UP)
	await _frames(14)
	await _shot("02_costume_run.png")
	p.anim.play("idle")
	cam.queue_free()
	main.camera_rig.camera.current = true
	await _frames(5)


## Close-ups of the first guard and the inspector, from the front (models face their -Z).
func _guard_closeups() -> void:
	var cam := Camera3D.new()
	cam.fov = 40.0
	main.add_child(cam)
	var picked := {}
	for g: Guard in main.get_tree().get_nodes_in_group(KK.GROUP_GUARDS):
		if picked.has(g.kind):
			continue
		picked[g.kind] = true
		var fwd := -g.global_basis.z
		fwd.y = 0.0
		cam.global_position = g.global_position + fwd.normalized() * 3.4 + Vector3.UP * 1.4
		cam.look_at(g.global_position + Vector3.UP * 1.0, Vector3.UP)
		cam.current = true
		await _frames(3)
		await _shot("04_closeup_%s.png" % ("inspector" if g.kind == KK.EnemyKind.INSPECTOR else "guard"))
	cam.queue_free()
	main.camera_rig.camera.current = true
	await _frames(3)


func _restore() -> void:
	if _saved.is_empty():
		if FileAccess.file_exists(KK.SAVE_PATH):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(KK.SAVE_PATH))
	else:
		FileAccess.open(KK.SAVE_PATH, FileAccess.WRITE).store_buffer(_saved)


func _frames(count: int) -> void:
	for k in count:
		await process_frame


func _shot(file: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(OUT.path_join(file))
	print("shot ", file)
