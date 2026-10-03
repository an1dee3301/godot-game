extends RefCounted
## Example module: a slatted oak bench. Shows the contract every generated module follows.

static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root := Node3D.new()
	root.name = "ExampleBench"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var oak := DesignKit.wood()
	for slat in 4:
		DesignKit.rbox(root, Vector3(1.8, 0.05, 0.12), Vector3(0.0, 0.42, -0.2 + float(slat) * 0.14), oak, 0.02)
	for x in [-0.75, 0.75]:
		DesignKit.rbox(root, Vector3(0.05, 0.42, 0.5), Vector3(x, 0.21, 0.0), DesignKit.metal(), 0.02)
	if variant % 2 == 1:
		DesignKit.rbox(root, Vector3(1.8, 0.4, 0.05), Vector3(0.0, 0.66, -0.27), oak, 0.02)
	return root
