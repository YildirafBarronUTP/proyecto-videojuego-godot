extends Cpu
class_name JefeNivel1

@export_category("Estadísticas del Jefe")
@export var hp_maximo: int = 1
@export var tiempo_entre_ataques: float = 1.0

@export_category("Ataque Especial")
@export var tiempo_recarga_especial: float = 15.0
var timer_ataque_especial: float = 3.0

@export var escena_fuego_jefe: PackedScene
@onready var sonido_pasos: AudioStreamPlayer2D = $SonidoPasos
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var colision: CollisionShape2D = $CollisionShape2D
@onready var rayo_ataque: RayCast2D = $RayCast2D
@onready var sonido_carga_fuego: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
@onready var sonido_fuego_cruz: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
@onready var sonido_golpe_martillo: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
@onready var sonido_risa: AudioStreamPlayer2D = AudioStreamPlayer2D.new()

var esta_muerto: bool = false
var esta_atacando: bool = false
var puede_atacar: bool = true

var ultima_posicion_registro: Vector2 = Vector2.ZERO
var tiempo_atascado: float = 0.0
@export var limite_tiempo_atascado: float = 0.15

var timer_impulso: float = 0.0
@export var duracion_impulso: float = 0.15 
var direccion_pulso_actual: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("enemigos")
	add_to_group("jefe_verdugo")
	
	velocidad = 280.0
	vidas = hp_maximo
	
	sonido_pasos.volume_db = 5.0
	sonido_pasos.max_distance = 4000.0
	
	sprite.animation_finished.connect(_on_animation_finished)
	
	if sonido_pasos.finished.is_connected(_on_paso_terminado):
		sonido_pasos.finished.disconnect(_on_paso_terminado)
	sonido_pasos.finished.connect(_on_paso_terminado)
	
	# Inyección nativa de audios 2D
	sonido_carga_fuego.stream = load("res://sounds/soundtrack/Nivel1/cargar_fuego.wav")
	sonido_carga_fuego.volume_db = 4.0
	sonido_carga_fuego.max_distance = 3500.0
	add_child(sonido_carga_fuego)
	
	sonido_fuego_cruz.stream = load("res://sounds/soundtrack/Nivel1/fuego_cruz.wav")
	sonido_fuego_cruz.volume_db = 5.0
	sonido_fuego_cruz.max_distance = 3500.0
	add_child(sonido_fuego_cruz)
	
	sonido_golpe_martillo.stream = load("res://sounds/soundtrack/Nivel1/golpe_martillo.wav")
	sonido_golpe_martillo.volume_db = 6.0 
	sonido_golpe_martillo.max_distance = 3000.0
	add_child(sonido_golpe_martillo)
	
	sonido_risa.volume_db = 5.0
	sonido_risa.max_distance = 3500.0
	add_child(sonido_risa)
	
	await get_tree().create_timer(1.3).timeout
	
	var nodo_mapa = get_parent().get_node_or_null("lvl1_MapaProcedural")
	if nodo_mapa:
		print("Jefe: Configurando sistema A* autónomo para el Nivel 1...")
		astar = AStarGrid2D.new()
		astar.region = Rect2i(0, 0, 15, 13)
		astar.cell_size = Vector2(128, 128)
		astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
		astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
		astar.update()
		
		actualizar_malla_obstaculos_procedurales(nodo_mapa)
		print("Jefe: Sistema A* autónomo inicializado con éxito.")
	
	if astar != null:
		actualizar_mapa_peligro()
		tomar_decision()

