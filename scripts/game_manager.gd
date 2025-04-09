extends Node

# Configuração do jogo
const GRID_WIDTH = 10
const GRID_HEIGHT = 20
const EMPTY_CELL = -1

# Carrega a classe de power-up
const PowerUpClass = preload("res://scripts/power_up.gd")

# Estados do jogo
enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER
}

# Variáveis globais
var current_state = GameState.MENU
var player1_score = 0
var player2_score = 0
var player1_lines = 0
var player2_lines = 0
var player1_level = 1
var player2_level = 1
var winner = 0

# Power-ups ativos por jogador
var player1_active_power_ups = []
var player2_active_power_ups = []

# Sinais
signal game_started
signal game_over(winner)
signal power_up_sent(target_player_id, power_type, from_player_id)
signal lines_cleared(player_id, lines_count)
signal player_controls_mirrored(player_id, is_mirrored)

# Funções do jogo
func start_game():
	player1_score = 0
	player2_score = 0
	player1_lines = 0
	player2_lines = 0
	player1_level = 1
	player2_level = 1
	player1_active_power_ups = []
	player2_active_power_ups = []
	winner = 0
	current_state = GameState.PLAYING
	emit_signal("game_started")

func pause_game():
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED
	elif current_state == GameState.PAUSED:
		current_state = GameState.PLAYING

func end_game(player_id):
	winner = player_id
	current_state = GameState.GAME_OVER
	emit_signal("game_over", winner)

func add_score(player_id, points):
	if player_id == 1:
		player1_score += points
	else:
		player2_score += points

func add_lines(player_id, lines_count):
	if player_id == 1:
		player1_lines += lines_count
		player1_level = 1 + int(player1_lines / 10)
	else:
		player2_lines += lines_count
		player2_level = 1 + int(player2_lines / 10)
	
	emit_signal("lines_cleared", player_id, lines_count)

# Envia um power-up para o oponente
func send_power_up(from_player_id, power_type):
	var target_player_id = 1 if from_player_id == 2 else 2
	
	# Envia o power-up para o alvo
	emit_signal("power_up_sent", target_player_id, power_type, from_player_id)
	
	# Aplicar efeitos globais se necessário
	match power_type:
		PowerUpClass.Type.MIRROR:
			# Notifica o controlador do jogador para espelhar os controles
			emit_signal("player_controls_mirrored", target_player_id, true)
			
			# Programa para desativar o espelhamento depois do tempo
			var mirror_duration = 8.0  # Duração padrão do espelhamento
			await get_tree().create_timer(mirror_duration).timeout
			emit_signal("player_controls_mirrored", target_player_id, false)
		
		PowerUpClass.Type.BLOCK_SWAP:
			# A troca de peças é gerenciada dentro do TetrisGrid

# Para trocar peças entre os jogadores (usado pelo power-up BLOCK_SWAP)
func swap_player_pieces():
	var grids = get_tree().get_nodes_in_group("tetris_grid")
	
	if grids.size() < 2:
		return
	
	var grid1 = null
	var grid2 = null
	
	for grid in grids:
		if grid.player_id == 1:
			grid1 = grid
		elif grid.player_id == 2:
			grid2 = grid
	
	if grid1 != null and grid2 != null:
		var temp_piece = grid1.current_piece
		grid1.current_piece = grid2.current_piece.duplicate() if grid2.current_piece else null
		grid2.current_piece = temp_piece.duplicate() if temp_piece else null
		
		# Atualiza posições e visualização
		if grid1.current_piece:
			grid1.current_piece.position = Vector2i(GRID_WIDTH / 2 - 2, 0)
			grid1.update_ghost_piece()
		
		if grid2.current_piece:
			grid2.current_piece.position = Vector2i(GRID_WIDTH / 2 - 2, 0)
			grid2.update_ghost_piece()

func get_drop_speed(player_id):
	var level = player1_level if player_id == 1 else player2_level
	# A fórmula clássica do Tetris - quanto maior o nível, mais rápido as peças caem
	return max(0.1, 1.0 - (0.05 * (level - 1))) 