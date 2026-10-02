extends SceneTree
## Renders the title screen and one establishing shot per museum room (needs a window).
## Run: KK_SHOT_DIR=/abs/dir Godot --path . -s res://tests/room_tour.gd

const MAIN := preload("res://scenes/main.tscn")
var OUT := OS.get_environment("KK_SHOT_DIR") if OS.get_environment("KK_SHOT_DIR") != "" else "user://"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := MAIN.instantiate() as HeistMain
	root.add_child(main)
	current_scene = main
	await _frames(150)
	await _shot("title.png")
	main.start_game()
	await _frames(40)
	main.player.global_position = Vector3(0, -50, 0)
	main.player.process_mode = Node.PROCESS_MODE_DISABLED
	main.hud.set_visible_hud(false)
	var cam := Camera3D.new()
	cam.fov = 62.0
	main.add_child(cam)
	cam.current = true
	for id: String in MuseumLayout.ROOMS:
		var r: Rect2 = MuseumLayout.ROOMS[id]["rect"]
		var h: float = MuseumLayout.ROOMS[id]["height"]
		var centre := Vector3(r.get_center().x, 1.2, r.get_center().y)
		var corner := Vector3(r.position.x + 1.2, clampf(h * 0.55, 1.8, 4.5) if h > 0.0 else 3.0, r.end.y - 1.2)
		if r.size.x < 6.0 or r.size.y < 6.0:
			corner = Vector3(r.get_center().x, 1.7, r.end.y - 1.0)
			centre = Vector3(r.get_center().x, 1.4, r.position.y + 1.0)
		cam.global_position = corner
		cam.look_at(centre, Vector3.UP)
		await _frames(25)
		await _shot("room_%s.png" % id)
	quit()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(file: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join(file))