func tomar_decision() -> void:
	if esta_atacando or esta_muerto: return

	var mi_celda = pos_a_celda(global_position)
	
	# Evasión de bombas del jugador
	if mi_celda in radio_peligro:
		estado_actual = EstadoIA.HUIR
		if celda_objetivo_final != Vector2i(-1, -1) and not celda_objetivo_final in radio_peligro:
			return 
		buscar_casilla_segura(mi_celda)
		return
		
	if estado_actual == EstadoIA.HUIR and not mi_celda in radio_peligro:
		camino_actual.clear()
		celda_objetivo_final = Vector2i(-1, -1)
		estado_actual = EstadoIA.IDLE
		alinear_al_centro() 
		return

	# ENFOQUE ÚNICO: Caza y persecución implacable del jugador
	var victima = buscar_entidad_mas_cercana("jugadores", mi_celda, true)
	if victima != null:
		estado_actual = EstadoIA.ATACAR
		intentar_acorralar(mi_celda, pos_a_celda(victima.global_position))
		return 
		
	estado_actual = EstadoIA.IDLE

func intentar_acorralar(mi_celda: Vector2i, celda_victima: Vector2i) -> void:
	# Si ya tenemos al jugador como objetivo final de ruta y nos estamos moviendo, evitamos recalcular innecesariamente
	if celda_objetivo_final == celda_victima and not camino_actual.is_empty():
		return 

	# 35% de probabilidad de intentar flanquear de forma inteligente por sus costados
	if randi() % 100 < 35: 
		var opciones_flanqueo = [
			celda_victima + Vector2i.UP, celda_victima + Vector2i.DOWN, 
			celda_victima + Vector2i.LEFT, celda_victima + Vector2i.RIGHT
		]
		opciones_flanqueo.shuffle()
		
		for ady in opciones_flanqueo:
			if ady.x >= 0 and ady.x < 15 and ady.y >= 0 and ady.y < 13:
				if not astar.is_point_solid(ady) and not ady in radio_peligro:
					trazar_ruta(mi_celda, ady)
					return
	
	# 65% de probabilidad de ir directo por él
	if celda_victima.x >= 0 and celda_victima.x < 15 and celda_victima.y >= 0 and celda_victima.y < 13:
		trazar_ruta(mi_celda, celda_victima)

func alinear_al_centro() -> void:
	var mi_celda = pos_a_celda(global_position)
	global_position = celda_a_pos(mi_celda)

func actualizar_mapa_peligro() -> void:
	radio_peligro.clear()
	
	var bombas = get_tree().get_nodes_in_group("bombas")
	for bomba in bombas:
		var celda_bomba = pos_a_celda(bomba.global_position)
		var poder = bomba.poder_explosion if "poder_explosion" in bomba else 2
		
		if celda_bomba.x >= 0 and celda_bomba.x < 15 and celda_bomba.y >= 0 and celda_bomba.y < 13:
			radio_peligro.append(celda_bomba)
		
		var direcciones = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
		for dir in direcciones:
			for i in range(1, poder + 1):
				var celda_afectada = celda_bomba + (dir * i)
				
				if celda_afectada.x >= 0 and celda_afectada.x < 15 and celda_afectada.y >= 0 and celda_afectada.y < 13:
					if astar.is_point_solid(celda_afectada):
						break 
					radio_peligro.append(celda_afectada)
				else:
					break
				
	var fuegos = get_tree().get_nodes_in_group("fuego_activo")
	for fuego in fuegos:
		if fuego.has_meta("es_fuego_jefe") or "soy_del_jefe" in fuego:
			continue
			
		var celda_fuego = pos_a_celda(fuego.global_position)
		if celda_fuego.x >= 0 and celda_fuego.x < 15 and celda_fuego.y >= 0 and celda_fuego.y < 13:
			radio_peligro.append(celda_fuego)

func buscar_entidad_mas_cercana(grupo: String, mi_celda: Vector2i, ignorar_yo_mismo: bool = false) -> Node2D:
	var entidades = get_tree().get_nodes_in_group(grupo)
	var mas_cercana: Node2D = null
	var distancia_minima = 9999.0
	
	for entidad in entidades:
		if ignorar_yo_mismo and entidad == self:
			continue
			
		var celda_entidad = pos_a_celda(entidad.global_position)
		if celda_entidad.x >= 0 and celda_entidad.x < 15 and celda_entidad.y >= 0 and celda_entidad.y < 13:
			var ruta = astar.get_id_path(mi_celda, celda_entidad)
			if not ruta.is_empty():
				var dist = abs(mi_celda.x - celda_entidad.x) + abs(mi_celda.y - celda_entidad.y)
				if dist < distancia_minima:
					distancia_minima = dist
					mas_cercana = entidad
				
	return mas_cercana

