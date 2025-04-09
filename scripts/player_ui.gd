extends Control

# Sinais
signal power_up_activated(power_up_index)

# Referências à grade de Tetris e aos elementos da UI
@export var tetris_grid: Node2D
@export var player_id: int = 1

# Nós da interface
@onready var score_label = $ScoreLabel
@onready var level_label = $LevelLabel
@onready var power_meter_label = $PowerMeterLabel
@onready var next_piece_display = $NextPieceDisplay
@onready var held_piece_display = $HeldPieceDisplay
@onready var power_up_indicator = $PowerUpIndicator
@onready var power_ups_container = $PowerUpsContainer
@onready var power_up_slots = []  # Slots de power-ups
@onready var notification_label = $NotificationLabel
@onready var notification_timer = $NotificationTimer

# Referência aos scripts
var Tetromino = load("res://scripts/tetromino.gd")
const PowerUpClass = preload("res://scripts/power_up.gd")

# Constantes de exibição
const PREVIEW_CELL_SIZE = 20
const MAX_POWER_UPS = 3

# Variáveis de estado
var display_next_piece = null
var display_held_piece = null
var available_power_ups = []

# Cores para as diferentes peças
var piece_colors = {
	"I": Color("#00FFFF"), # Ciano
	"J": Color("#0000FF"), # Azul
	"L": Color("#FF7F00"), # Laranja
	"O": Color("#FFFF00"), # Amarelo
	"S": Color("#00FF00"), # Verde
	"T": Color("#800080"), # Roxo
	"Z": Color("#FF0000")  # Vermelho
}

# Referência ao sistema de power-ups
var power_up_system

# Inicialização
func _ready():
	# Conecta os sinais
	if tetris_grid:
		tetris_grid.connect("piece_locked", _on_piece_locked)
		tetris_grid.connect("power_up_used", _on_power_up_used)
		tetris_grid.connect("power_up_gained", _on_power_up_gained)
		tetris_grid.connect("power_up_received", _on_power_up_received)
		tetris_grid.connect("power_up_meter_updated", _on_power_up_meter_updated)
	
	# Configura o ID do jogador no texto
	var player_text = "Jogador " + str(player_id)
	$PlayerLabel.text = player_text
	
	# Inicializa slots de power-ups
	for i in range(MAX_POWER_UPS):
		var slot = power_ups_container.get_node("PowerUpSlot" + str(i+1))
		if slot:
			power_up_slots.append(slot)
			slot.modulate = Color(0.3, 0.3, 0.3, 0.5)  # Slot vazio é escuro
	
	# Inicializa a interface
	update_ui()

func _process(_delta):
	# Atualiza as informações em tempo real
	update_ui()
	
	# Redesenha as visualizações de peças
	next_piece_display.queue_redraw()
	held_piece_display.queue_redraw()

# Atualiza a interface com os valores atuais
func update_ui():
	if player_id == 1:
		score_label.text = "Pontos: " + str(GameManager.player1_score)
		level_label.text = "Nível: " + str(GameManager.player1_level)
	else:
		score_label.text = "Pontos: " + str(GameManager.player2_score)
		level_label.text = "Nível: " + str(GameManager.player2_level)
	
	# Atualiza a exibição de peças
	if tetris_grid:
		display_next_piece = tetris_grid.next_piece
		display_held_piece = tetris_grid.held_piece

# Atualiza a exibição de power-ups
func update_power_ups(power_ups):
	available_power_ups = power_ups
	
	# Limpa todos os slots
	for slot in power_up_slots:
		slot.modulate = Color(0.3, 0.3, 0.3, 0.5)  # Slot vazio
	
	# Preenche os slots com os power-ups disponíveis
	for i in range(min(power_ups.size(), power_up_slots.size())):
		var power_up = power_ups[i]
		var slot = power_up_slots[i]
		
		# Define a cor do slot baseado no tipo do power-up
		slot.modulate = power_up.get_color()
		
		# Adiciona texto ao slot com o nome do power-up
		var label = slot.get_node("Label") if slot.has_node("Label") else null
		if label:
			var power_name = ""
			match power_up.power_type:
				PowerUpClass.Type.CLEAR_ROWS:
					power_name = "LIMPAR"
				PowerUpClass.Type.SPEED_UP:
					power_name = "ACELERAR"
				PowerUpClass.Type.BLOCK_SWAP:
					power_name = "TROCAR"
				PowerUpClass.Type.MIRROR:
					power_name = "ESPELHAR"
				PowerUpClass.Type.TETRIS_BOMB:
					power_name = "BOMBA"
			
			label.text = power_name

