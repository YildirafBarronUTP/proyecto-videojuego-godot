extends Jugador
class_name Cpu

enum EstadoIA { IDLE, HUIR, LOOTEAR, FARMEAR, ATACAR }
var estado_actual: EstadoIA = EstadoIA.IDLE

@export var color_robot: Color = Color.WHITE
var nivel: NivelMultiBase
var astar: AStarGrid2D
var camino_actual: Array[Vector2] = []
var objetivo_posicion: Vector2 = Vector2.ZERO
var celda_objetivo_final: Vector2i = Vector2i(-1, -1) 

var tiempo_reaccion: float = 0.15 
var timer_decision: float = 0.0

var radio_peligro: Array[Vector2i] = []

func _ready() -> void:
	super._ready()
	
	# El bot se pinta del color apenas nace
	if has_node("Sprite2D"):
		$Sprite2D.modulate = color_robot
	await get_tree().create_timer(1.2).timeout
	if get_parent() is NivelMultiBase:
		nivel = get_parent() as NivelMultiBase
		astar = nivel.astar_grid

func _physics_process(delta: float) -> void:
	if astar == null or nivel == null or vidas <= 0:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	timer_decision -= delta
	if timer_decision <= 0:
		actualizar_mapa_peligro()
		tomar_decision()
		timer_decision = tiempo_reaccion + randf_range(-0.02, 0.05)

	ejecutar_movimiento()

func alinear_al_centro() -> void:
	var mi_celda = nivel.pos_a_celda(global_position)
	global_position = nivel.celda_a_pos(mi_celda)

func tomar_decision() -> void:
	var mi_celda = nivel.pos_a_celda(global_position)
	
	# 1. SUPERVIVENCIA ESTRICTA 
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

	# 2. ATACAR 
	var victima = buscar_entidad_mas_cercana("jugadores", mi_celda, true)
	if victima != null and cargas_activas < cargas_maximas:
		estado_actual = EstadoIA.ATACAR
		intentar_acorralar(mi_celda, nivel.pos_a_celda(victima.global_position))
		if estado_actual == EstadoIA.ATACAR: return 

	# 3. LOOTEAR
	var bonificacion = buscar_entidad_mas_cercana("bonificaciones", mi_celda)
	if bonificacion != null:
		estado_actual = EstadoIA.LOOTEAR
		trazar_ruta(mi_celda, nivel.pos_a_celda(bonificacion.global_position))
		if not camino_actual.is_empty(): return

	# 4. FARMEAR
	var contenedor = buscar_entidad_mas_cercana("contenedores", mi_celda)
	if contenedor != null and cargas_activas < cargas_maximas:
		estado_actual = EstadoIA.FARMEAR
		intentar_destruir_contenedor(mi_celda, nivel.pos_a_celda(contenedor.global_position))
		return
		
	estado_actual = EstadoIA.IDLE

func intentar_destruir_contenedor(mi_celda: Vector2i, celda_caja: Vector2i) -> void:
	var distancia = abs(mi_celda.x - celda_caja.x) + abs(mi_celda.y - celda_caja.y)
	
	if distancia <= 1: 
		if simulacion_es_seguro_plantar(mi_celda):
			alinear_al_centro()
			plantar_bomba()
			actualizar_mapa_peligro()
			buscar_casilla_segura(mi_celda)
		else:
			var celdas_adyacentes = [ mi_celda + Vector2i.UP, mi_celda + Vector2i.DOWN, mi_celda + Vector2i.LEFT, mi_celda + Vector2i.RIGHT ]
			celdas_adyacentes.shuffle()
			for ady in celdas_adyacentes:
				if not astar.is_point_solid(ady) and not ady in radio_peligro:
					trazar_ruta(mi_celda, ady)
					return
	else:
		var celdas_adyacentes = [
			celda_caja + Vector2i.UP, celda_caja + Vector2i.DOWN,
			celda_caja + Vector2i.LEFT, celda_caja + Vector2i.RIGHT
		]
		
		if celda_objetivo_final in celdas_adyacentes and not camino_actual.is_empty():
			return
			
		var mejor_ruta = []
		var mejor_adyacente = Vector2i.ZERO
		
		for adyacente in celdas_adyacentes:
			if not astar.is_point_solid(adyacente) and not adyacente in radio_peligro:
				var ruta = astar.get_id_path(mi_celda, adyacente)
				if not ruta.is_empty():
					if mejor_ruta.is_empty() or ruta.size() < mejor_ruta.size():
						mejor_ruta = ruta
						mejor_adyacente = adyacente

		if not mejor_ruta.is_empty():
			trazar_ruta(mi_celda, mejor_adyacente)

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
			
	# === NUEVO: MEMORIA DE ATAQUE ANTI-ZIGZAG ===
	# Si ya estamos persiguiendo a la víctima o estamos flanqueando su posición actual, mantenemos el rumbo
	var adyacentes_victima = [
		celda_victima,
		celda_victima + Vector2i.UP, celda_victima + Vector2i.DOWN,
		celda_victima + Vector2i.LEFT, celda_victima + Vector2i.RIGHT
	]
	
	if celda_objetivo_final in adyacentes_victima and not camino_actual.is_empty():
		return # Mantenemos el plan táctico sin tirar los dados de nuevo

	# Si no tenemos un plan, tiramos los dados para flanquear o ir directo
	if randi() % 100 < 35: 
		var opciones_flanqueo = [celda_victima + Vector2i.UP, celda_victima + Vector2i.DOWN, celda_victima + Vector2i.LEFT, celda_victima + Vector2i.RIGHT]
		opciones_flanqueo.shuffle()
		for ady in opciones_flanqueo:
			if not astar.is_point_solid(ady) and not ady in radio_peligro:
				trazar_ruta(mi_celda, ady)
				return
	
	# Si el flanqueo falla o toca persecución agresiva
	trazar_ruta(mi_celda, celda_victima)

