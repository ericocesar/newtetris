extends Node2D

# Sinais para eventos do jogo
signal game_started
signal game_paused
signal game_resumed
signal game_over(winner_id)
signal countdown_changed(count)

# Constantes do jogo
const COUNT_DURATION = 1.0
const COUNTDOWN_START = 3

# Estados do jogo
enum GameState {IDLE, COUNTDOWN, PLAYING, PAUSED, GAME_OVER}

# Variáveis do jogo
var current_state = GameState.IDLE
var countdown_value = COUNTDOWN_START
var countdown_timer = 0
var game_time = 0
var active_power_ups = {}

# Referências de nós
var player_controllers = []
var player_grids = []
var player_uis = []
var power_up_effects
var countdown_label
var game_over_panel
var game_over_winner_label

# Sistema de power-ups
var power_up_system

func _ready():
	# Obter referências aos nós
	player_controllers = [
		$Player1Area/PlayerController,
		$Player2Area/PlayerController
	]
	
	player_grids = [
		$Player1Area/TetrisGrid,
		$Player2Area/TetrisGrid
	]
	
	player_uis = [
		$Player1Area/PlayerUI,
		$Player2Area/PlayerUI
	]
	
	countdown_label = $CountdownLabel
	game_over_panel = $GameOverPanel
	game_over_winner_label = $GameOverPanel/WinnerLabel
	
	# Configurar jogadores
	for i in range(2):
		player_controllers[i].player_id = i
		player_grids[i].player_id = i
		player_uis[i].player_id = i
		
		# Conectar sinais
		player_controllers[i].tetromino_placed.connect(_on_tetromino_placed.bind(i))
		player_grids[i].lines_cleared.connect(_on_lines_cleared.bind(i))
		player_grids[i].game_over.connect(_on_player_game_over.bind(i))
	
	# Inicializar sistema de power-ups
	power_up_system = $PowerUpSystem
	power_up_system.setup(player_controllers, player_grids, player_uis)
	
	# Inicializar efeitos visuais de power-ups
	power_up_effects = $PowerUpEffects
	power_up_effects.setup(power_up_system, player_grids, player_uis)
	
	# Definir estado inicial e ocultar elementos UI
	reset_game()
	
	# Conectar botões do painel de Game Over
	$GameOverPanel/ButtonsContainer/ReplayButton.pressed.connect(_on_replay_button_pressed)
	$GameOverPanel/ButtonsContainer/MenuButton.pressed.connect(_on_menu_button_pressed)

func _process(delta):
	match current_state:
		GameState.COUNTDOWN:
			_process_countdown(delta)
		GameState.PLAYING:
			_process_gameplay(delta)
			
func _process_countdown(delta):
	countdown_timer -= delta
	
	if countdown_timer <= 0:
		if countdown_value > 1:
			# Próximo número na contagem regressiva
			countdown_value -= 1
			countdown_timer = COUNT_DURATION
			countdown_label.text = str(countdown_value)
			emit_signal("countdown_changed", countdown_value)
		else:
			# Iniciar o jogo quando a contagem chegar a zero
			countdown_label.text = "Começar!"
			yield(get_tree().create_timer(0.5), "timeout")
			countdown_label.visible = false
			current_state = GameState.PLAYING
			start_game()

func _process_gameplay(delta):
	game_time += delta
	
	# Atualizar tempo de jogo nas UIs
	for ui in player_uis:
		ui.update_time(game_time)
	
	# Lógica de atualização do jogo
	if current_state == GameState.PLAYING:
		# Verificar condições de spawn de power-up
		power_up_system.update(delta)

func start_countdown():
	current_state = GameState.COUNTDOWN
	countdown_value = COUNTDOWN_START
	countdown_timer = COUNT_DURATION
	countdown_label.text = str(countdown_value)
	countdown_label.visible = true
	emit_signal("countdown_changed", countdown_value)

func start_game():
	# Ativar controles dos jogadores
	for controller in player_controllers:
		controller.enable_controls()
	
	# Iniciar as grids
	for grid in player_grids:
		grid.start_game()
	
	# Atualizar as UIs
	for ui in player_uis:
		ui.reset_ui()
	
	current_state = GameState.PLAYING
	emit_signal("game_started")

func pause_game():
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED
		
		# Desativar controles dos jogadores
		for controller in player_controllers:
			controller.disable_controls()
		
		# Pausar as grids
		for grid in player_grids:
			grid.pause_game()
			
		emit_signal("game_paused")

func resume_game():
	if current_state == GameState.PAUSED:
		current_state = GameState.PLAYING
		
		# Reativar controles dos jogadores
		for controller in player_controllers:
			controller.enable_controls()
		
		# Retomar as grids
		for grid in player_grids:
			grid.resume_game()
			
		emit_signal("game_resumed")

func end_game(winner_id):
	current_state = GameState.GAME_OVER
	
	# Desativar controles dos jogadores
	for controller in player_controllers:
		controller.disable_controls()
	
	# Mostrar o painel de fim de jogo
	game_over_winner_label.text = "Jogador " + str(winner_id + 1) + " venceu!"
	game_over_panel.visible = true
	
	emit_signal("game_over", winner_id)

func reset_game():
	current_state = GameState.IDLE
	game_time = 0
	active_power_ups.clear()
	
	# Reiniciar jogadores
	for controller in player_controllers:
		controller.reset_controller()
		controller.disable_controls()
	
	for grid in player_grids:
		grid.reset_grid()
	
	for ui in player_uis:
		ui.reset_ui()
	
	# Reiniciar sistema de power-ups
	power_up_system.reset()
	
	# Ocultar elementos UI
	countdown_label.visible = false
	game_over_panel.visible = false

# Callbacks para eventos do jogo
func _on_tetromino_placed(player_id):
	player_uis[player_id].update_score(player_grids[player_id].score)
	player_uis[player_id].update_level(player_grids[player_id].level)

func _on_lines_cleared(num_lines, player_id):
	if num_lines > 0:
		# Atualizar UI
		player_uis[player_id].update_score(player_grids[player_id].score)
		player_uis[player_id].update_level(player_grids[player_id].level)
		
		# Verificar se deve gerar garbage lines para o oponente
		if num_lines >= 2:
			var opponent_id = 1 if player_id == 0 else 0
			var garbage_lines = num_lines - 1
			player_grids[opponent_id].add_garbage_lines(garbage_lines)

func _on_player_game_over(player_id):
	var winner_id = 1 if player_id == 0 else 0
	end_game(winner_id)

func _on_replay_button_pressed():
	reset_game()
	start_countdown()

func _on_menu_button_pressed():
	get_tree().change_scene("res://scenes/menu.tscn")

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if current_state == GameState.PLAYING:
			pause_game()
		elif current_state == GameState.PAUSED:
			resume_game() 