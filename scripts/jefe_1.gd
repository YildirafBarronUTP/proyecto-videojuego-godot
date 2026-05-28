extends Cpu
class_name JefeNivel1

@export_category("Estadísticas del Jefe")
@export var hp_maximo: int = 8
@export var tiempo_entre_ataques: float = 1.0

@onready var sonido_pasos: AudioStreamPlayer2D = $SonidoPasos
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var colision: CollisionShape2D = $CollisionShape2D
@onready var rayo_ataque: RayCast2D = $RayCast2D

var esta_muerto: bool = false
var esta_atacando: bool = false
var puede_atacar: bool = true

# VARIABLES DE PULSO SECUENCIAL
var ultima_posicion_registro: Vector2 = Vector2.ZERO
var tiempo_atascado: float = 0.0
@export var limite_tiempo_atascado: float = 0.15

# AJUSTE DE DISTANCIA POR PASO
var timer_impulso: float = 0.0
@export var duracion_impulso: float = 0.15 
var direccion_pulso_actual: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("enemigos")
	
	# Usamos las variables heredadas del padre Jugador/Cpu
	velocidad = 280.0
	vidas = hp_maximo
	
	sonido_pasos.volume_db = 5.0
	sonido_pasos.max_distance = 4000.0
	
	sprite.animation_finished.connect(_on_animation_finished)
	
	if sonido_pasos.finished.is_connected(_on_paso_terminado):
		sonido_pasos.finished.disconnect(_on_paso_terminado)
	sonido_pasos.finished.connect(_on_paso_terminado)
	
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

# --- SOBREESCRITURA DE MÉTODOS DEL PADRE PARA DESACOPLAR 'NIVEL' ---

func tomar_decision() -> void:
	var mi_celda = pos_a_celda(global_position)
	
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

	var victima = buscar_entidad_mas_cercana("jugadores", mi_celda, true)
	if victima != null and cargas_activas < cargas_maximas:
		estado_actual = EstadoIA.ATACAR
		intentar_acorralar(mi_celda, pos_a_celda(victima.global_position))
		if estado_actual == EstadoIA.ATACAR: return 

	var bonificacion = buscar_entidad_mas_cercana("bonificaciones", mi_celda)
	if bonificacion != null:
		estado_actual = EstadoIA.LOOTEAR
		trazar_ruta(mi_celda, pos_a_celda(bonificacion.global_position))
		if not camino_actual.is_empty(): return

	var contenedor = buscar_entidad_mas_cercana("contenedores", mi_celda)
	if contenedor != null and cargas_activas < cargas_maximas:
		estado_actual = EstadoIA.FARMEAR
		intentar_destruir_contenedor(mi_celda, pos_a_celda(contenedor.global_position))
		return
		
	estado_actual = EstadoIA.IDLE

func intentar_acorralar(mi_celda: Vector2i, celda_victima: Vector2i) -> void:
	var misma_linea = (mi_celda.x == celda_victima.x) or (mi_celda.y == celda_victima.y)
	var a_distancia_de_tiro = mi_celda.distance_to(celda_victima) <= poder_explosion
	
	if misma_linea and a_distancia_de_tiro:
		if simulacion_es_seguro_plantar(mi_celda):
			alinear_al_centro()
			plantar_bomba()
			actualizar_mapa_peligro()
			buscar_casilla_segura(mi_celda)
			return
			
	var adyacentes_victima = [
		celda_victima,
		celda_victima + Vector2i.UP, celda_victima + Vector2i.DOWN,
		celda_victima + Vector2i.LEFT, celda_victima + Vector2i.RIGHT
	]
	
	if celda_objetivo_final in adyacentes_victima and not camino_actual.is_empty():
		return 

	if randi() % 100 < 35: 
		var opciones_flanqueo = [
			celda_victima + Vector2i.UP, 
			celda_victima + Vector2i.DOWN, 
			celda_victima + Vector2i.LEFT, 
			celda_victima + Vector2i.RIGHT
		]
		opciones_flanqueo.shuffle()
		
		for ady in opciones_flanqueo:
			if ady.x >= 0 and ady.x < 15 and ady.y >= 0 and ady.y < 13:
				if not astar.is_point_solid(ady) and not ady in radio_peligro:
					trazar_ruta(mi_celda, ady)
					return
	
	if celda_victima.x >= 0 and celda_victima.x < 15 and celda_victima.y >= 0 and celda_victima.y < 13:
		trazar_ruta(mi_celda, celda_victima)

