extends Control

# Referências a nós
@onready var player1_grid = $Player1Area/TetrisGrid
@onready var player2_grid = $Player2Area/TetrisGrid
@onready var countdown_label = $CountdownLabel
@onready var game_over_panel = $GameOverPanel
@onready var winner_label = $GameOverPanel/WinnerLabel
@onready var player1_controller = $Player1Controller
@onready var player2_controller = $Player2Controller

# Variáveis de estado
var countdown_time = 3
var countdown_timer = 0
var is_countdown_active = false

# Inicialização
func _ready():
	# Configurar os IDs dos jogadores
	player1_grid.player_id = 1
	player2_grid.player_id = 2
	
	# Conectar sinais
	player1_grid.connect("game_over", _on_player1_game_over)
	player2_grid.connect("game_over", _on_player2_game_over)
	
	# Esconder o painel de game over
	game_over_panel.visible = false
	
	# Iniciar o jogo com contagem regressiva
	start_countdown()

# Loop principal
func _process(delta):
	if is_countdown_active:
		countdown_timer -= delta
		
		if countdown_timer <= 0:
			if countdown_time > 0:
				countdown_time -= 1
				countdown_timer = 1
				update_countdown_display()
			else:
				is_countdown_active = false
				countdown_label.visible = false
				GameManager.start_game()

# Inicia a contagem regressiva para o jogo
func start_countdown():
	is_countdown_active = true
	countdown_time = 3
	countdown_timer = 1
	countdown_label.visible = true
	update_countdown_display()

# Atualiza o display da contagem regressiva
func update_countdown_display():
	if countdown_time > 0:
		countdown_label.text = str(countdown_time)
	else:
		countdown_label.text = "VAI!"

# Callback quando o jogador 1 perde
func _on_player1_game_over():
	# O jogador 2 ganha
	GameManager.end_game(2)

# Callback quando o jogador 2 perde
func _on_player2_game_over():
	# O jogador 1 ganha
	GameManager.end_game(1)

# Callback quando o jogo termina
func _on_game_over(winner_id):
	game_over_panel.visible = true
	
	if winner_id == 1:
		winner_label.text = "Jogador 1 Venceu!"
	else:
		winner_label.text = "Jogador 2 Venceu!"

# Callback para o botão de jogar novamente
func _on_play_again_button_pressed():
	game_over_panel.visible = false
	start_countdown()

# Callback para o botão de menu principal
func _on_main_menu_button_pressed():
	get_tree().change_scene_to_file("res://scenes/menu.tscn") 