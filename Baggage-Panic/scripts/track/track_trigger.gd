class_name TrackTrigger
extends Area3D
## Non-lethal zone. collision_layer = BP.LAYER_PICKUP, group "track_trigger". OWNER: agent B.
## kind "checkpoint": full-width customs arch, data = {}.
## kind "route": one per fork branch, data = {"code": "LAX", "lane": 0}.

var kind := "checkpoint"
var data := {}
var fired := false

func _init() -> void:
	collision_layer = BP.LAYER_PICKUP
	collision_mask = 0
	monitoring = false
	monitorable = true
	add_to_group("track_trigger")

static func make_checkpoint() -> TrackTrigger:
	var node := TrackTrigger.new()
	node.kind = "checkpoint"
	TrackProps.shape(node, Vector3(8.0, 3.3, 0.8), Vector3(0, 1.65, 0))
	var metal := TrackProps.material("steel", Color(0.34, 0.4, 0.44), 0.72)
	var green := TrackProps.material("checkpoint_green", Color(0.05, 0.85, 0.49), 0.05, Color(0.02, 0.5, 0.22))
	for side in [-1.0, 1.0]:
		TrackProps.box(node, Vector3(0.25, 3.7, 0.5), Vector3(side * 4.0, 1.85, 0), metal)
		TrackProps.box(node, Vector3(0.055, 2.8, 0.55), Vector3(side * 3.82, 1.45, 0), green)
	TrackProps.box(node, Vector3(8.2, 0.55, 0.65), Vector3(0, 3.55, 0), TrackProps.material("checkpoint_blue", Color(0.05, 0.25, 0.48), 0.45))
	TrackProps.box(node, Vector3(8.2, 0.07, 0.68), Vector3(0, 3.85, 0), green)
	TrackProps.label(node, "BAGGAGE CHECKPOINT", Vector3(0, 3.54, 0.39), Color(0.65, 1, 1), 46)
	return node

static func make_route(code: String, lane: int) -> TrackTrigger:
	var node := TrackTrigger.new()
	node.kind = "route"
	node.data = {"code": code, "lane": lane}
	TrackProps.shape(node, Vector3(2.35, 3.0, 0.8), Vector3(0, 1.5, 0))
	return node