# Desenha a próxima peça
func _on_next_piece_display_draw():
	if display_next_piece:
		draw_preview_piece(next_piece_display, display_next_piece)

# Desenha a peça guardada
func _on_held_piece_display_draw():
	if display_held_piece:
		draw_preview_piece(held_piece_display, display_held_piece)

# Função auxiliar para desenhar peças nas visualizações
func draw_preview_piece(canvas, piece):
	var shape = piece.get_shape()
	var color = piece.get_color()
	
	# Limpa o fundo
	var canvas_rect = Rect2(Vector2.ZERO, canvas.size)
	canvas.draw_rect(canvas_rect, Color(0.15, 0.15, 0.15, 1.0), true)
	
	# Centraliza a peça na visualização
	var offset_x = (canvas.size.x - 4 * PREVIEW_CELL_SIZE) / 2
	var offset_y = (canvas.size.y - 4 * PREVIEW_CELL_SIZE) / 2
	
	# Desenha a peça
	for y in range(4):
		for x in range(4):
			if shape[y][x] == 1:
				var pos_x = offset_x + x * PREVIEW_CELL_SIZE
				var pos_y = offset_y + y * PREVIEW_CELL_SIZE
				
				# Desenha o bloco
				canvas.draw_rect(Rect2(pos_x, pos_y, PREVIEW_CELL_SIZE, PREVIEW_CELL_SIZE), color, true)
				
				# Borda mais clara para efeito 3D
				var light_color = Color(min(color.r + 0.3, 1.0), min(color.g + 0.3, 1.0), min(color.b + 0.3, 1.0), color.a)
				var dark_color = Color(max(color.r - 0.3, 0.0), max(color.g - 0.3, 0.0), max(color.b - 0.3, 0.0), color.a)
				
				canvas.draw_line(Vector2(pos_x, pos_y), Vector2(pos_x + PREVIEW_CELL_SIZE, pos_y), light_color, 1.0)
				canvas.draw_line(Vector2(pos_x, pos_y), Vector2(pos_x, pos_y + PREVIEW_CELL_SIZE), light_color, 1.0)
				canvas.draw_line(Vector2(pos_x + PREVIEW_CELL_SIZE, pos_y), Vector2(pos_x + PREVIEW_CELL_SIZE, pos_y + PREVIEW_CELL_SIZE), dark_color, 1.0)
				canvas.draw_line(Vector2(pos_x, pos_y + PREVIEW_CELL_SIZE), Vector2(pos_x + PREVIEW_CELL_SIZE, pos_y + PREVIEW_CELL_SIZE), dark_color, 1.0)

# Callback quando uma peça é bloqueada na grade
func _on_piece_locked():
	update_ui()

# Callback quando o medidor de power-up é atualizado
func _on_power_up_meter_updated(value, threshold):
	power_meter_label.text = "Power: " + str(value) + "/" + str(threshold)
	
	# Atualiza a barra de progresso, se existir
	var progress_bar = $PowerMeterBar if has_node("PowerMeterBar") else null
	if progress_bar:
		progress_bar.max_value = threshold
		progress_bar.value = value

# Callback quando o jogador ganha um power-up
func _on_power_up_gained(power_type, player_id):
	if player_id == self.player_id:
		# Efeito visual
		show_power_up_effect(power_type, false) # false = não é recebido (é ganho)
		
		# Atualiza os slots
		if tetris_grid:
			update_power_ups(tetris_grid.available_power_ups)

# Callback quando um power-up é usado
func _on_power_up_used(power_type, player_id):
	if player_id == self.player_id:
		show_power_up_effect(power_type, false)
		
		# Atualiza os slots
		if tetris_grid:
			update_power_ups(tetris_grid.available_power_ups)

