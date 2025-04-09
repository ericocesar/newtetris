extends Node

# Referência ao sistema de power-ups
var power_up_system

# Referências aos grids dos jogadores
var player_grids = []

# Referências às áreas de UI dos jogadores
var player_uis = []

# Referências aos controladores dos jogadores
var player_controllers = []

# Efeitos visuais para cada tipo de power-up
var visual_effects = {}

# Sistema de partículas para efeitos
var particle_effects = {}

# Sprites para indicadores de power-ups
var power_up_indicators = {}

# Sinais
signal effect_started(player_id, effect_type)
signal effect_ended(player_id, effect_type)

# Inicializa o sistema de efeitos
func _ready():
	# Será configurado pelo gerenciador de jogo
	pass

# Configura o sistema com as referências necessárias
func setup(p_power_up_system, p_player_grids, p_player_uis, p_player_controllers):
	power_up_system = p_power_up_system
	player_grids = p_player_grids
	player_uis = p_player_uis
	player_controllers = p_player_controllers
	
	# Conecta sinais do sistema de power-ups
	power_up_system.power_up_activated.connect(_on_power_up_activated)
	power_up_system.power_up_ended.connect(_on_power_up_ended)
	power_up_system.power_up_available.connect(_on_power_up_available)
	
	# Inicializa containers para efeitos visuais
	_setup_visual_effects()

# Configura os efeitos visuais para cada tipo de power-up
func _setup_visual_effects():
	var PowerUpType = power_up_system.PowerUpType
	
	# Cria indicadores para cada jogador
	for i in range(2):
		power_up_indicators[i] = {}
		visual_effects[i] = {}
		particle_effects[i] = {}
	
	# Configura efeitos visuais específicos para cada power-up
	# Esses serão aplicados quando o power-up for ativado
	for i in range(2):
		# CLEAR_LINE - Flash na linha removida
		visual_effects[i][PowerUpType.CLEAR_LINE] = func():
			var flash = ColorRect.new()
			flash.color = Color(1, 1, 1, 0.7)
			flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
			player_grids[i].add_child(flash)
			flash.size = player_grids[i].size
			flash.position = Vector2.ZERO
			
			var tween = create_tween()
			tween.tween_property(flash, "color:a", 0, 0.5)
			tween.tween_callback(flash.queue_free)
		
		# SPEED_UP - Borda pulsante vermelha
		visual_effects[i][PowerUpType.SPEED_UP] = func():
			var border = _create_border(player_grids[i], Color(1, 0, 0, 0.7))
			var tween = create_tween()
			tween.set_loops()
			tween.tween_property(border, "modulate:a", 0.3, 0.5)
			tween.tween_property(border, "modulate:a", 0.7, 0.5)
			
			return [border, tween]
		
		# SPEED_DOWN - Borda pulsante azul
		visual_effects[i][PowerUpType.SPEED_DOWN] = func():
			var border = _create_border(player_grids[i], Color(0, 0, 1, 0.7))
			var tween = create_tween()
			tween.set_loops()
			tween.tween_property(border, "modulate:a", 0.3, 0.5)
			tween.tween_property(border, "modulate:a", 0.7, 0.5)
			
			return [border, tween]
		
		# BLOCK_ROTATION - Ícone de rotação bloqueada
		visual_effects[i][PowerUpType.BLOCK_ROTATION] = func():
			var icon = _create_block_icon(player_grids[i], "rotation_blocked")
			var tween = create_tween()
			tween.set_loops()
			tween.tween_property(icon, "modulate:a", 0.5, 0.5)
			tween.tween_property(icon, "modulate:a", 1.0, 0.5)
			
			return [icon, tween]
		
		# BLOCK_MOVEMENT - Ícone de movimento bloqueado
		visual_effects[i][PowerUpType.BLOCK_MOVEMENT] = func():
			var icon = _create_block_icon(player_grids[i], "movement_blocked")
			var tween = create_tween()
			tween.set_loops()
			tween.tween_property(icon, "modulate:a", 0.5, 0.5)
			tween.tween_property(icon, "modulate:a", 1.0, 0.5)
			
			return [icon, tween]
		
		# FLIP_CONTROLS - Invertendo controles (efeito de rotação)
		visual_effects[i][PowerUpType.FLIP_CONTROLS] = func():
			var icon = _create_block_icon(player_grids[i], "controls_flipped")
			var tween = create_tween()
			tween.set_loops()
			tween.tween_property(icon, "rotation_degrees", 180, 1.0)
			tween.tween_property(icon, "rotation_degrees", 0, 1.0)
			
			return [icon, tween]
		
		# GARBAGE_LINES - Efeito de lixo caindo
		visual_effects[i][PowerUpType.GARBAGE_LINES] = func():
			var particles = _create_particles(player_grids[i], Color(0.5, 0.5, 0.5))
			particles.emitting = true
			
			var timer = Timer.new()
			timer.wait_time = 2.0
			timer.one_shot = true
			timer.timeout.connect(func(): 
				particles.emitting = false
				particles.queue_free()
				timer.queue_free()
			)
			add_child(timer)
			timer.start()
			
			return [particles]
		
		# RANDOM_BLOCKS - Efeito de blocos coloridos
		visual_effects[i][PowerUpType.RANDOM_BLOCKS] = func():
			var particles = _create_particles(player_grids[i], Color(1, 0.5, 0))
			particles.emitting = true
			
			return [particles]
		
		# INSTANT_DROP - Flash rápido na tela
		visual_effects[i][PowerUpType.INSTANT_DROP] = func():
			var flash = ColorRect.new()
			flash.color = Color(1, 1, 0, 0.5)
			flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
			player_grids[i].add_child(flash)
			flash.size = player_grids[i].size
			flash.position = Vector2.ZERO
			
			var tween = create_tween()
			tween.tween_property(flash, "color:a", 0, 0.3)
			tween.tween_callback(flash.queue_free)

