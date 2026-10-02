class_name HeistHUD
extends CanvasLayer
## Procedural in-game display for the phantom thief.

var level: MuseumLevel
var player: PhantomThief
var canvas: HeistHUDCanvas
var _banner_tween: Tween


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
	canvas.objective = objective
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


## Slide a temporary calling-card announcement across the lower screen.
func show_banner(message: String, color: Color = Color.WHITE, seconds: float = 2.5) -> void:
	if canvas == null:
		return
	if _banner_tween != null and _banner_tween.is_running():
		_banner_tween.kill()
	canvas.banner = message
	canvas.banner_color = color
	canvas.banner_alpha = 0.0
	canvas.banner_slide = 28.0
	_banner_tween = create_tween().set_parallel(true)
	_banner_tween.tween_property(canvas, "banner_alpha", 1.0, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_banner_tween.tween_property(canvas, "banner_slide", 0.0, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_banner_tween.chain().tween_interval(seconds)
	_banner_tween.chain().tween_property(canvas, "banner_alpha", 0.0, 0.35)


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
