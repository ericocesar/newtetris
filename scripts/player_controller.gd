extends Node

# Sinais
signal power_up_activated(type, target_player_id)

# Constantes e Enums
enum ControlScheme { PLAYER_1, PLAYER_2 }

# Variáveis de configuração
var control_scheme = ControlScheme.PLAYER_1
var player_id = 0
var opponent_id = 1

# Referências a outros nós
var grid = null
var power_up_system = null

# Configurações de controle
var controls = {
	ControlScheme.PLAYER_1: {
		"move_left": KEY_A,
		"move_right": KEY_D,
		"soft_drop": KEY_S,
		"hard_drop": KEY_SPACE,
		"rotate_cw": KEY_E,
		"rotate_ccw": KEY_Q,
		"hold": KEY_W,
		"use_power_up": KEY_F
	},
	ControlScheme.PLAYER_2: {
		"move_left": KEY_LEFT,
		"move_right": KEY_RIGHT,
		"soft_drop": KEY_DOWN,
		"hard_drop": KEY_KP_0,
		"rotate_cw": KEY_UP,
		"rotate_ccw": KEY_CONTROL,
		"hold": KEY_SHIFT,
		"use_power_up": KEY_KP_ENTER
	}
}

# Variáveis de estado
var das_active = false
var das_delay = 0.15  # Atraso inicial
var das_interval = 0.05  # Intervalo de repetição
var das_timer = 0.0
var das_direction = 0

var controls_flipped = false
var movement_blocked = false
var rotation_blocked = false
var input_enabled = true

func _ready():
	set_process_input(false)

# Configurar o controlador
func setup(tetris_grid, powerup_system, scheme, id, opponent):
	grid = tetris_grid
	power_up_system = powerup_system
	control_scheme = scheme
	player_id = id
	opponent_id = opponent
	
	set_process_input(true)

# Habilitar ou desabilitar entrada
func set_input_enabled(enabled):
	input_enabled = enabled

# Processar entradas
func _input(event):
	if !input_enabled or !grid or grid.is_paused() or grid.is_game_over():
		return
	
	var current_controls = controls[control_scheme]
	var tetromino = grid.get_current_tetromino()
	
	if !tetromino:
		return
	
	if event is InputEventKey:
		if event.pressed:
			# Mover para esquerda
			if event.keycode == current_controls["move_left"] and !movement_blocked:
				handle_move_input(-1)
			
			# Mover para direita
			elif event.keycode == current_controls["move_right"] and !movement_blocked:
				handle_move_input(1)
			
			# Queda suave
			elif event.keycode == current_controls["soft_drop"] and !movement_blocked:
				tetromino.set_fast_fall(true)
			
			# Queda rápida
			elif event.keycode == current_controls["hard_drop"] and !movement_blocked:
				tetromino.hard_drop()
			
			# Rotação horária
			elif event.keycode == current_controls["rotate_cw"] and !rotation_blocked:
				tetromino.rotate(true)
			
			# Rotação anti-horária
			elif event.keycode == current_controls["rotate_ccw"] and !rotation_blocked:
				tetromino.rotate(false)
			
			# Segurar peça
			elif event.keycode == current_controls["hold"]:
				grid.hold_tetromino()
			
			# Usar power-up
			elif event.keycode == current_controls["use_power_up"]:
				use_power_up()
		else:
			# Soltar tecla
			if event.keycode == current_controls["move_left"] or event.keycode == current_controls["move_right"]:
				das_active = false
				das_timer = 0.0
				das_direction = 0
			elif event.keycode == current_controls["soft_drop"]:
				tetromino.set_fast_fall(false)

# Processar movimento horizontal com DAS (Delayed Auto Shift)
func handle_move_input(direction):
	var tetromino = grid.get_current_tetromino()
	if !tetromino:
		return
	
	if controls_flipped:
		direction = -direction
	
	tetromino.move_horizontal(direction)
	
	das_active = true
	das_timer = 0.0
	das_direction = direction

# Atualizar o sistema DAS
func _process(delta):
	if !input_enabled or !grid or grid.is_paused() or grid.is_game_over():
		return
	
	var tetromino = grid.get_current_tetromino()
	if !tetromino:
		return
	
	if das_active:
		das_timer += delta
		if das_timer >= das_delay:
			var repeat_rate = (das_timer - das_delay) / das_interval
			if repeat_rate >= 1.0:
				tetromino.move_horizontal(das_direction)
				das_timer = das_delay + (repeat_rate - floor(repeat_rate)) * das_interval

# Usar um power-up
func use_power_up():
	if power_up_system and power_up_system.has_available_power_up(player_id):
		var power_up_type = power_up_system.get_available_power_up(player_id)
		power_up_system.activate_power_up(power_up_type, player_id, opponent_id)
		emit_signal("power_up_activated", power_up_type, opponent_id)

# Aplicar efeito de controles invertidos
func flip_controls(flip_state):
	controls_flipped = flip_state

# Bloquear movimento
func block_movement(blocked):
	movement_blocked = blocked

# Bloquear rotação
func block_rotation(blocked):
	rotation_blocked = blocked

# Reiniciar estados
func reset_states():
	controls_flipped = false
	movement_blocked = false
	rotation_blocked = false
	das_active = false
	das_timer = 0.0
	das_direction = 0