# Manipula a ativação de um power-up
func _on_power_up_activated(player_id, power_up_type, target_player_id):
	# Exibe o efeito visual
	_show_power_up_effect(target_player_id, power_up_type)
	
	# Exibe uma notificação na UI do jogador que usou o power-up
	_show_power_up_notification(player_id, power_up_type, target_player_id)
	
	emit_signal("effect_started", target_player_id, power_up_type)

# Manipula o término de um power-up
func _on_power_up_ended(player_id, power_up_type, target_player_id):
	# Remove o efeito visual
	_hide_power_up_effect(target_player_id, power_up_type)
	
	emit_signal("effect_ended", target_player_id, power_up_type)

# Manipula um power-up disponível
func _on_power_up_available(player_id, power_up_type):
	# Exibe o power-up na UI do jogador
	if player_uis[player_id]:
		player_uis[player_id].add_power_up(power_up_type)

# Exibe o efeito visual de um power-up
func _show_power_up_effect(player_id, power_up_type):
	if not player_id in visual_effects or not power_up_type in visual_effects[player_id]:
		return
		
	# Remove efeito anterior se existir
	_hide_power_up_effect(player_id, power_up_type)
	
	# Chama a função de efeito visual
	var effect_result = visual_effects[player_id][power_up_type].call()
	
	# Se a função retornou objetos para rastrear, salva-os
	if effect_result is Array:
		particle_effects[player_id][power_up_type] = effect_result

# Remove o efeito visual de um power-up
func _hide_power_up_effect(player_id, power_up_type):
	if not player_id in particle_effects:
		return
		
	if power_up_type in particle_effects[player_id]:
		var effects = particle_effects[player_id][power_up_type]
		for effect in effects:
			if effect is Node and is_instance_valid(effect):
				effect.queue_free()
			elif effect is Tween and effect.is_running():
				effect.kill()
				
		particle_effects[player_id].erase(power_up_type)

# Exibe uma notificação na UI do jogador
func _show_power_up_notification(player_id, power_up_type, target_player_id):
	if player_uis[player_id]:
		var power_up_name = power_up_system.get_power_up_name(power_up_type)
		var target_text = "no Oponente" if player_id != target_player_id else "em Você"
		player_uis[player_id].show_notification("Ativou " + power_up_name + " " + target_text)

# Criar uma borda ao redor de um nó
func _create_border(target_node, color):
	var border = Line2D.new()
	border.width = 4
	border.default_color = color
	
	var size = target_node.size
	border.points = [
		Vector2(0, 0),
		Vector2(size.x, 0),
		Vector2(size.x, size.y),
		Vector2(0, size.y),
		Vector2(0, 0)
	]
	
	target_node.add_child(border)
	return border

# Criar um ícone de bloqueio
func _create_block_icon(target_node, icon_type):
	var icon = TextureRect.new()
	
	# Idealmente, carregaria um sprite aqui, mas por enquanto vamos criar um placeholder
	var icon_size = min(target_node.size.x, target_node.size.y) * 0.3
	
	icon.size = Vector2(icon_size, icon_size)
	icon.position = target_node.size / 2 - icon.size / 2
	icon.modulate = Color(1, 1, 1, 0.8)
	
	# Criar um ColorRect como placeholder
	var placeholder = ColorRect.new()
	placeholder.size = icon.size
	
	# Diferentes cores para diferentes ícones
	match icon_type:
		"rotation_blocked":
			placeholder.color = Color(1, 0, 0, 0.5)
		"movement_blocked":
			placeholder.color = Color(0, 0, 1, 0.5)
		"controls_flipped":
			placeholder.color = Color(1, 0.5, 0, 0.5)
		_:
			placeholder.color = Color(1, 1, 1, 0.5)
	
	icon.add_child(placeholder)
	target_node.add_child(icon)
	return icon

# Criar um sistema de partículas
func _create_particles(target_node, color):
	var particles = CPUParticles2D.new()
	
	particles.amount = 20
	particles.lifetime = 1.0
	particles.explosiveness = 0.2
	particles.randomness = 0.5
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(target_node.size.x / 2, 5)
	
	particles.gravity = Vector2(0, 200)
	particles.initial_velocity_min = 50
	particles.initial_velocity_max = 100
	particles.scale_amount = 4
	
	particles.color = color
	
	particles.position = Vector2(target_node.size.x / 2, 0)
	target_node.add_child(particles)
	
	return particles

# Limpa todos os efeitos visuais
func clear_all_effects():
	for player_id in particle_effects:
		for power_up_type in particle_effects[player_id].keys():
			_hide_power_up_effect(player_id, power_up_type) 