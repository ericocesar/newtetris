extends Node

# Sinais
signal tetromino_settled

# Referência à grade de Tetris
@export var tetris_grid: Node2D
@export var player_id: int = 1
@export var ui_node: Node

# Variáveis de controle
var move_delay = 0.1
var move_timer = 0
var is_moving_left = false
var is_moving_right = false
var is_soft_dropping = false
var controls_mirrored = false  # Flag para controles espelhados

# Referência à classe PowerUp
const PowerUpClass = preload("res://scripts/power_up.gd")

# Estados para controle de input
var block_rotation = false  # Bloqueio de rotação (power-up)
var block_movement = false  # Bloqueio de movimento (power-up)
var flip_controls = false   # Controles invertidos (power-up)

# Referência ao tetromino atual
var active_tetromino = null

# Configuração de entrada
func _ready():
	if tetris_grid:
		tetris_grid.player_id = player_id
		
		# Conecta sinais
		tetris_grid.connect("game_over", _on_game_over)
		tetris_grid.connect("power_up_gained", _on_power_up_gained)
		tetris_grid.connect("power_up_used", _on_power_up_used)
		tetris_grid.connect("power_up_received", _on_power_up_received)
		
		# Configura sinais do GameManager
		GameManager.connect("game_started", _on_game_started)
		GameManager.connect("game_over", _on_game_over)
		GameManager.connect("power_up_sent", _on_power_up_sent)
		GameManager.connect("player_controls_mirrored", _on_player_controls_mirrored)

# Processamento de entrada
func _process(delta):
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
		
	# Movimento contínuo com atraso
	move_timer += delta
	
	if move_timer >= move_delay:
		move_timer = 0
		
		if is_moving_left:
			if controls_mirrored:
				tetris_grid.move_piece_right()  # Invertido quando controles espelhados
			else:
				tetris_grid.move_piece_left()
		
		if is_moving_right:
			if controls_mirrored:
				tetris_grid.move_piece_left()  # Invertido quando controles espelhados
			else:
				tetris_grid.move_piece_right()
		
		if is_soft_dropping:
			tetris_grid.move_piece_down()

# Detecção de teclas pressionadas
func _input(event):
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	
	# Movimentos do jogador 1
	if player_id == 1:
		if event.is_action_pressed("p1_move_left"):
			is_moving_left = true
			if controls_mirrored:
				tetris_grid.move_piece_right()  # Invertido quando controles espelhados
			else:
				tetris_grid.move_piece_left()
		elif event.is_action_released("p1_move_left"):
			is_moving_left = false
		
		if event.is_action_pressed("p1_move_right"):
			is_moving_right = true
			if controls_mirrored:
				tetris_grid.move_piece_left()  # Invertido quando controles espelhados
			else:
				tetris_grid.move_piece_right()
		elif event.is_action_released("p1_move_right"):
			is_moving_right = false
		
		if event.is_action_pressed("p1_rotate"):
			tetris_grid.rotate_piece()
		
		if event.is_action_pressed("p1_soft_drop"):
			is_soft_dropping = true
		elif event.is_action_released("p1_soft_drop"):
			is_soft_dropping = false
		
		if event.is_action_pressed("p1_hard_drop"):
			tetris_grid.hard_drop()
		
		if event.is_action_pressed("p1_hold"):
			tetris_grid.hold_piece()
		
		# Teclas para ativar power-ups (1-5)
		if event.is_action_pressed("p1_powerup1"):
			use_power_up(0)
		elif event.is_action_pressed("p1_powerup2"):
			use_power_up(1)
		elif event.is_action_pressed("p1_powerup3"):
			use_power_up(2)
	
	# Movimentos do jogador 2
	elif player_id == 2:
		if event.is_action_pressed("p2_move_left"):
			is_moving_left = true
			if controls_mirrored:
				tetris_grid.move_piece_right()  # Invertido quando controles espelhados
			else:
				tetris_grid.move_piece_left()
		elif event.is_action_released("p2_move_left"):
			is_moving_left = false
		
		if event.is_action_pressed("p2_move_right"):
			is_moving_right = true
			if controls_mirrored:
				tetris_grid.move_piece_left()  # Invertido quando controles espelhados
			else:
				tetris_grid.move_piece_right()
		elif event.is_action_released("p2_move_right"):
			is_moving_right = false
		
		if event.is_action_pressed("p2_rotate"):
			tetris_grid.rotate_piece()
		
		if event.is_action_pressed("p2_soft_drop"):
			is_soft_dropping = true
		elif event.is_action_released("p2_soft_drop"):
			is_soft_dropping = false
		
		if event.is_action_pressed("p2_hard_drop"):
			tetris_grid.hard_drop()
		
		if event.is_action_pressed("p2_hold"):
			tetris_grid.hold_piece()
			
		# Teclas para ativar power-ups (1-5)
		if event.is_action_pressed("p2_powerup1"):
			use_power_up(0)
		elif event.is_action_pressed("p2_powerup2"):
			use_power_up(1)
		elif event.is_action_pressed("p2_powerup3"):
			use_power_up(2)