func trazar_ruta(inicio: Vector2i, destino: Vector2i) -> void:
	for x in range(astar.region.size.x):
		for y in range(astar.region.size.y):
			var celda = Vector2i(x, y)
			if celda in radio_peligro:
				astar.set_point_weight_scale(celda, 10000.0)
			else:
				astar.set_point_weight_scale(celda, 1.0)
				
	if destino == celda_objetivo_final and not camino_actual.is_empty():
		return
		
	var ruta = astar.get_id_path(inicio, destino)
	
	if estado_actual != EstadoIA.HUIR and ruta.size() > 1:
		for celda in ruta:
			if celda in radio_peligro:
				camino_actual.clear()
				celda_objetivo_final = Vector2i(-1, -1)
				estado_actual = EstadoIA.IDLE
				return
	
	camino_actual.clear()
	celda_objetivo_final = destino
	
	for id in ruta:
		camino_actual.append(celda_a_pos(id))
		
	if not camino_actual.is_empty():
		camino_actual.pop_front() 
		if not camino_actual.is_empty():
			objetivo_posicion = camino_actual[0]
		else:
			objetivo_posicion = global_position

func actualizar_malla_obstaculos_procedurales(mapa: Node) -> void:
	if astar == null or mapa == null: return
	
	for x in range(15):
		for y in range(13):
			var offset_x = -((15 * 128) / 2.0) + (128 / 2.0) + mapa.desplazamiento_mapa.x
			var offset_y = -((13 * 128) / 2.0) + (128 / 2.0) + mapa.desplazamiento_mapa.y
			var pos_mundo = Vector2(offset_x + (x * 128), offset_y + (y * 128))
			
			var query = PhysicsPointQueryParameters2D.new()
			query.position = pos_mundo
			query.collision_mask = 1 
			
			var colisiones = get_world_2d().direct_space_state.intersect_point(query)
			if not colisiones.is_empty():
				astar.set_point_solid(Vector2i(x, y), true)

func _physics_process(delta: float) -> void:
	if esta_muerto or vidas <= 0:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if esta_atacando:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# 1. CEREBRO Y TEMPORIZADORES
	if not esta_muerto and vidas > 0 and not esta_atacando:
		if timer_ataque_especial > 0:
			timer_ataque_especial -= delta

		if timer_ataque_especial <= 0:
			if not puede_atacar:
				return 
			else:
				print("🚨 ¡ALERTA DE DISPARO! Forzando freno de zancada para lanzar ataqueFuego.")
				velocity = Vector2.ZERO # Aseguramos freno inmediato por físicas
				timer_ataque_especial = tiempo_recarga_especial
				camino_actual.clear()
				celda_objetivo_final = Vector2i(-1, -1)
				
				alinear_al_centro()
				ejecutar_ataque_suelo()
				return

		if astar != null and get_parent() != null:
			timer_decision -= delta
			if timer_decision <= 0:
				actualizar_mapa_peligro()
				tomar_decision()
				timer_decision = tiempo_reaccion + randf_range(-0.02, 0.05)

	# 2. MOVIMIENTO FÍSICO POR IMPULSOS SECUENCIALES
	if not camino_actual.is_empty():
		direccion_pulso_actual = global_position.direction_to(objetivo_posicion).normalized()
		
		if not sonido_pasos.playing and timer_impulso <= 0.0:
			avanzar_secuencia_paso()

		if timer_impulso > 0.0:
			timer_impulso -= delta
			velocity = direccion_pulso_actual * velocidad
			
			if global_position.distance_to(ultima_posicion_registro) < 0.3:
				tiempo_atascado += delta
				if tiempo_atascado >= limite_tiempo_atascado:
					print("Jefe: Atasco en pilar pautado. Destrabando.")
					sonido_pasos.stop()
					timer_impulso = 0.0
					tiempo_atascado = 0.0
					camino_actual.clear()
					celda_objetivo_final = Vector2i(-1, -1)
					estado_actual = EstadoIA.IDLE
					alinear_al_centro()
					tomar_decision()
			else:
				tiempo_atascado = 0.0
		else:
			velocity = Vector2.ZERO
			tiempo_atascado = 0.0 
			
		ultima_posicion_registro = global_position
	else:
		velocity = Vector2.ZERO
		tiempo_atascado = 0.0
		timer_impulso = 0.0
		ultima_posicion_registro = global_position
		
	move_and_slide()

	# 3. CONTROL DE REJILLA EN IMPULSOS
	if not camino_actual.is_empty() and global_position.distance_to(objetivo_posicion) < 20.0:
		global_position = objetivo_posicion
		camino_actual.pop_front()
		if not camino_actual.is_empty():
			objetivo_posicion = camino_actual[0]

	# 4. ATAQUE AUTOMÁTICO A CONTENEDORES OBSTÁCULO
	var dir_mirada = direccion_pulso_actual if direccion_pulso_actual != Vector2.ZERO else global_position.direction_to(objetivo_posicion).normalized()
	ajustar_direccion_rayo(dir_mirada)
	
	if puede_atacar and rayo_ataque.is_colliding():
		var objeto_detected = rayo_ataque.get_collider()
		if objeto_detected and (objeto_detected.is_in_group("contenedores") or objeto_detected.has_method("generar_bonificacion")):
			ejecutar_ataque_caja(objeto_detected)

	if not esta_atacando and camino_actual.is_empty():
		sprite.pause()

