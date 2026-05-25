extends Node2D

@export var escena_jefe: PackedScene = preload("res://scenes/entidades/jefe1.tscn")
@onready var musica_fondo: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var sonido_lava: AudioStreamPlayer = AudioStreamPlayer.new()

# Referencia a la región de navegación
@onready var nav_region: NavigationRegion2D = $NavigationRegion2D 

func _ready() -> void:
	print("Nivel 1 iniciado correctamente")
	
	# 1. Configurar audios
	musica_fondo.stream = load("res://sounds/soundtrack/Nivel1/main_theme.wav")
	musica_fondo.volume_db = -5.0
	add_child(musica_fondo)
	musica_fondo.play()
	
	sonido_lava.stream = load("res://sounds/soundtrack/Nivel1/lava_flow.wav")
	sonido_lava.volume_db = -17.0
	add_child(sonido_lava)
	sonido_lava.play()
	
	# 2. BUSCAR EL MAPA (Ruta directa según el nuevo árbol de nodos)
	# Si tu nodo en la escena se llama diferente a "MapaProcedural", cambia ese nombre aquí abajo:
	if has_node("NavigationRegion2D/MapaProcedural"):
		var mapa = $NavigationRegion2D/Lvl1MapaProcedural
		print("Mapa detectado con éxito en la nueva ruta. Esperando señal...")
		mapa.mapa_generado_lvl1.connect(_on_mapa_listo)
	else:
		print("ERROR CRÍTICO: No se encontró el nodo MapaProcedural dentro de NavigationRegion2D")
		# Plan de respaldo por si la ruta falla: spawnear al jefe de todas formas
		await get_tree().create_timer(0.5).timeout
		spawnear_jefe(null)

func _on_mapa_listo() -> void:
	print("Señal 'mapa_generado_lvl1' recibida con éxito. Horneando navegación...")
	if nav_region:
		nav_region.bake_navigation_mesh(false) 
	
	# Esperamos un frame físico de Godot
	await get_tree().process_frame
	
	var mapa = $NavigationRegion2D/MapaProcedural
	spawnear_jefe(mapa)

func spawnear_jefe(mapa: MapaProcedural) -> void:
	if escena_jefe:
		var jefe = escena_jefe.instantiate()
		
		# VALORES FIJOS DE TU NIVEL 1 (Garantiza que no den 0)
		var cols = 15
		var fils = 13
		var tam_celda = Vector2(128, 128) # Tamaño estándar de tus celdas (128x128)
		
		# Leemos el desplazamiento directamente del script de tu compañero
		# Si su script usa un valor diferente, lo ajustamos, pero 384 es el estándar para centrarlo
		var desplaza = Vector2(384, 0) 
		if mapa and mapa.desplazamiento_mapa != Vector2.ZERO:
			desplaza = mapa.desplazamiento_mapa
		
		# Fórmula matemática exacta de la cuadrícula procedural
		var offset_x = -((cols * tam_celda.x) / 2.0) + (tam_celda.x / 2.0) + desplaza.x
		var offset_y = -((fils * tam_celda.y) / 2.0) + (tam_celda.y / 2.0) + desplaza.y
		var compensacion_pivote = tam_celda / 2.0
		
		# Queremos posicionarlo en la esquina inferior derecha segura (celda 13, 11)
		var destino_x = cols - 2 # 13
		var destino_y = fils - 2 # 11
		
		# Cálculo final de la posición en el mundo 2D
		jefe.global_position = Vector2(
			offset_x + (destino_x * tam_celda.x), 
			offset_y + (destino_y * tam_celda.y)
		) + compensacion_pivote
		
		# RESPALDO: Si por alguna extraña razón matemática la posición sigue dando errónea,
		# calculamos una posición estática basada en el spawn de tu jugador (-320, -570)
		# Un mapa de 15x13 con celdas de 128 mide aprox 1920x1664. La esquina opuesta es:
		if jefe.global_position == Vector2.ZERO or jefe.global_position == compensacion_pivote:
			jefe.global_position = Vector2(1200, 500)
			print("Fallback activo: Posicionando al jefe en coordenada fija segura.")

		add_child(jefe)
		print("¡Jefe reubicado con éxito! Spawn real en: ", jefe.global_position)
