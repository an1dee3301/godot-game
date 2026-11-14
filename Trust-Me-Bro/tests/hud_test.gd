extends SceneTree
const Hud = preload("res://scripts/hud.gd")
class Contestant extends RefCounted:
	var display_name: String = "Alex"
	var contestant_id: int = 0
	var tint: Color = Color("ff7469")
	var score: int = 100
	var active: bool = true
	var has_crown: bool = false
	var perk: String = ""
var checks: int = 0
var failures: int = 0
var hud: CanvasLayer
var events: Array = []
func _initialize() -> void:
	call_deferred("run")
func check(value: bool,message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("HUD: " + message)
func find_button(text: String) -> Button:
	for node: Node in hud.root.find_children("*","Button",true,false):
		if node.text == text: return node
	return null
func run() -> void:
	hud = Hud.new()
	root.add_child(hud)
	await process_frame
	check(hud.menu.visible and not hud.game.visible,"Start on the party chooser")
	check(hud._title_page.visible and not hud._setup_page.visible,"Title should focus on play, with setup forms hidden")
	hud._open_setup("couch")
	check(hud._couch_form.is_visible_in_tree() and not hud._online_form.is_visible_in_tree(),"Couch setup should not expose network forms")
	hud._open_setup("join")
	check(hud._address_input.is_visible_in_tree() and hud._join_submit.visible and not hud._host_submit.visible,"Join setup should show only the joining form")
	hud._open_setup("host")
	check(not hud._address_input.is_visible_in_tree() and hud._host_submit.visible,"Host setup should not ask for someone else's address")
	hud._back_to_title()
	check(hud._title_page.visible and root.gui_get_focus_owner() == hud._title_play_button,"Back should restore the title and its gamepad focus")
	hud.host_requested.connect(func(label: String,port: int) -> void: events.append(["host",label,port]))
	hud.join_requested.connect(func(address: String,label: String,port: int) -> void: events.append(["join",address,label,port]))
	hud.start_requested.connect(func(amount: int) -> void: events.append(["couch",amount]))
	hud.ready_requested.connect(func(ready: bool) -> void: events.append(["ready",ready]))
	hud._open_setup("host")
	hud._name_input.text = "  Alex  "
	hud._port_input.text = "24900"
	find_button("Create room").pressed.emit()
	check(events.back() == ["host","Alex",24900],"Host button must send chosen name and port")
	hud._address_input.text = "192.168.1.20"
	find_button("Join room").pressed.emit()
	check(events.back() == ["join","192.168.1.20","Alex",24900],"Join button must send the entered host address")
	var previous: int = events.size()
	hud._address_input.text = ""
	find_button("Join room").pressed.emit()
	check(events.size() == previous and not hud._connection_status.text.is_empty(),"Blank address must explain the error without attempting a connection")
	hud._port_input.text = "99999"
	find_button("Create room").pressed.emit()
	check(events.size() == previous,"Invalid port must not silently connect to a different port")
	hud._select_humans(3)
	hud._start_button.pressed.emit()
	check(events.back() == ["couch",3],"Couch start must preserve selected human count")
	hud._name_input.grab_focus()
	await process_frame
	check(root.gui_get_focus_owner() == hud._name_input,"Name input should accept menu typing")
	hud.show_game()
	check(root.gui_get_focus_owner() == null,"Starting the game must release text-input focus")
	check(hud._sound_button.focus_mode == Control.FOCUS_NONE,"Sound button must not swallow jump input")
	hud.update_round(0,"CROWD CONTROL","Stand on the right pad.")
	check(not hud._question_panel.visible,"Round intro should not show a stale question")
	hud.update_question("Which number is even?",["2","3","5","7"],1,2)
	hud.update_question_metadata("Brain Teasers","easy","Two is divisible by two.")
	check(not hud._question_panel.visible and not hud._answer_row.visible and hud._answer_labels[0].text == "2","Question data stays available while the 3D studio screen owns its presentation")
	check(not hud._status.text.contains("divisible"),"The answer explanation must not display before reveal")
	check(hud._answer_row.get_rect().end.y <= 195 and hud._question_panel.get_rect().end.y <= 195,"Question UI must preserve the stage below the top HUD")
	hud.reveal_answer(0)
	hud.show_banner("A  ·  TWO","Two is divisible by two.")
	hud.update_timer(3.8,12.0)
	check(hud.banner.position.y >= 700 and hud.banner.size.y <= 65 and hud._timer.text == "0" and hud._banner_title.text == "SAFE!","Answer reveal should be a small safe callout below the stage and lock the timer at zero")
	hud.show_countdown(3)
	check(hud._countdown.visible and not hud.banner.visible,"Countdown replaces the intro card")
	hud.hide_banner()
	check(not hud._countdown.visible,"Question start must remove the countdown")
	hud.update_gacha_entries([{"id":0,"name":"Alex","perk":"nerd"},{"id":3,"name":"Pip","perk":"heavy"}])
	hud.show_banner("LUCKY SLOP!","")
	check(hud._gacha.visible and not hud.banner.visible and hud._gacha_names[0].text == "Alex" and hud._gacha_perks[0].text == "Nerd Glasses","Lucky Slop must present owners and readable perks")
	check(hud._gacha_cards[1].visible and not hud._gacha_cards[2].visible,"Perk panel must not show unassigned owners")
	hud.hide_banner()
	check(hud._status.text == "Two is divisible by two.","Reveal should display the explanation")
	hud.show_lobby([{"id":1,"slot":0,"name":"Alex","ready":true}],true,"Room open")
	check(hud.lobby.visible and not hud._network_start_button.disabled,"A lone host can start with bot seats")
	hud.show_lobby([{"id":1,"slot":0,"name":"Alex","ready":true},{"id":20,"slot":1,"name":"Pip","ready":false}],true)
	check(hud._network_start_button.disabled,"Host start must wait for an unready friend")
	hud.show_lobby([{"id":1,"slot":0,"name":"Alex","ready":true},{"id":20,"slot":1,"name":"Pip","ready":true}],true)
	check(not hud._network_start_button.disabled,"Host start should enable when every friend is ready")
	hud.show_lobby([{"id":1,"slot":0,"name":"Alex","ready":true},{"id":20,"slot":1,"name":"Pip","ready":false}],false)
	hud._ready_button.pressed.emit()
	check(events.back() == ["ready",true],"A joining player can signal ready")
	check(not hud._network_start_button.visible and hud._ready_button.visible,"Only the host sees the match-start control")
	hud.show_pause(true)
	check(hud._pause_note.text.contains("keeps going"),"Online pause must explain that the party continues")
	hud.show_pause(false)
	var actors: Array = []
	for i in 8:
		var actor: Contestant = Contestant.new()
		actor.contestant_id = i
		actor.display_name = "PLAYER %d" % [i + 1]
		actor.score = 1000 - i * 100
		actors.append(actor)
	hud.set_local_player(2)
	hud.update_scores(actors)
	var visible_scores: int = 0
	for card: Panel in hud._player_cards:
		if card.visible: visible_scores += 1
	check(visible_scores == 1 and hud._player_cards[2].visible,"In play, only the local player's portrait and score are shown")
	actors[2].active = false
	hud.show_banner("B  ·  WRONG TILE","Hidden explanation")
	hud.update_scores(actors)
	check(hud._banner_title.text == "NOPE!" and not hud._banner_subtitle.visible,"An eliminated local player gets a short reaction without an explanation wall")
	hud.show_results(actors)
	check(not hud._restart_button.visible,"A client must not receive a replay-start button")
	hud.set_network_role(true,true)
	hud.show_results(actors)
	check(hud._restart_button.visible,"The host can replay a network match")
	check(hud._results_rows.get_child_count() == 8,"Replay should not duplicate ranking rows")
	actors[1].score = actors[0].score
	hud.show_results(actors)
	check(hud._winner_label.text == "IT'S A TIE!","Equal highest scores must share the result")
	hud.queue_free()
	await process_frame
	await process_frame
	print("HUD TEST: %d checks, %d failures" % [checks,failures])
	quit(1 if failures > 0 else 0)
