extends Node2D
class_name MapaProcedural

# --- CONFIGURACIÓN DEL MAPA ---
@export_category("Dimensiones")
@export var celda_size: Vector2 = Vector2(128, 128)
@export var columnas: int = 15 # Ancho total
@export var filas: int = 13    # Alto total (Ajustado a 13 para no ser chato)

# Desplazamiento exacto de 3 columnas (384px) hacia la derecha para dejar espacio a la UI.
# Al ser múltiplo de 128, la lógica de centrado de las bombas no se rompe.
@export var desplazamiento_mapa: Vector2 = Vector2(384, 0) 

@export_category("Generación")
@export var probabilidad_contenedor: float = 0.64 

# --- REFERENCIAS A ESCENAS ---
@export_category("Bloques")
@export var escena_muro: PackedScene
@export var escena_pilar: PackedScene
@export var escena_contenedor: PackedScene

func _ready() -> void:
	randomize() 
	generar_cuadricula()

func generar_cuadricula() -> void:
	# Calculamos el origen (0,0) del mapa y le aplicamos el desplazamiento para la UI
	var offset_x = -((columnas * celda_size.x) / 2.0) + (celda_size.x / 2.0) + desplazamiento_mapa.x
	var offset_y = -((filas * celda_size.y) / 2.0) + (celda_size.y / 2.0) + desplazamiento_mapa.y
	
	# LA SOLUCIÓN: Sumamos la mitad exacta de la celda (64px) para alinear 
	# los bloques generados con el centro geométrico de la cuadrícula
	var compensacion_pivote = celda_size / 2.0 
	
	for x in range(columnas):
		for y in range(filas):
			# Coordenada matemática exacta anclada al centro real
			var posicion_real = Vector2(offset_x + (x * celda_size.x), offset_y + (y * celda_size.y)) + compensacion_pivote
			
			# 1. BORDES DEL MAPA (Muros exteriores)
			if x == 0 or x == columnas - 1 or y == 0 or y == filas - 1:
				instanciar_bloque(escena_muro, posicion_real)
				continue
				
			# 2. PILARES INDESTRUCTIBLES
			if x % 2 == 0 and y % 2 == 0:
				instanciar_bloque(escena_pilar, posicion_real)
				continue
				
			# 3. ZONA SEGURA DE JUGADORES ("L")
			if es_zona_segura(x, y):
				continue 
				
			# 4. CONTENEDORES DESTRUCTIBLES
			if randf() <= probabilidad_contenedor:
				instanciar_bloque(escena_contenedor, posicion_real)

func es_zona_segura(x: int, y: int) -> bool:
	var segura = false
	# Jugador 1 (Arriba Izquierda)
	if (x == 1 and y == 1) or (x == 2 and y == 1) or (x == 1 and y == 2): segura = true
	# Jugador 2 (Arriba Derecha)
	if (x == columnas - 2 and y == 1) or (x == columnas - 3 and y == 1) or (x == columnas - 2 and y == 2): segura = true
	# Jugador 3 (Abajo Izquierda)
	if (x == 1 and y == filas - 2) or (x == 2 and y == filas - 2) or (x == 1 and y == filas - 3): segura = true
	# Jugador 4 (Abajo Derecha)
	if (x == columnas - 2 and y == filas - 2) or (x == columnas - 3 and y == filas - 2) or (x == columnas - 2 and y == filas - 3): segura = true
	return segura

func instanciar_bloque(escena: PackedScene, pos: Vector2) -> void:
	if escena == null:
		return
	var bloque = escena.instantiate()
	bloque.position = pos
	add_child(bloque)