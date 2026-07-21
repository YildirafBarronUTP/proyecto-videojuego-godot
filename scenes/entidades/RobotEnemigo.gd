extends CharacterBody2D

@export var velocidad : float = 130.0
@export var hp : int = 3

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D

var objetivo : Node2D = null
var direccion_actual : Vector2 = Vector2.DOWN
var esta_disparando : bool = false
var tamano_celda : float = 128.0

# Sistema Anti-Atasco
var ultima_posicion : Vector2 = Vector2.ZERO
var tiempo_atascado : float = 0.0

func _ready() -> void:
	add_to_group("enemigos")
	add_to_group("robots_cazadores")
	buscar_a_voltio()
	actualizar_animacion(direccion_actual)

func buscar_a_voltio() -> void:
	var jugadores = get_tree().get_nodes_in_group("jugadores")
	if jugadores.is_empty():
		jugadores = get_tree().get_nodes_in_group("jugador")
		
	if not jugadores.is_empty():
		objetivo = jugadores[0]

func _physics_process(delta: float) -> void:
	if hp <= 0 or esta_disparando:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	if not objetivo or not is_instance_valid(objetivo):
		buscar_a_voltio()

	if objetivo and is_instance_valid(objetivo):
		actualizar_animacion(direccion_actual)
		
		# 1. ESCÁNER ESPACIAL (Detecta objetivo o contenedor al frente)
		var objeto_frente = escanear_objeto_frente()
		if objeto_frente:
			if es_voltio(objeto_frente):
				ejecutar_ataque_a_voltio(objeto_frente)
				return
			elif es_objeto_destruible(objeto_frente):
				ejecutar_disparo_laser(objeto_frente)
				return
		
		# 2. MOVIMIENTO
		velocity = direccion_actual * velocidad
		move_and_slide()
		
		# 3. RESPALDO POR CONTACTO FÍSICO DIRECTO
		for i in get_slide_collision_count():
			var colision = get_slide_collision(i)
			var colisionador = colision.get_collider()
			if es_voltio(colisionador):
				ejecutar_ataque_a_voltio(colisionador)
				return
			elif es_objeto_destruible(colisionador):
				ejecutar_disparo_laser(colisionador)
				return
		
		# 4. DECISIÓN DE RUTA Y SISTEMA ANTI-ATASCO
		if is_on_wall() or global_position.distance_to(ultima_posicion) < 0.4:
			tiempo_atascado += delta
			if tiempo_atascado >= 0.15:
				tiempo_atascado = 0.0
				recalcular_ruta_hacia_voltio(true)
		else:
			tiempo_atascado = 0.0
			if randf() < 0.03:
				recalcular_ruta_hacia_voltio(false)
			
		ultima_posicion = global_position

# --- DETECCIÓN EN ESPACIO FÍSICO 2D ---
func escanear_objeto_frente() -> Node2D:
	var punto_sensor = global_position + (direccion_actual * 65.0)
	
	var query = PhysicsPointQueryParameters2D.new()
	query.position = punto_sensor
	query.collide_with_bodies = true
	query.collide_with_areas = true
	
	var colisiones = get_world_2d().direct_space_state.intersect_point(query)
	for col in colisiones:
		var colisionador = col.collider
		if colisionador and colisionador != self:
			if es_voltio(colisionador) or es_objeto_destruible(colisionador):
				return colisionador
	return null

func es_voltio(obj: Node) -> bool:
	if not obj or not is_instance_valid(obj): return false
	return obj.is_in_group("jugadores") or obj.is_in_group("jugador") or "voltio" in obj.name.to_lower()

func es_objeto_destruible(obj: Node) -> bool:
	if not obj or not is_instance_valid(obj): return false
	return obj.is_in_group("contenedores") or "hp" in obj or "contenedor" in obj.name.to_lower()

# --- ATAQUES ---
func ejecutar_ataque_a_voltio(voltio_obj: Node) -> void:
	esta_disparando = true
	velocity = Vector2.ZERO
	sprite.stop()
	
	print("Robot: ¡Voltio avistado! Disparando láser...")
	await get_tree().create_timer(0.25).timeout
	
	if is_instance_valid(voltio_obj):
		if voltio_obj.has_method("recibir_dano"):
			voltio_obj.recibir_dano()
			print("¡El láser del robot le quitó 1 vida a Voltio!")
		elif "vidas" in voltio_obj:
			voltio_obj.vidas -= 1
			
	await get_tree().create_timer(0.4).timeout
	esta_disparando = false

func ejecutar_disparo_laser(contenedor: Node) -> void:
	esta_disparando = true
	velocity = Vector2.ZERO
	sprite.stop()
	
	print("Robot: ¡Contenedor detectado! Disparando ráfaga láser...")
	await get_tree().create_timer(0.3).timeout
	
	if is_instance_valid(contenedor):
		if contenedor.has_method("recibir_dano"):
			contenedor.recibir_dano(1)
		elif "hp" in contenedor:
			contenedor.hp -= 1
			if contenedor.hp <= 0:
				if contenedor.has_method("generar_bonificacion"):
					contenedor.generar_bonificacion()
				contenedor.queue_free()
		elif contenedor.has_method("destruir"):
			contenedor.destruir()
		else:
			contenedor.queue_free()
			
		print("Robot: ¡Contenedor desintegrado!")
		
	await get_tree().create_timer(0.2).timeout
	esta_disparando = false
	recalcular_ruta_hacia_voltio(false)

