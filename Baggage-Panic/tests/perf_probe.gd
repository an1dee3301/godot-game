extends SceneTree
## Average FPS over a 20 s invulnerable run (needs a window). Run: Godot --path . -s res://tests/perf_probe.gd
const MAIN := preload("res://scenes/main.tscn")
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var main := MAIN.instantiate() as RunnerMain
	root.add_child(main)
	for i in 30:
		await process_frame
	main.start_run()
	main.player.hitbox.monitoring = false
	var samples: Array[float] = []
	var t := 0.0
	while t < 20.0:
		await process_frame
		t += root.get_process_delta_time()
		if main.player.global_position.y < 0.0:
			main.player.global_position.y = 0.0
			main.player.velocity.y = 0.0
		samples.append(Engine.get_frames_per_second())
	var total := 0.0
	var worst := 1000.0
	for s in samples.slice(60):
		total += s
		worst = minf(worst, s)
	print("PERF avg_fps=%.1f min_fps=%.1f draw_calls=%d objects=%d" % [total / (samples.size() - 60), worst,
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)])
	quit()
