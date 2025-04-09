extends Node

class_name GameManager

# Sinais
signal game_started
signal game_over(player_id)
signal player_scored(player_id, points, total_score)
signal level_up(player_id, level)
signal countdown_updated(count)

# Constantes
const MAX_LEVEL = 15
const LINES_PER_LEVEL = 10
const POWER_UP_CHANCE = 0.2  # 20% de chance para power up em cada peça
const COUNTDOWN_START = 3

# Enums
enum GameState { MENU, COUNTDOWN, PLAYING, PAUSED, GAME_OVER }

# Estados
var game_state = GameState.MENU
var countdown_value = COUNTDOWN_START
var countdown_timer = 0.0

# Jogadores
var player_data = {
	1: {
		"score": 0,
		"lines": 0,
		"level": 1,
		"active_tetromino": null,
		"next_tetromino": null
	},
	2: {
		"score": 0,
		"lines": 0,
		"level": 1,
		"active_tetromino": null,
		"next_tetromino": null
	}
}

# Referências a outros nós
var player_grids = {}
var player_controllers = {}
var player_uis = {}
var power_up_system = null
var visual_effects = null

# Nós da cena
@onready var countdown_label = $UI/CountdownLabel
@onready var game_over_panel = $UI/GameOverPanel
@onready var countdown_timer_node = $CountdownTimer
@onready var bg_music = $BackgroundMusic
@onready var game_over_sound = $GameOverSound
@onready var level_up_sound = $LevelUpSound

# Inicialização
func _ready():
	randomize()
	countdown_label.visible = false
	game_over_panel.visible = false
	set_process(false)

# Configura o jogo
func setup(p1_grid, p2_grid, p1_controller, p2_controller, p1_ui, p2_ui, power_up_sys, effects):
	# Armazena referências aos nós importantes
	player_grids = {
		1: p1_grid,
		2: p2_grid
	}
	
	player_controllers = {
		1: p1_controller,
		2: p2_controller
	}
	
	player_uis = {
		1: p1_ui,
		2: p2_ui
	}
	
	power_up_system = power_up_sys
	visual_effects = effects
	
	# Configura as grades dos jogadores
	for player_id in player_grids.keys():
		var grid = player_grids[player_id]
		grid.player_id = player_id
		grid.connect("game_over", _on_grid_game_over)
	
	# Configura os controles dos jogadores
	for player_id in player_controllers.keys():
		var controller = player_controllers[player_id]
		controller.player_id = player_id
		controller.connect("tetromino_settled", _on_tetromino_settled)
		controller.connect("power_up_activated", _on_power_up_activated)
	
	# Configura as UIs dos jogadores
	for player_id in player_uis.keys():
		var ui = player_uis[player_id]
		ui.player_id = player_id
		ui.update_score(0)
		ui.update_level(1)
		ui.update_lines(0)
	
	# Configura o sistema de power-ups
	if power_up_system:
		power_up_system.setup(player_grids, player_controllers)
	
	# Configura o sistema de efeitos visuais
	if visual_effects:
		visual_effects.setup(power_up_system, player_grids, player_uis)
	
	# Escuta sinais adicionais
	countdown_timer_node.timeout.connect(_on_countdown_timeout)

# Inicia um novo jogo
func start_game():
	# Reinicia dados dos jogadores
	for player_id in player_data.keys():
		player_data[player_id].score = 0
		player_data[player_id].lines = 0
		player_data[player_id].level = 1
		
		# Atualiza UIs
		if player_uis.has(player_id):
			player_uis[player_id].update_score(0)
			player_uis[player_id].update_level(1)
			player_uis[player_id].update_lines(0)
		
		# Limpa grades
		if player_grids.has(player_id):
			player_grids[player_id].clear_grid()
	
	# Inicia contagem regressiva
	game_state = GameState.COUNTDOWN
	countdown_value = COUNTDOWN_START
	countdown_label.text = str(countdown_value)
	countdown_label.visible = true
	countdown_timer_node.start()
	
	# Inicia música
	if bg_music and !bg_music.playing:
		bg_music.play()
	
	emit_signal("countdown_updated", countdown_value)
	set_process(true)

# Inicia a jogabilidade após a contagem regressiva
func start_gameplay():
	game_state = GameState.PLAYING
	countdown_label.visible = false
	
	# Gera peças iniciais para os jogadores
	for player_id in player_data.keys():
		spawn_next_tetromino(player_id)
		spawn_active_tetromino(player_id)
		
		# Ativa controladores
		if player_controllers.has(player_id):
			player_controllers[player_id].enable_input(true)
	
	emit_signal("game_started")

# Pausa o jogo
func pause_game():
	if game_state == GameState.PLAYING:
		game_state = GameState.PAUSED
		for player_id in player_controllers.keys():
			player_controllers[player_id].enable_input(false)
		
		# Pausar música se estiver tocando
		if bg_music and bg_music.playing:
			bg_music.stream_paused = true

# Retoma o jogo
func resume_game():
	if game_state == GameState.PAUSED:
		game_state = GameState.PLAYING
		for player_id in player_controllers.keys():
			player_controllers[player_id].enable_input(true)
		
		# Retoma música se estiver pausada
		if bg_music and bg_music.stream_paused:
			bg_music.stream_paused = false

# Finaliza o jogo para um jogador
func end_game(player_id):
	game_state = GameState.GAME_OVER
	
	# Desativa controladores
	for id in player_controllers.keys():
		player_controllers[id].enable_input(false)
	
	# Mostra o painel de fim de jogo
	game_over_panel.visible = true
	
	# Toca som de game over
	if game_over_sound:
		game_over_sound.play()
	
	emit_signal("game_over", player_id)