func recalcular_ruta_hacia_voltio(forzar_desatasco: bool = false) -> void:
	if not objetivo or not is_instance_valid(objetivo): return
	
	var direcciones = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	
	if forzar_desatasco:
		direcciones.shuffle()
		direccion_actual = direcciones[0]
		actualizar_animacion(direccion_actual)
		return
		
	var mejor_direccion = direccion_actual
	var menor_distancia = INF
	
	for dir in direcciones:
		if dir == -direccion_actual and direcciones.size() > 1:
			continue
			
		var posicion_futura = global_position + (dir * tamano_celda)
		var distancia_a_voltio = posicion_futura.distance_to(objetivo.global_position)
		
		if distancia_a_voltio < menor_distancia:
			menor_distancia = distancia_a_voltio
			mejor_direccion = dir
			
	direccion_actual = mejor_direccion
	actualizar_animacion(direccion_actual)

func actualizar_animacion(dir: Vector2) -> void:
	if dir == Vector2.RIGHT:
		sprite.play("caminar_derecha")
	elif dir == Vector2.LEFT:
		sprite.play("caminar_izquierda")
	elif dir == Vector2.DOWN:
		sprite.play("caminar_abajo")
	elif dir == Vector2.UP:
		sprite.play("caminar_arriba")

# --- SISTEMA DE DAÑO Y COMPROBACIÓN DE VICTORIA ---
func recibir_dano(cantidad: int = 1) -> void:
	if hp <= 0: return
	
	hp -= cantidad
	print("Robot cazador dañado. HP restante: ", hp)
	
	if hp <= 0:
		morir_y_verificar_victoria()

func morir_y_verificar_victoria() -> void:
	# Nos desvinculamos inmediatamente de los grupos
	remove_from_group("enemigos")
	remove_from_group("robots_cazadores")
	
	# Comprobamos cuántos robots cazadores quedan vivos en la escena
	var robots_restantes = get_tree().get_nodes_in_group("robots_cazadores")
	print("Robots cazadores restantes en el mapa: ", robots_restantes.size())
	
	if robots_restantes.is_empty():
		# ¡Es el último robot! Mostramos el mensaje de victoria
		mostrar_mensaje_victoria()
	else:
		# Aún quedan otros robots vivos en la partida
		queue_free()

# --- VICTORIA CINEMATOGRÁFICA ---
func mostrar_mensaje_victoria() -> void:
	if get_tree() == null or get_parent() == null: return
	
	set_physics_process(false)
	hide() # Ocultamos el sprite del robot
	
	# 1. Detener la música de fondo del Nivel 3
	for nodo in get_parent().get_children():
		if (nodo is AudioStreamPlayer or nodo is AudioStreamPlayer2D) and nodo.playing:
			nodo.stop()
			
	# 2. Reproducción de audio de victoria
	var cancion_victoria = load("res://sounds/soundtrack/Nivel2/ganar.wav")
	if cancion_victoria != null:
		var audio_victoria = AudioStreamPlayer.new()
		audio_victoria.stream = cancion_victoria
		get_parent().add_child(audio_victoria)
		audio_victoria.play()
	
	# 3. Interfaz de pantalla de victoria
	var canvas = CanvasLayer.new()
	get_tree().root.add_child(canvas)
	
	var fondo = ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.75) 
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT) 
	canvas.add_child(fondo)
	
	var texto = Label.new()
	texto.text = "¡ROBOTS CAZADORES DESTRUIDOS!\n\nEnfrentando al Núcleo Central..."
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto.set_anchors_preset(Control.PRESET_FULL_RECT)
	texto.add_theme_font_size_override("font_size", 45) 
	canvas.add_child(texto)
	
	# 4. Esperar 4 segundos mostrando el aviso
	await get_tree().create_timer(4.0).timeout
	
	if get_tree() != null:
		# 5. BÚSQUEDA INTELIGENTE DE RUTA (Evita bloqueos)
		var ruta_siguiente_nivel = "res://niveles/nivel3/nivel_3b.tscn"
		
		if not ResourceLoader.exists(ruta_siguiente_nivel):
			if ResourceLoader.exists("res://scenes/niveles/nivel3/nivel_3b.tscn"):
				ruta_siguiente_nivel = "res://scenes/niveles/nivel3/nivel_3b.tscn"
			elif ResourceLoader.exists("res://scenes/niveles/nivel_3b.tscn"):
				ruta_siguiente_nivel = "res://scenes/niveles/nivel_3b.tscn"
				
		print("Cargando siguiente nivel en: ", ruta_siguiente_nivel)
		get_tree().change_scene_to_file(ruta_siguiente_nivel)
		
		# Limpiamos el texto y el nodo del robot
		canvas.queue_free()
		queue_free()
