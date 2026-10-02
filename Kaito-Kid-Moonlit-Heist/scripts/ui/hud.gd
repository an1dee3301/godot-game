class_name HeistHUD
extends CanvasLayer
## Procedural in-game display for the phantom thief.

var level: MuseumLevel
var player: PhantomThief
var canvas: HeistHUDCanvas
var _banner_tween: Tween
var _banner_queue: Array[Dictionary] = []
var _recent_banners: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	canvas = HeistHUDCanvas.new()
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(canvas)


## Connect the map and live player readouts.
func setup(p_level: MuseumLevel, p_player: PhantomThief) -> void:
	level = p_level
	player = p_player
	if canvas == null:
		_ready()
	canvas.level = level
	canvas.player = player
	canvas.queue_redraw()


## Update health, including the delayed damage trail.
func set_health(hp: float, max_hp: float) -> void:
	if canvas == null:
		return
	canvas.max_hp = maxf(max_hp, 1.0)
	canvas.hp = clampf(hp, 0.0, canvas.max_hp)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(canvas, "health_display", canvas.hp, 0.23).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(canvas, "health_ghost", canvas.hp, 0.55).set_delay(0.27).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## Set the collected jewel count.
func set_jewels(count: int, total: int) -> void:
	if canvas == null:
		return
	canvas.jewels = count
	canvas.jewels_total = total
	canvas.queue_redraw()


## Set remaining smoke bombs.
func set_smoke(count: int) -> void:
	if canvas == null:
		return
	canvas.smoke = count
	canvas.queue_redraw()


## Show the focused interaction, or clear it with an empty string.
func set_prompt(prompt: String) -> void:
	if canvas == null or canvas.prompt == prompt:
		return
	canvas.prompt = prompt
	canvas.queue_redraw()


## Update the mission line.
func set_objective(objective: String) -> void:
	if canvas == null:
		return
	canvas.objective = "ONE LAST VANISH" if objective.to_lower().contains("escape") else "FIVE JEWELS. ONE ENCORE."
	canvas.queue_redraw()


## Set elapsed run time in seconds.
func set_timer(seconds: float) -> void:
	if canvas != null:
		canvas.elapsed = seconds


## Set guard alert intensity, from hidden through chase.
func set_alert(alert_level: int) -> void:
	if canvas == null:
		return
	canvas.alert_level = clampi(alert_level, 0, 2)
	var tween := create_tween()
	tween.tween_property(canvas, "alert_fade", 1.0 if alert_level >= 2 else 0.0, 0.5)


## Queue a restrained announcement; repeated warnings are suppressed briefly.
func show_banner(message: String, color: Color = Color.WHITE, seconds: float = 2.5) -> void:
	if canvas == null:
		return
	var line := _rewrite_banner(message)
	var now := Time.get_ticks_msec()
	if int(_recent_banners.get(line, -100000)) + 6500 > now:
		return
	_recent_banners[line] = now
	if _banner_queue.size() >= 3:
		_banner_queue.pop_front()
	_banner_queue.append({"text": line, "color": color, "seconds": minf(seconds, 2.8)})
	if _banner_tween == null or not _banner_tween.is_running():
		_play_next_banner()


func _rewrite_banner(message: String) -> String:
	var lower := message.to_lower()
	var rewritten := message
	if lower.contains("showtime"):
		rewritten = "Ladies and gentlemen…"
	elif lower.contains("laser grid offline"):
		rewritten = "A little sleight of hand."
	elif lower.contains("laser tripped"):
		rewritten = "A rather loud entrance."
	elif lower.contains("camera spotted"):
		rewritten = "Caught my good side?"
	elif lower.contains("kaito kid") or lower.contains("get him"):
		rewritten = "Too slow, Inspector!"
	elif lower.contains("all jewels") or lower.contains("alarm!"):
		rewritten = "And now, the grand exit."
	elif lower.contains("stolen"):
		rewritten = "%s — gone without a trace." % message.get_slice(" stolen", 0)
	return rewritten


func _play_next_banner() -> void:
	if _banner_queue.is_empty() or canvas == null:
		return
	var item: Dictionary = _banner_queue.pop_front()
	canvas.banner = String(item["text"])
	canvas.banner_color = item["color"] as Color
	canvas.banner_alpha = 0.0
	canvas.banner_slide = 13.0
	_banner_tween = create_tween().set_parallel(true)
	_banner_tween.tween_property(canvas, "banner_alpha", 1.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_banner_tween.tween_property(canvas, "banner_slide", 0.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_banner_tween.chain().tween_interval(float(item["seconds"]))
	_banner_tween.chain().tween_property(canvas, "banner_alpha", 0.0, 0.38)
	_banner_tween.finished.connect(_play_next_banner)


## Pulse crimson at the screen edge when Kaito is hurt.
func flash_damage() -> void:
	if canvas == null:
		return
	canvas.damage_flash = 0.85
	create_tween().tween_property(canvas, "damage_flash", 0.0, 0.55).set_trans(Tween.TRANS_CUBIC)


## Flash cold moonlight across the screen during lightning.
func show_lightning(strength: float) -> void:
	if canvas == null:
		return
	canvas.lightning_flash = clampf(strength, 0.0, 1.0) * 0.68
	create_tween().tween_property(canvas, "lightning_flash", 0.0, 0.22)


## Toggle the complete in-game layer.
func set_visible_hud(on: bool) -> void:
	visible = on
