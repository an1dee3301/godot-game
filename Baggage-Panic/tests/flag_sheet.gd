extends SceneTree
## Run headless with -s res://tests/flag_sheet.gd; BP_FLAG_SHEET overrides the output path.


func _initialize() -> void:
	call_deferred("_make_sheet")


func _make_sheet() -> void:
	var cell_w := 252
	var cell_h := 150
	var columns := 4
	var rows := ceili(float(Flags.CODES.size()) / float(columns))
	var sheet := Image.create_empty(columns * cell_w, rows * cell_h, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("dddddd"))
	for i in Flags.CODES.size():
		var flag := Flags.image(Flags.CODES[i], 120)
		var x := (i % columns) * cell_w + 6
		var y := (i / columns) * cell_h + 6
		sheet.blit_rect(flag, Rect2i(0, 0, flag.get_width(), flag.get_height()), Vector2i(x, y))
	var path := OS.get_environment("BP_FLAG_SHEET")
	if path.is_empty():
		path = "/tmp/bp_flags.png"
	var error := sheet.save_png(path)
	if error != OK:
		printerr("Flag contact sheet failed: ", error)
		quit(1)
		return
	print("Flag contact sheet: ", path)
	quit()