func simulacion_es_seguro_plantar(celda_simulada: Vector2i) -> bool:
	var peligro_simulado: Array[Vector2i] = []
	
	if celda_simulada.x >= 0 and celda_simulada.x < 15 and celda_simulada.y >= 0 and celda_simulada.y < 13:
		peligro_simulado.append(celda_simulada)
	
	var direcciones = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	for dir in direcciones:
		for i in range(1, poder_explosion + 1):
			var celda_afectada = celda_simulada + (dir * i)
			
			if celda_afectada.x >= 0 and celda_afectada.x < 15 and celda_afectada.y >= 0 and celda_afectada.y < 13:
				if astar.is_point_solid(celda_afectada):
					break
				peligro_simulado.append(celda_afectada)
			else:
				break
			
	for x in range(-5, 6):
		for y in range(-5, 6):
			var casilla_refugio = celda_simulada + Vector2i(x, y)
			
			if casilla_refugio.x >= 0 and casilla_refugio.x < 15 and casilla_refugio.y >= 0 and casilla_refugio.y < 13:
				if not astar.is_point_solid(casilla_refugio) and not casilla_refugio in peligro_simulado and not casilla_refugio in radio_peligro:
					var ruta_escape = astar.get_id_path(celda_simulada, casilla_refugio)
					if not ruta_escape.is_empty():
						var escape_seguro = true
						for i in range(1, ruta_escape.size()):
							var celda_paso = ruta_escape[i]
							if celda_paso in radio_peligro:
								escape_seguro = false
								break
						if escape_seguro:
							return true 
	return false

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
		var es_alcanzable = false
		
		if grupo == "contenedores":
			if abs(mi_celda.x - celda_entidad.x) + abs(mi_celda.y - celda_entidad.y) <= 1:
				es_alcanzable = true
			else:
				var adyacentes = [celda_entidad + Vector2i.UP, celda_entidad + Vector2i.DOWN, celda_entidad + Vector2i.LEFT, celda_entidad + Vector2i.RIGHT]
				for ady in adyacentes:
					if ady.x >= 0 and ady.x < 15 and ady.y >= 0 and ady.y < 13:
						if not astar.is_point_solid(ady):
							var ruta = astar.get_id_path(mi_celda, ady)
							if not ruta.is_empty():
								es_alcanzable = true
								break
		else:
			if celda_entidad.x >= 0 and celda_entidad.x < 15 and celda_entidad.y >= 0 and celda_entidad.y < 13:
				var ruta = astar.get_id_path(mi_celda, celda_entidad)
				if not ruta.is_empty():
					es_alcanzable = true
				
		if es_alcanzable:
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
	if esta_muerto or vidas <= 0 or esta_atacando:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# 1. EJECUTAR EL CEREBRO DE LA IA
	if astar != null and get_parent() != null:
		timer_decision -= delta
		if timer_decision <= 0:
			actualizar_mapa_peligro()
			tomar_decision()
			timer_decision = tiempo_reaccion + randf_range(-0.02, 0.05)

	# 2. MOVIMIENTO FÍSICO POR IMPULSOS SECUENCIALES (Con Anti-Atasco de precisión)
	if not camino_actual.is_empty():
		direccion_pulso_actual = global_position.direction_to(objetivo_posicion).normalized()
		
		# DISPARADOR SECUENCIAL AUTOMÁTICO
		if not sonido_pasos.playing and timer_impulso <= 0.0:
			avanzar_secuencia_paso()

		# Aplicamos velocidad estable mientras el pulso de tiempo esté activo
		if timer_impulso > 0.0:
			timer_impulso -= delta
			velocity = direccion_pulso_actual * velocidad
			
			# --- CORRECCIÓN INTEGRAL ANTI-ATASCO EN PULSOS ---
			if global_position.distance_to(ultima_posicion_registro) < 0.3:
				tiempo_atascado += delta
				if tiempo_atascado >= limite_tiempo_atascado:
					print("Jefe: Atasco en pilar detectado durante pulso activo. Forzando destrabe.")
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

	# 3. COMPROBACIÓN DE LLEGADA A LA CELDA
	if not camino_actual.is_empty() and global_position.distance_to(objetivo_posicion) < 20.0:
		global_position = objetivo_posicion
		camino_actual.pop_front()
		if not camino_actual.is_empty():
			objetivo_posicion = camino_actual[0]

	# 4. ATAQUE AUTOMÁTICO A CAJAS CUANDO OBSTRUYEN EL PASO
	var dir_mirada = direccion_pulso_actual if direccion_pulso_actual != Vector2.ZERO else global_position.direction_to(objetivo_posicion).normalized()
	ajustar_direccion_rayo(dir_mirada)
	
	if puede_atacar and rayo_ataque.is_colliding():
		var objeto_detected = rayo_ataque.get_collider()
		if objeto_detected and objeto_detected.has_method("generar_bonificacion"):
			ejecutar_ataque_caja(objeto_detected)

	# 5. PAUSA SI LLEGA AL DESTINO Y SE QUEDA INMÓVIL
	if not esta_atacando and camino_actual.is_empty():
		sprite.pause()

# --- CONTROLADOR CENTRAL DE LA SECUENCIA CONSECUTIVA ---

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

# --- SISTEMA DE GOLPES, ANIMACIONES CON FLIP Y PISADAS ---

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
	
	var pos_rayo = rayo_ataque.target_position
	sprite.play("ataque")
	
	# TRUCO DE ESCALA Y CENTRADO VISUAL
	sprite.scale = Vector2(1.15, 1.15)
	
	if pos_rayo.x > 0:
		sprite.flip_h = true
		sprite.position.x = -15.0
	else:
		sprite.flip_h = false
		sprite.position.x = 15.0
		
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
		
		# RESTAURAR AL ESTADO NORMAL DE CAMINATA
		sprite.scale = Vector2(1.0, 1.0)
		sprite.position = Vector2.ZERO

func recibir_dano(cantidad: int = 1) -> void:
	if esta_muerto: return
	vidas -= cantidad 
	print("¡Bomba impactó al Jefe! Vidas restantes: ", vidas)
	sprite.modulate = Color(1, 0, 0) 
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color(1, 1, 1) 
	if vidas <= 0: 
		morir()

func morir() -> void:
	esta_muerto = true
	sonido_pasos.stop()
	remove_from_group("enemigos")
	colision.set_deferred("disabled", true)
	await get_tree().create_timer(1.0).timeout
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