# Callback quando um power-up é recebido
func _on_power_up_received(power_type, from_player_id):
	if from_player_id != player_id:
		show_power_up_effect(power_type, true) # true = é recebido

# Mostra um efeito quando um power-up é usado ou recebido
func show_power_up_effect(power_type, is_received = false):
	var power_name = ""
	var power_color = Color.WHITE
	
	match power_type:
		PowerUpClass.Type.SPEED_UP:
			power_name = "ACELERAR" if !is_received else "ACELERADO!"
			power_color = Color(1.0, 0.8, 0.2)  # Amarelo
		PowerUpClass.Type.CLEAR_ROWS:
			power_name = "LIMPAR" if !is_received else "LINHAS LIMPAS!"
			power_color = Color(1.0, 0.3, 0.3)  # Vermelho
		PowerUpClass.Type.BLOCK_SWAP:
			power_name = "TROCAR" if !is_received else "PEÇAS TROCADAS!"
			power_color = Color(0.3, 0.7, 1.0)  # Azul
		PowerUpClass.Type.MIRROR:
			power_name = "ESPELHAR" if !is_received else "CONTROLES INVERTIDOS!"
			power_color = Color(0.8, 0.4, 1.0)  # Roxo
		PowerUpClass.Type.TETRIS_BOMB:
			power_name = "BOMBA" if !is_received else "BOMBA RECEBIDA!"
			power_color = Color(0.3, 1.0, 0.5)  # Verde
	
	# Atualiza o indicador de power-up
	power_up_indicator.text = power_name
	power_up_indicator.modulate = power_color
	
	# Inicia a animação
	$AnimationPlayer.stop()
	$AnimationPlayer.play("power_up_effect")

# Mostra efeito visual de espelhamento
func show_mirror_effect(is_mirrored):
	if is_mirrored:
		# Adiciona um efeito visual de espelhamento na UI
		$MirrorEffect.visible = true
		var tween = create_tween()
		tween.tween_property($MirrorEffect, "modulate", Color(0.8, 0.4, 1.0, 0.3), 0.5)
		tween.tween_property($MirrorEffect, "modulate", Color(0.8, 0.4, 1.0, 0.15), 0.5)
		tween.set_loops(8)  # 8 loops = ~8 segundos
	else:
		# Remove o efeito visual
		$MirrorEffect.visible = false 

# Configura a UI para o jogador específico
func setup(id: int):
	player_id = id
	update_score(0)
	update_level(1)
	clear_power_ups()
	
	# Atualiza o título baseado no ID do jogador
	$PlayerLabel.text = "Jogador " + str(player_id + 1)
	
	# Configura o timer de notificação
	notification_timer.one_shot = true
	notification_timer.timeout.connect(_on_notification_timer_timeout)
	notification_label.visible = false

# Atualiza a pontuação exibida
func update_score(score: int):
	score_label.text = str(score)

# Atualiza o nível exibido
func update_level(level: int):
	level_label.text = str(level)

# Atualiza a exibição da próxima peça
func update_next_tetromino(shape_data):
	# Limpa a exibição atual
	for child in next_piece_display.get_children():
		child.queue_free()
	
	if not shape_data:
		return
	
	var shape = shape_data.shape
	var shape_type = shape_data.type
	var color = piece_colors[shape_type]
	
	# Tamanho do bloco para a prévia
	var block_size = 16
	var grid_size = block_size * 4
	
	# Determina o offset com base no tipo da peça
	var offset_x = grid_size / 2 - block_size
	var offset_y = grid_size / 2 - block_size
	
	if shape_type == "I":
		offset_y -= block_size / 2
	elif shape_type == "O":
		offset_x -= block_size / 2
	
	# Cria os blocos da prévia
	for pos in shape:
		var block = ColorRect.new()
		block.size = Vector2(block_size, block_size)
		block.position = Vector2(
			offset_x + pos.x * block_size,
			offset_y + pos.y * block_size
		)
		block.color = color
		
		# Adiciona uma borda ao bloco
		var border = ReferenceRect.new()
		border.size = block.size
		border.border_color = Color(0, 0, 0, 0.3) # Borda preta semi-transparente
		border.border_width = 1.0
		border.editor_only = false
		block.add_child(border)
		
		next_piece_display.add_child(block)

