extends Control

# Referências a nós
@onready var title_label = $TitleLabel
@onready var start_button = $VBoxContainer/StartButton
@onready var controls_button = $VBoxContainer/ControlsButton
@onready var quit_button = $VBoxContainer/QuitButton
@onready var controls_panel = $ControlsPanel
@onready var back_button = $ControlsPanel/BackButton

# Variáveis de animação
var title_animation_time = 0

# Inicialização
func _ready():
	# Esconder o painel de controles inicialmente
	controls_panel.visible = false
	
	# Conectar sinais de botões
	start_button.connect("pressed", _on_start_button_pressed)
	controls_button.connect("pressed", _on_controls_button_pressed)
	quit_button.connect("pressed", _on_quit_button_pressed)
	back_button.connect("pressed", _on_back_button_pressed)
	
	# Inicializar o Gerenciador de Jogo no estado de menu
	GameManager.current_state = GameManager.GameState.MENU

# Loop principal para animações
func _process(delta):
	# Animação simples do título
	title_animation_time += delta
	title_label.modulate = Color(
		1.0, 
		0.5 + 0.5 * sin(title_animation_time * 2), 
		0.5 + 0.5 * sin(title_animation_time * 1.5),
		1.0
	)

# Botão de iniciar o jogo
func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://scenes/game.tscn")

# Botão de controles
func _on_controls_button_pressed():
	controls_panel.visible = true

# Botão de sair
func _on_quit_button_pressed():
	get_tree().quit()

# Botão de voltar dos controles
func _on_back_button_pressed():
	controls_panel.visible = false 