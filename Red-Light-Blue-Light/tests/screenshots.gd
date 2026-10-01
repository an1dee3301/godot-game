extends SceneTree
const MAIN := preload("res://scenes/main.tscn")
var OUT := OS.get_environment("RLBL_SHOT_DIR").path_join("") if OS.get_environment("RLBL_SHOT_DIR") != "" else "user://"
var PORT := int(OS.get_environment("RLBL_TEST_PORT")) if OS.get_environment("RLBL_TEST_PORT") != "" else 17778
var host: RaceMain
var client: RaceMain
var hv: SubViewport
var cv: SubViewport
func _initialize() -> void:
	call_deferred("_run")
func _vp(n: String) -> SubViewport:
	var v := SubViewport.new(); v.name = n; v.size = Vector2i(1280, 720); v.own_world_3d = true
	v.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(v)
	set_multiplayer(SceneMultiplayer.new(), v.get_path())
	var m := MAIN.instantiate(); v.add_child(m)
	return v
func _shot(v: SubViewport, f: String) -> void:
	await RenderingServer.frame_post_draw
	v.get_texture().get_image().save_png(OUT + f)
func _f(n: int) -> void:
	for i in n: await process_frame
func _run() -> void:
	hv = _vp("H"); cv = _vp("C")
	host = hv.get_child(0); client = cv.get_child(0)
	await _f(20)
	await _shot(hv, "s1_menu.png")
	host.host_game("Andy", PORT); await _f(10)
	client.join_game("127.0.0.1", "Mickey", PORT); await _f(90)
	await _shot(hv, "s2_lobby_host.png")
	host.match_controller.request_player_ready(true)
	client.match_controller.request_player_ready.rpc_id(1, true)
	await _f(10); host.match_controller.request_start(); await _f(10)
	host.match_controller.time_left = 0.02; await _f(10)
	var hp: RacePlayer = host.players.get_node("1")
	hp.use_test_input = true; hp.test_input = Vector2(0.3, -1); await _f(90)
	hp.test_input = Vector2.ZERO
	await _shot(cv, "s3_go_client.png")
	host.match_controller.force_light(MatchController.Light.STOP, 10.0); await _f(60)
	await _shot(hv, "s4_red_host.png")
	var cp: RacePlayer = client.players.get_node(str(client.multiplayer.get_unique_id()))
	cp.use_test_input = true; cp.test_input = Vector2(0, -1); await _f(25)
	await _shot(cv, "s5_elim_client.png")
	hp.global_position = Vector3(2, 0.2, -24); await _f(40)
	await _shot(hv, "s6_doll_host.png")
	quit(0)