func actualizar_mapa_peligro() -> void:
	radio_peligro.clear()
	
	var bombas = get_tree().get_nodes_in_group("bombas")
	for bomba in bombas:
		var celda_bomba = nivel.pos_a_celda(bomba.global_position)
		var poder = bomba.poder_explosion if "poder_explosion" in bomba else 2
		radio_peligro.append(celda_bomba)
		
		var direcciones = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
		for dir in direcciones:
			for i in range(1, poder + 1):
				var celda_afectada = celda_bomba + (dir * i)
				if astar.is_point_solid(celda_afectada):
					break 
				radio_peligro.append(celda_afectada)
				
	var fuegos = get_tree().get_nodes_in_group("fuego_activo")
	for fuego in fuegos:
		var celda_fuego = nivel.pos_a_celda(fuego.global_position)
		radio_peligro.append(celda_fuego)

func simulacion_es_seguro_plantar(celda_simulada: Vector2i) -> bool:
	var peligro_simulado: Array[Vector2i] = []
	peligro_simulado.append(celda_simulada)
	
	var direcciones = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	for dir in direcciones:
		for i in range(1, poder_explosion + 1):
			var celda_afectada = celda_simulada + (dir * i)
			if astar.is_point_solid(celda_afectada):
				break
			peligro_simulado.append(celda_afectada)
			
	for x in range(-5, 6):
		for y in range(-5, 6):
			var casilla_refugio = celda_simulada + Vector2i(x, y)
			
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

func buscar_casilla_segura(mi_celda: Vector2i) -> void:
	var radio_busqueda = 1
	while radio_busqueda < 10:
		var opciones_seguras = [] 
		for x in range(-radio_busqueda, radio_busqueda + 1):
			for y in range(-radio_busqueda, radio_busqueda + 1):
				var celda_revisada = mi_celda + Vector2i(x, y)
				if not astar.is_point_solid(celda_revisada) and not celda_revisada in radio_peligro:
					var ruta = astar.get_id_path(mi_celda, celda_revisada)
					if not ruta.is_empty():
						opciones_seguras.append(celda_revisada)
		
		if not opciones_seguras.is_empty():
			opciones_seguras.shuffle()
			trazar_ruta(mi_celda, opciones_seguras[0])
			return
			
		radio_busqueda += 1

func buscar_entidad_mas_cercana(grupo: String, mi_celda: Vector2i, ignorar_yo_mismo: bool = false) -> Node2D:
	var entidades = get_tree().get_nodes_in_group(grupo)
	var mas_cercana: Node2D = null
	var distancia_minima = 9999.0
	
	for entidad in entidades:
		if ignorar_yo_mismo and entidad == self:
			continue
			
		var celda_entidad = nivel.pos_a_celda(entidad.global_position)
		var es_alcanzable = false
		
		if grupo == "contenedores":
			if abs(mi_celda.x - celda_entidad.x) + abs(mi_celda.y - celda_entidad.y) <= 1:
				es_alcanzable = true
			else:
				var adyacentes = [celda_entidad + Vector2i.UP, celda_entidad + Vector2i.DOWN, celda_entidad + Vector2i.LEFT, celda_entidad + Vector2i.RIGHT]
				for ady in adyacentes:
					if not astar.is_point_solid(ady):
						var ruta = astar.get_id_path(mi_celda, ady)
						if not ruta.is_empty():
							es_alcanzable = true
							break
		else:
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
		camino_actual.append(nivel.celda_a_pos(id))
		
	if not camino_actual.is_empty():
		camino_actual.pop_front() 
		if not camino_actual.is_empty():
			objetivo_posicion = camino_actual[0]
		else:
			objetivo_posicion = global_position

func ejecutar_movimiento() -> void:
	if camino_actual.is_empty():
		velocity = Vector2.ZERO
		move_and_slide()
		$Sprite2D.stop()
		return

	var direccion = global_position.direction_to(objetivo_posicion)

	if abs(direccion.x) > abs(direccion.y):
		if direccion.x < 0:
			$Sprite2D.play("perfil_izquierdo")
		else:
			$Sprite2D.play("perfil_derecho")
	else:
		if direccion.y < 0:
			$Sprite2D.play("caminar_atras")
		else:
			$Sprite2D.play("caminar_frente")

	velocity = direccion * velocidad
	move_and_slide()

	if global_position.distance_to(objetivo_posicion) < 15.0:
		global_position = objetivo_posicion
		camino_actual.pop_front()
		
		if not camino_actual.is_empty():
			objetivo_posicion = camino_actual[0]
