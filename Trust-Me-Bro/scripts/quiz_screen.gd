extends Node3D
## Public quiz content lives on the physical studio screen, shared by every player.
const DISPLAY_FONT = preload("res://assets/fonts/Fredoka.ttf")
const BODY_FONT = preload("res://assets/fonts/DMSans.ttf")
const INK := Color("14284b")
const COLORS: Array[Color] = [Color("fa636b"),Color("51a6f5"),Color("47cda4"),Color("ffcf4d")]
const CENTERS: Array[float] = [-8.145,-2.715,2.715,8.145]
var _question: Label3D
var _letters: Array[Label3D] = []
var _answers: Array[Label3D] = []
var _plates: Array[MeshInstance3D] = []
var _display: FontVariation
var _body: FontVariation
var _key: String = ""

func _ready() -> void:
	_display = FontVariation.new()
	_display.base_font = DISPLAY_FONT
	_display.variation_opentype = {2003265652:650.0,2003072104:100.0}
	_body = FontVariation.new()
	_body.base_font = BODY_FONT
	_body.variation_opentype = {2003265652:700.0,1869640570:28.0}
	_question = _text("TRUST ME, BRO!",Vector3(0,5.95,-13.47),124,0.0078,21.1,_display)
	_question.name = "GiantScreenQuestion"
	for i in 4:
		var letter: Label3D = _text("ABCD"[i],Vector3(CENTERS[i]-1.94,3.85,-13.39),112,0.0066,0.75,_display)
		letter.name = "ScreenLetter" + "ABCD"[i]
		_letters.append(letter)
		var answer: Label3D = _text("",Vector3(CENTERS[i]+0.40,3.85,-13.39),88,0.0064,3.63,_body)
		answer.name = "ScreenAnswer" + "ABCD"[i]
		_answers.append(answer)
	var stage: Node = get_parent()
	for i in 4:
		_plates.append(stage.find_child("Screen_Answer_" + "ABCD"[i],true,false) as MeshInstance3D)
	show_title()

func _text(content: String,at: Vector3,size: int,pixel: float,width_m: float,font: Font) -> Label3D:
	var label: Label3D = Label3D.new()
	label.text = content
	label.font = font
	label.position = at
	label.font_size = size
	label.pixel_size = pixel
	label.width = width_m / pixel
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate = INK
	label.outline_size = 0
	label.shaded = false
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(label)
	return label

func show_title() -> void:
	_key = "title"
	_question.text = "TRUST ME, BRO!"
	_question.font_size = 146
	_set_choices(["Pick a tile","Shove a friend","Try to survive","Trust nobody"])

func show_round(number: int,title: String,_rule: String) -> void:
	_key = "round:%d" % number
	_question.text = "ROUND %d\n%s" % [number,title]
	_question.font_size = 122
	_set_choices(["", "", "", ""])

func show_question(prompt: String,answers: Array) -> void:
	var key: String = prompt + str(answers)
	if key == _key: return
	_key = key
	_question.text = prompt
	_question.font_size = 108 if prompt.length() > 82 else 122
	_set_choices(answers)

func reveal(correct: int,answer: String) -> void:
	_key = "answer:%d:%s" % [correct,answer]
	_question.text = "%s · %s" % ["ABCD"[clampi(correct,0,3)],answer]
	_question.font_size = 138 if answer.length() < 38 else 110
	for i in 4:
		_answers[i].modulate = INK if i == correct else INK.lightened(0.45)
		_letters[i].modulate = INK if i == correct else INK.lightened(0.45)
		_tint_plate(i,COLORS[i] if i == correct else Color("d4d9dd"))

func show_intermission() -> void:
	_key = "luck"
	_question.text = "A LITTLE LUCK.\nA LOT OF TROUBLE."
	_question.font_size = 120
	_set_choices(["", "", "", ""])

func show_winner(winner: String) -> void:
	_key = "winner"
	_question.text = "%s WINS!" % winner
	_question.font_size = 126
	_set_choices(["", "", "", ""])

func _set_choices(answers: Array) -> void:
	for i in 4:
		var content: String = str(answers[i]) if i < answers.size() else ""
		_answers[i].text = content
		# Two wrapped lines at 78 fit the authored 1.34 m display plates.
		_answers[i].font_size = 68 if content.length() > 25 else (78 if content.length() > 8 else 88)
		_answers[i].modulate = INK
		_letters[i].modulate = INK
		_letters[i].visible = not content.is_empty()
		_tint_plate(i,COLORS[i])

func _tint_plate(index: int,color: Color) -> void:
	var plate: MeshInstance3D = _plates[index]
	if not is_instance_valid(plate): return
	var material: StandardMaterial3D = plate.material_override as StandardMaterial3D
	if material == null:
		material = StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		plate.material_override = material
	material.albedo_color = color