# Gera uma nova peça ativa para o jogador
func spawn_active_tetromino(player_id):
	if !player_data.has(player_id) or !player_grids.has(player_id) or !player_controllers.has(player_id):
		return
	
	var grid = player_grids[player_id]
	var controller = player_controllers[player_id]
	
	# Usa a próxima peça como ativa
	var shape_type = player_data[player_id].next_tetromino
	
	# Posição inicial (centro da grade no topo)
	var start_x = int(grid.grid_width / 2) - 2
	var start_position = Vector2i(start_x, 0)
	
	# Cria o tetromino
	var tetromino = preload("res://scripts/tetromino.gd").new()
	add_child(tetromino)
	tetromino.player_id = player_id
	
	# Ajusta velocidade de queda com base no nível
	var fall_speed = get_fall_speed_for_level(player_data[player_id].level)
	tetromino.fall_speed = fall_speed
	
	# Inicializa e conecta o tetromino
	tetromino.initialize(shape_type, grid, start_position)
	controller.connect_tetromino(tetromino)
	
	# Atualiza a referência no player_data
	player_data[player_id].active_tetromino = tetromino
	
	# Gera a próxima peça
	spawn_next_tetromino(player_id)

# Gera a próxima peça para o jogador
func spawn_next_tetromino(player_id):
	if !player_data.has(player_id) or !player_uis.has(player_id):
		return
	
	# Escolhe uma forma aleatória
	var shape_type = randi() % 7  # 7 tipos de tetrominos
	
	# Atualiza a próxima peça no player_data
	player_data[player_id].next_tetromino = shape_type
	
	# Atualiza a UI do jogador
	player_uis[player_id].update_next_piece(shape_type)

# Processa pontuação quando linhas são limpas
func process_score(player_id, lines_cleared, is_tetris):
	if !player_data.has(player_id) or !player_uis.has(player_id):
		return
	
	var points = 0
	
	# Sistema de pontuação baseado no número de linhas e nível
	var level = player_data[player_id].level
	
	match lines_cleared:
		1: points = 100 * level  # Single
		2: points = 300 * level  # Double
		3: points = 500 * level  # Triple
		4: points = 800 * level  # Tetris
		_: points = 0
	
	# Bônus para Tetris
	if is_tetris:
		points += 400 * level  # Bônus adicional por Tetris
	
	# Atualiza os dados do jogador
	player_data[player_id].score += points
	player_data[player_id].lines += lines_cleared
	
	# Verifica se subiu de nível
	var lines_total = player_data[player_id].lines
	var new_level = min(MAX_LEVEL, 1 + int(lines_total / LINES_PER_LEVEL))
	
	if new_level > player_data[player_id].level:
		player_data[player_id].level = new_level
		emit_signal("level_up", player_id, new_level)
		
		# Atualiza a velocidade da peça ativa
		if player_data[player_id].active_tetromino:
			var fall_speed = get_fall_speed_for_level(new_level)
			player_data[player_id].active_tetromino.set_fall_speed(fall_speed)
		
		# Toca som de level up
		if level_up_sound:
			level_up_sound.play()
	
	# Atualiza a UI
	player_uis[player_id].update_score(player_data[player_id].score)
	player_uis[player_id].update_level(player_data[player_id].level)
	player_uis[player_id].update_lines(player_data[player_id].lines)
	
	# Emite sinal de pontuação
	emit_signal("player_scored", player_id, points, player_data[player_id].score)

# Calcula a velocidade de queda com base no nível
func get_fall_speed_for_level(level):
	# Fórmula para velocidade de queda: quanto maior o nível, menor o tempo de queda
	return max(0.1, 1.0 - ((level - 1) * 0.05))

# Verifica se deve gerar um power-up
func should_generate_power_up():
	return randf() < POWER_UP_CHANCE

# Processa a contagem regressiva
func _process(delta):
	if game_state == GameState.COUNTDOWN:
		countdown_timer += delta
		
		# Animação de scala para a label
		var scale_value = 1.0 + sin(countdown_timer * 10) * 0.2
		countdown_label.scale = Vector2(scale_value, scale_value)

# Callbacks
func _on_countdown_timeout():
	countdown_value -= 1
	
	if countdown_value > 0:
		countdown_label.text = str(countdown_value)
		emit_signal("countdown_updated", countdown_value)
		countdown_timer_node.start()
	else:
		countdown_label.text = "Começar!"
		emit_signal("countdown_updated", 0)
		
		# Espera um breve momento e inicia o jogo
		await get_tree().create_timer(0.5).timeout
		start_gameplay()

func _on_tetromino_settled(player_id):
	if game_state != GameState.PLAYING:
		return
	
	# Verifica se o jogador deve receber um power-up
	if should_generate_power_up() and power_up_system:
		var power_up_type = power_up_system.generate_random_power_up(player_id)
		player_uis[player_id].add_power_up(power_up_type)
	
	# Gera nova peça
	spawn_active_tetromino(player_id)

func _on_power_up_activated(type, player_id, target_player_id):
	if game_state != GameState.PLAYING or !power_up_system:
		return
	
	# Aplica o power-up
	power_up_system.apply_power_up(type, player_id, target_player_id)

func _on_grid_game_over(player_id):
	end_game(player_id)

# Funções para botões da UI
func _on_restart_button_pressed():
	game_over_panel.visible = false
	start_game()

func _on_main_menu_button_pressed():
	game_over_panel.visible = false
	game_state = GameState.MENU
	
	# Parar a música
	if bg_music and bg_music.playing:
		bg_music.stop()
	
	# Mudar para a cena do menu (isso pode variar dependendo da estrutura)
	get_tree().change_scene_to_file("res://scenes/menu.tscn") 