# Adiciona um power-up à UI
func add_power_up(power_up_type):
	# Limita o número de power-ups a 3
	if available_power_ups.size() >= 3:
		return false
	
	# Adiciona à lista de power-ups disponíveis
	available_power_ups.append(power_up_type)
	
	# Atualiza a visualização dos power-ups
	update_power_up_display()
	
	return true

# Ativa um power-up específico
func activate_power_up(index):
	if index < 0 or index >= available_power_ups.size():
		return false
	
	# Emite sinal para ativar o power-up
	emit_signal("power_up_activated", index)
	
	return true

# Atualiza a exibição dos power-ups
func update_power_up_display():
	# Limpa os power-ups existentes
	for child in power_ups_container.get_children():
		child.queue_free()
	
	# Cria botões para cada power-up disponível
	for i in range(available_power_ups.size()):
		var power_up_type = available_power_ups[i]
		var button = Button.new()
		
		# Configurações do botão
		button.text = PowerUp.names[power_up_type]
		button.tooltip_text = PowerUp.descriptions[power_up_type]
		button.custom_minimum_size = Vector2(100, 40)
		button.add_theme_color_override("font_color", Color.WHITE)
		button.add_theme_color_override("font_hover_color", Color.YELLOW)
		
		# Estilo do botão
		var style = StyleBoxFlat.new()
		style.bg_color = PowerUp.colors[power_up_type]
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color.WHITE
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		
		button.add_theme_stylebox_override("normal", style)
		
		# Conecta o sinal de clique do botão
		button.pressed.connect(func(): _on_power_up_button_pressed(i))
		
		# Adiciona o botão ao contêiner
		power_ups_container.add_child(button)

# Limpa todos os power-ups
func clear_power_ups():
	available_power_ups.clear()
	
	for child in power_ups_container.get_children():
		child.queue_free()

# Remove um power-up específico da lista
func remove_power_up(index):
	if index >= 0 and index < available_power_ups.size():
		available_power_ups.remove_at(index)
		update_power_up_display()
		return true
	return false

# Exibe uma notificação temporária
func show_notification(text: String, duration: float = 2.0):
	notification_label.text = text
	notification_label.visible = true
	
	# Configura uma animação para a notificação
	var tween = create_tween()
	notification_label.modulate.a = 0
	tween.tween_property(notification_label, "modulate:a", 1.0, 0.3)
	
	# Inicia o timer para esconder a notificação
	notification_timer.wait_time = duration
	notification_timer.start()

# Exibe uma notificação de power-up
func show_power_up_notification(power_up_type, target_is_self: bool = false):
	var power_up_name = PowerUp.names[power_up_type]
	var text = "Ativou " + power_up_name
	
	if target_is_self:
		text += " (em você)"
	else:
		text += " (no oponente)"
	
	show_notification(text, 3.0)

# Manipula cliques nos botões de power-up
func _on_power_up_button_pressed(index):
	if activate_power_up(index):
		# O power-up foi ativado, a remoção será tratada pelo sistema de power-ups
		pass

# Esconde a notificação quando o timer expirar
func _on_notification_timer_timeout():
	var tween = create_tween()
	tween.tween_property(notification_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): notification_label.visible = false)

# Função para atualizar os power-ups disponíveis
func update_available_power_ups(power_ups):
	available_power_ups = power_ups
	update_power_up_display()

# Processar entrada de teclado para ativar power-ups
func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if player_id == 0 and event.keycode == KEY_E:
			# Jogador 1 - tecla E
			if available_power_ups.size() > 0:
				activate_power_up(0)  # Ativa o primeiro power-up disponível
		elif player_id == 1 and event.keycode == KEY_SHIFT:
			# Jogador 2 - tecla Shift
			if available_power_ups.size() > 0:
				activate_power_up(0)  # Ativa o primeiro power-up disponível 