extends SceneTree
## Headless check for the concourse dressing layer. Run: Godot --headless --path . -s res://tests/dressing_check.gd
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var layer := (load("res://scripts/world/concourse_dressing.gd") as GDScript).new() as Node3D
	root.add_child(layer)
	for i in 600:
		layer.call("follow", -float(i) * 1.5)
		await process_frame
	var nodes := 0
	var pending: Array[Node] = [layer]
	while not pending.is_empty():
		var current: Node = pending.pop_back()
		if current is MeshInstance3D or current is MultiMeshInstance3D or current is Label3D:
			nodes += 1
		pending.append_array(current.get_children())
	print(("DRESSING_OK" if nodes <= 7000 else "DRESSING_FAIL") + " nodes=%d" % nodes)
	quit()