# Usa um power-up específico pelo índice
func use_power_up(index):
	if tetris_grid:
		if tetris_grid.use_power_up(index):
			update_power_up_ui()

# Atualiza a interface do usuário para os power-ups
func update_power_up_ui():
	if ui_node:
		# Solicita ao nó de UI para atualizar a exibição de power-ups
		ui_node.update_power_ups(tetris_grid.available_power_ups)

# Callbacks de sinais
func _on_game_started():
	if tetris_grid:
		tetris_grid.reset_grid()
		
	# Reinicia variáveis de controle
	is_moving_left = false
	is_moving_right = false
	is_soft_dropping = false
	controls_mirrored = false
	
	update_power_up_ui()

func _on_game_over(winner_id):
	# Limpa as flags de movimento
	is_moving_left = false
	is_moving_right = false
	is_soft_dropping = false
	controls_mirrored = false

# Quando o jogador recebe um power-up
func _on_power_up_received(power_type, from_player_id):
	# Atualizar UI e aplicar efeitos visuais
	if ui_node:
		ui_node.show_power_up_effect(power_type, true)  # True = é recebido
	
	# Efeitos sonoros
	# play_power_up_sound(power_type, true)

# Quando um jogador ganha um power-up
func _on_power_up_gained(power_type, player_id):
	if player_id == self.player_id:
		update_power_up_ui()
		
		# Efeitos sonoros
		# play_power_up_sound(power_type, false)  # False = não é recebido

# Quando um jogador usa um power-up
func _on_power_up_used(power_type, player_id):
	if player_id == self.player_id:
		update_power_up_ui()
		
		# Para power-ups que afetam o oponente, encaminha para o GameManager
		match power_type:
			PowerUpClass.Type.CLEAR_ROWS, PowerUpClass.Type.SPEED_UP, PowerUpClass.Type.BLOCK_SWAP, PowerUpClass.Type.MIRROR:
				GameManager.send_power_up(player_id, power_type)

# Quando um power-up é enviado ao jogador
func _on_power_up_sent(target_player_id, power_type, from_player_id):
	if target_player_id == player_id and tetris_grid:
		tetris_grid.receive_power_up(power_type, from_player_id)

# Quando os controles do jogador precisam ser espelhados
func _on_player_controls_mirrored(player_id, is_mirrored):
	if player_id == self.player_id:
		controls_mirrored = is_mirrored
		
		# Efeito visual na UI
		if ui_node:
			ui_node.show_mirror_effect(is_mirrored)

# Conecta o controle com o tetromino
func connect_tetromino(tetromino):
	if active_tetromino != null:
		# Desconecta o tetromino anterior se existir
		active_tetromino.settled.disconnect(_on_tetromino_settled)
	
	active_tetromino = tetromino
	
	if active_tetromino != null:
		# Conecta o sinal de assentamento do tetromino
		active_tetromino.settled.connect(_on_tetromino_settled)

# Quando um tetromino assenta na grade
func _on_tetromino_settled():
	# Desconecta o tetromino atual
	active_tetromino = null
	
	# Emite sinal para o gerenciador de jogo
	emit_signal("tetromino_settled")

# Define se o controlador está com rotação bloqueada
func set_block_rotation(value):
	block_rotation = value

# Define se o controlador está com movimento bloqueado
func set_block_movement(value):
	block_movement = value

# Define se os controles estão invertidos
func set_flip_controls(value):
	flip_controls = value 