# 5. DETECCIONES CONTINUAS DE CONTACTO
	var bonificaciones_activas = get_tree().get_nodes_in_group("bonificaciones")
	for item in bonificaciones_activas:
		if global_position.distance_to(item.global_position) < 70.0:
			item.queue_free()
			
	var lista_jugadores = get_tree().get_nodes_in_group("jugadores")
	for jugador in lista_jugadores:
		if global_position.distance_to(jugador.global_position) < 75.0:
			if jugador.has_method("recibir_dano"):
				var vidas_antes = jugador.vidas if "vidas" in jugador else 0
				
				jugador.recibir_dano()

				var vidas_despues = jugador.vidas if "vidas" in jugador else 0
				if vidas_antes == 0 or vidas_despues < vidas_antes:
					reproducir_risa_aleatoria()

func avanzar_secuencia_paso() -> void:
	if camino_actual.is_empty() or esta_atacando or esta_muerto: return
	
	if abs(direccion_pulso_actual.x) > abs(direccion_pulso_actual.y):
		if direccion_pulso_actual.x < 0: 
			sprite.play("walkLeft")
		else: 
			sprite.play("walkRight")
	else:
		if direccion_pulso_actual.y > 0: 
			sprite.play("walkDown")
		else: 
			sprite.play("walkUp")
			
	sprite.pause()
	var total_frames = sprite.sprite_frames.get_frame_count(sprite.animation)
	sprite.frame = (sprite.frame + 1) % total_frames
	
	timer_impulso = duracion_impulso
	sonido_pasos.play()

func _on_paso_terminado() -> void:
	if not camino_actual.is_empty() and not esta_atacando and not esta_muerto:
		avanzar_secuencia_paso()

func ajustar_direccion_rayo(movimiento: Vector2) -> void:
	if movimiento == Vector2.ZERO: return
	if abs(movimiento.x) > abs(movimiento.y):
		rayo_ataque.target_position = Vector2(95 if movimiento.x > 0 else -95, 0)
	else:
		rayo_ataque.target_position = Vector2(0, 95 if movimiento.y > 0 else -95)

