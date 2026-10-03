extends SceneTree
## Headless smoke check for TarmacView.

func _initialize() -> void:
	var view := TarmacView.new()
	root.add_child(view)
	await process_frame
	for i in 600:
		view.follow(-float(i) * 1.5)
		view.set_intensity(float(i) / 600.0)
		await process_frame
	var meshes := 0
	var pending: Array[Node] = [view]
	while not pending.is_empty():
		var current: Node = pending.pop_back()
		if current is MeshInstance3D or current is MultiMeshInstance3D:
			meshes += 1
		for child in current.get_children():
			pending.append(child)
	if meshes > 2500 or meshes < 200:
		push_error("Tarmac mesh count outside expected range: %d" % meshes)
		quit(1)
		return
	print("TARMAC_OK meshes=%d" % meshes)
	quit(0)
