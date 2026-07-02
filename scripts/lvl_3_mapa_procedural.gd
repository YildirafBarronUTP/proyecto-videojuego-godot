extends MapaProcedural # Heredar logica

@export var escena_robot_enemigo : PackedScene # Aquí arrastrarás tu 'RobotEnemigo.tscn'

func _ready() -> void:
	# personalizar las dimensiones
	columnas = 15
	filas = 13
	probabilidad_contenedor = 0.7 # Más o menos obstáculos
	
	# Llama a la función del script base que dibuja el mapa y los contenedores
	super._ready()
	
	# ¡SOLUCIÓN!: Detecta los bloques reales en pantalla y acomoda a los enemigos internamente
	spawnear_robots_en_esquinas_reales()

func spawnear_robots_en_esquinas_reales() -> void:
	if not escena_robot_enemigo:
		print("¡AVISO!: No has asignado la escena del RobotEnemigo en el Inspector del Mapa 3.")
		return
		
	# Creamos variables para medir los límites reales de tus muros decorados
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	
	# Escaneamos la posición exacta de cada bloque que el generador creó en la pantalla
	for hijo in get_children():
		if hijo is Node2D:
			var pos = hijo.position
			if pos.x < min_x: min_x = pos.x
			if pos.x > max_x: max_x = pos.x
			if pos.y < min_y: min_y = pos.y
			if pos.y > max_y: max_y = pos.y
			
	# Si por alguna razón no se detectan bloques, evitamos un colapso
	if min_x == INF:
		print("Error: No se pudieron escanear las dimensiones del laberinto procedural.")
		return
		
	var tamano_celda = 128.0 # Dimensión de tus baldosas
	
	# Calculamos matemáticamente las 3 esquinas jugables exactamente UN bloque hacia adentro
	# de los muros perimetrales reales detectados en el escaneo anterior.
	var esquinas_posiciones = [
		Vector2(max_x - tamano_celda, min_y + tamano_celda), # Esquina Superior Derecha
		Vector2(min_x + tamano_celda, max_y - tamano_celda), # Esquina Inferior Izquierda
		Vector2(max_x - tamano_celda, max_y - tamano_celda)  # Esquina Inferior Derecha
	]
	
	for pos_esquina in esquinas_posiciones:
		# Limpiamos el contenedor del 70% de probabilidad si cayó justo en esa esquina
		limpiar_contenedor_en_posicion(pos_esquina)
		
		# Instanciamos el robot enemigo de forma segura
		var robot = escena_robot_enemigo.instantiate()
		add_child(robot)
		
		# Lo posicionamos de forma local basándonos en la cuadrícula escaneada
		robot.position = pos_esquina
		
		# Escala ideal para que quepa perfectamente y se mueva sin atascos por los pasillos
		robot.scale = Vector2(0.45, 0.45)
		
	print("Mapa 3: Los 3 robots cazadores han sido desplegados en sus respectivas esquinas reales.")

func limpiar_contenedor_en_posicion(pos_local: Vector2) -> void:
	# Recorremos los hijos para desintegrar cualquier caja de madera en el spawn del enemigo
	for hijo in get_children():
		if hijo.is_in_group("contenedores") or "contenedor" in hijo.name.to_lower():
			if hijo.position.distance_to(pos_local) < 10.0:
				hijo.queue_free()