func ejecutar_ataque_caja(contenedor: Node2D) -> void:
	esta_atacando = true
	puede_atacar = false
	sonido_pasos.stop()
	timer_impulso = 0.0
	
	sprite.play("ataque")
	
	var pos_rayo = rayo_ataque.target_position
	sprite.flip_h = (pos_rayo.x > 0)
		
	# Retraso lúdico de 1.5s sincronizado para la caída del martillo
	await get_tree().create_timer(1.5).timeout
	
	if is_instance_valid(contenedor):
		if sonido_golpe_martillo.stream != null:
			sonido_golpe_martillo.play()
			
		if contenedor.has_method("recibir_dano"):
			contenedor.recibir_dano(1)
		elif "hp" in contenedor:
			contenedor.hp -= 1
			if contenedor.hp <= 0:
				contenedor.generar_bonificacion()
				contenedor.queue_free()

	await get_tree().create_timer(tiempo_entre_ataques).timeout
	puede_atacar = true
	
func _on_animation_finished() -> void:
	if esta_atacando:
		esta_atacando = false
		sprite.flip_h = false
		sprite.position = Vector2.ZERO

func recibir_dano(cantidad: int = 1) -> void:
	if esta_muerto or es_invulnerable or vidas <= 0: return

	vidas -= cantidad 
	print("¡Bomba impactó al Jefe! Vidas restantes: ", vidas)

	if vidas <= 0: 
		morir()
		return

	es_invulnerable = true
	var tween = create_tween().set_loops(3)
	tween.tween_property(sprite, "modulate", Color(1, 0, 0, 1), 0.1)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.1)

	await get_tree().create_timer(1.0).timeout
	es_invulnerable = false

func morir() -> void:
	esta_muerto = true
	sonido_pasos.stop()
	remove_from_group("enemigos")
	colision.set_deferred("disabled", true)
	mostrar_mensaje_victoria()

func mostrar_mensaje_victoria() -> void:
	if get_tree() == null or get_parent() == null: return
	
	set_physics_process(false)
	hide() 
	
	for nodo in get_parent().get_children():
		if (nodo is AudioStreamPlayer or nodo is AudioStreamPlayer2D) and nodo.playing:
			nodo.stop()
			
	var cancion_victoria = load("res://sounds/soundtrack/Nivel2/ganar.wav")
	if cancion_victoria != null:
		var audio_victoria = AudioStreamPlayer.new()
		audio_victoria.stream = cancion_victoria
		get_parent().add_child(audio_victoria)
		audio_victoria.play()
	
	var canvas = CanvasLayer.new()
	get_tree().root.add_child(canvas)
	
	var fondo = ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.75) 
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT) 
	canvas.add_child(fondo)
	
	var texto = Label.new()
	texto.text = "¡VERDUGO DESTRUIDO!\n\nAvanzando al Nivel 2..."
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto.set_anchors_preset(Control.PRESET_FULL_RECT)
	texto.add_theme_font_size_override("font_size", 45) 
	canvas.add_child(texto)
	
	if get_tree() == null: return
	await get_tree().create_timer(4.0).timeout
	
	if get_tree() != null:
		get_tree().change_scene_to_file("res://scenes/niveles/nivel2/nivel_2.tscn")
		canvas.queue_free()
		queue_free()

func pos_a_celda(pos: Vector2) -> Vector2i:
	var mapa = get_parent().get_node_or_null("lvl1_MapaProcedural")
	if mapa:
		var offset_x = -((15 * 128) / 2.0) + (128 / 2.0) + mapa.desplazamiento_mapa.x
		var offset_y = -((13 * 128) / 2.0) + (128 / 2.0) + mapa.desplazamiento_mapa.y
		var x = round((pos.x - offset_x) / 128.0)
		var y = round((pos.y - offset_y) / 128.0)
		return Vector2i(int(x), int(y))
	return Vector2i.ZERO

func celda_a_pos(celda: Vector2i) -> Vector2:
	var mapa = get_parent().get_node_or_null("lvl1_MapaProcedural")
	if mapa:
		var offset_x = -((15 * 128) / 2.0) + (128 / 2.0) + mapa.desplazamiento_mapa.x
		var offset_y = -((13 * 128) / 2.0) + (128 / 2.0) + mapa.desplazamiento_mapa.y
		return Vector2(offset_x + (celda.x * 128), offset_y + (celda.y * 128))
	return Vector2.ZERO
	
