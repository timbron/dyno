class_name SquadPortrait
extends PanelContainer
## One squad member's row in the tactical HUD: letter tile, name, state word and the
## health and stamina bars. The HUD calls refresh() every frame.

## The member shown; set by setup().
var dino: Dino

## Last applied HudFormat.Look, -1 = none yet.
var _look: int = -1

@onready var _number: Label = %Number
@onready var _glyph: Label = %Glyph
@onready var _name: Label = %Name
@onready var _state: Label = %State
@onready var _health_bar: ProgressBar = %HealthBar
@onready var _stamina_bar: ProgressBar = %StaminaBar


## Shows [param member] as squad number [param number] (1-based). Call after the node is
## in the tree.
func setup(member: Dino, number: int) -> void:
	dino = member
	_number.text = str(number)
	_glyph.text = HudFormat.portrait_glyph(member.display_label)
	_name.text = member.display_label
	refresh(false)


func refresh(selected: bool) -> void:
	var gone := not is_instance_valid(dino)
	var dead := gone or dino.is_dead()
	if gone:
		_health_bar.value = 0.0
		_stamina_bar.value = 0.0
	else:
		_health_bar.max_value = dino.species.max_health
		_health_bar.value = dino.health
		_stamina_bar.max_value = dino.species.max_stamina
		_stamina_bar.value = 0.0 if dead else dino.stamina
	_state.text = HudFormat.member_state(selected, dead, 0 if gone else dino.commands.size())
	var look := HudFormat.member_look(selected, dead)
	if look == _look:
		return
	_look = look
	match look:
		HudFormat.Look.SELECTED:
			_apply_look(JungleTheme.PORTRAIT_ROW_SELECTED, JungleTheme.LABEL_UNIT, false)
		HudFormat.Look.NORMAL:
			_apply_look(JungleTheme.PORTRAIT_ROW, JungleTheme.LABEL_UNIT_DIM, false)
		HudFormat.Look.DEAD:
			_apply_look(JungleTheme.PORTRAIT_ROW, JungleTheme.LABEL_UNIT_DIM, true)


func _apply_look(row: StringName, name_variation: StringName, dead: bool) -> void:
	theme_type_variation = row
	_name.theme_type_variation = name_variation
	if dead:
		_glyph.text = "X"
	elif is_instance_valid(dino):
		_glyph.text = HudFormat.portrait_glyph(dino.display_label)
