extends SceneTree
## Contact sheet of every livery's tail art + wordmark. Run: Godot --headless --path . -s res://tests/livery_sheet.gd
var OUT := OS.get_environment("BP_SHOT_DIR") if OS.get_environment("BP_SHOT_DIR") != "" else "user://"
func _initialize() -> void:
	var files: Array[String] = []
	for f in DirAccess.get_files_at("res://scripts/world/liveries"):
		if f.ends_with(".gd"):
			files.append("res://scripts/world/liveries/" + f)
	files.sort()
	var cell := Vector2i(400, 200)
	var sheet := Image.create(cell.x * 4, cell.y * ceili(files.size() / 4.0), false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.86, 0.83, 0.78))
	for i in files.size():
		var spec: Dictionary = (load(files[i]) as GDScript).call("spec")
		var origin := Vector2i((i % 4) * cell.x, (i / 4) * cell.y)
		sheet.fill_rect(Rect2i(origin + Vector2i(6, 6), Vector2i(cell.x - 12, cell.y - 12)), spec["body"] as Color)
		sheet.fill_rect(Rect2i(origin + Vector2i(6, cell.y - 40), Vector2i(cell.x - 12, 34)), spec["belly"] as Color)
		var tail := (spec["tail_texture"] as Texture2D).get_image()
		tail.convert(Image.FORMAT_RGBA8)
		tail.resize(150, 150)
		sheet.blend_rect(tail, Rect2i(0, 0, 150, 150), origin + Vector2i(10, 10))
		var title := (spec["title_texture"] as Texture2D).get_image()
		title.convert(Image.FORMAT_RGBA8)
		title.resize(220, 55)
		sheet.blend_rect(title, Rect2i(0, 0, 220, 55), origin + Vector2i(170, 60))
	sheet.save_png(OUT.path_join("liveries.png"))
	print("LIVERIES %d" % files.size())
	quit()