func ejecutar_ataque_suelo() -> void:
	if not puede_atacar or esta_muerto: return
	
	esta_atacando = true
	puede_atacar = false
	sonido_pasos.stop()
	timer_impulso = 0.0
	velocity = Vector2.ZERO
	
	camino_actual.clear()
	celda_objetivo_final = Vector2i(-1, -1)
	
	if sonido_carga_fuego.stream != null:
		sonido_carga_fuego.play()
	
	sprite.play("ataqueFuego") 
	await sprite.animation_finished
	
	propagar_fuego_en_cruz()
	esta_atacando = false
	
	await get_tree().create_timer(tiempo_entre_ataques).timeout
	puede_atacar = true
	
	alinear_al_centro()
	tomar_decision()

func propagar_fuego_en_cruz() -> void:
	if escena_fuego_jefe == null: return
	if sonido_fuego_cruz.stream != null:
		sonido_fuego_cruz.play()
		
	var origen_x = floor(global_position.x / 128.0) * 128.0 + 64.0
	var origen_y = floor(global_position.y / 128.0) * 128.0 + 64.0
	var posicion_centro_grid = Vector2(origen_x, origen_y)
	
	var fuego_centro = escena_fuego_jefe.instantiate()
	fuego_centro.global_position = posicion_centro_grid
	fuego_centro.set_meta("es_fuego_jefe", true) 
	get_parent().add_child(fuego_centro)
	
	var direcciones = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var tamano_celda = 128.0
	var alcance_maximo = 11
	
	for dir in direcciones:
		for i in range(1, alcance_maximo + 1):
			var pos_fuego_linea = posicion_centro_grid + (dir * (i * tamano_celda))
			
			var query_muro = PhysicsPointQueryParameters2D.new()
			query_muro.position = pos_fuego_linea
			query_muro.collision_mask = 1 
			var col_muro = get_world_2d().direct_space_state.intersect_point(query_muro)
			
			if not col_muro.is_empty():
				break
				
			var query_caja = PhysicsPointQueryParameters2D.new()
			query_caja.position = pos_fuego_linea
			query_caja.collision_mask = 2 
			var col_caja = get_world_2d().direct_space_state.intersect_point(query_caja)
			
			if not col_caja.is_empty():
				var objeto_detectado = col_caja[0].collider
				if objeto_detectado:
					if objeto_detectado.has_method("recibir_dano"):
						objeto_detectado.recibir_dano(1)
					elif "hp" in objeto_detectado:
						objeto_detectado.hp -= 1
						if objeto_detectado.hp <= 0:
							if objeto_detectado.has_method("generar_bonificacion"):
								objeto_detectado.generar_bonificacion()
							objeto_detectado.queue_free()
				
				var fuego = escena_fuego_jefe.instantiate()
				fuego.global_position = pos_fuego_linea
				fuego.set_meta("es_fuego_jefe", true)
				get_parent().add_child(fuego)
				break
				
			var fuego = escena_fuego_jefe.instantiate()
			fuego.global_position = pos_fuego_linea
			fuego.set_meta("es_fuego_jefe", true)
			get_parent().add_child(fuego)
			
func reproducir_risa_aleatoria() -> void:
	if sonido_risa.playing: return
	
	var pool_risas = [
		"res://sounds/soundtrack/Nivel1/risa1.wav",
		"res://sounds/soundtrack/Nivel1/risa2.wav",
		"res://sounds/soundtrack/Nivel1/risa3.wav"
	]
	
	var indice_aleatorio = randi() % pool_risas.size()
	var ruta_elegida = pool_risas[indice_aleatorio]
	
	var stream_audio = load(ruta_elegida)
	if stream_audio != null:
		sonido_risa.stream = stream_audio
		sonido_risa.play()
		print("😈 Verdugo se burla del jugador usando: ", ruta_elegida.get_file())
