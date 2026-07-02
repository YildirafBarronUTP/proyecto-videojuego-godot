extends MapaProcedural
class_name MapaProceduralJefeFinal

@export_category("Configuración del Jefe")
@export var escena_jefe : PackedScene

func _ready() -> void:
	randomize()
	# NO llamamos a super._ready() para evitar el bucle con el bug de pilares del padre.
	# En su lugar, ejecutamos nuestra propia generación corregida para el Boss Final:
	generar_cuadricula_jefe()
	spawnear_jefe_en_centro()

func generar_cuadricula_jefe() -> void:
	# Mantenemos intacta tu fórmula matemática de posicionamiento
	var offset_x = -((columnas * celda_size.x) / 2.0) + (celda_size.x / 2.0) + desplazamiento_mapa.x
	var offset_y = -((filas * celda_size.y) / 2.0) + (celda_size.y / 2.0) + desplazamiento_mapa.y
	var compensacion_pivote = celda_size / 2.0 
	
	# El centro de 15x13 celdas es la columna 7, fila 6
	var centro_x : int = columnas / 2
	var centro_y : int = filas / 2

	for x in range(columnas):
		for y in range(filas):
			var posicion_real = Vector2(offset_x + (x * celda_size.x), offset_y + (y * celda_size.y)) + compensacion_pivote
			
			# 1. Prioridad 1: Dibujar los muros perimetrales exteriores
			if x == 0 or x == columnas - 1 or y == 0 or y == filas - 1:
				instanciar_bloque(escena_muro, posicion_real)
				continue
				
			# 2. Prioridad 2 (CORRECCIÓN CRÍTICA): Si es la zona de 5x5 del jefe o las esquinas de Voltio, LIMPIAR TOTALMENTE
			var es_zona_jefe = x >= (centro_x - 2) and x <= (centro_x + 2) and y >= (centro_y - 2) and y <= (centro_y + 2)
			if es_zona_jefe or super.es_zona_segura(x, y):
				continue # Saltamos la celda por completo (no se creará pilar ni caja aquí)

			# 3. Prioridad 3: Si no es zona segura, colocamos las rejillas indestructibles (pilares)
			if x % 2 == 0 and y % 2 == 0:
				instanciar_bloque(escena_pilar, posicion_real)
				continue
				
			# 4. Prioridad 4: Colar cajas destruibles en los espacios restantes del pasillo
			if randf() <= probabilidad_contenedor:
				instanciar_bloque(escena_contenedor, posicion_real)

func spawnear_jefe_en_centro() -> void:
	if escena_jefe == null:
		print("Error: Falta asignar la escena del jefe final en el Inspector del mapa.")
		return
		
	var centro_x_idx : int = columnas / 2
	var centro_y_idx : int = filas / 2
	
	var offset_x = -((columnas * celda_size.x) / 2.0) + (celda_size.x / 2.0) + desplazamiento_mapa.x
	var offset_y = -((filas * celda_size.y) / 2.0) + (celda_size.y / 2.0) + desplazamiento_mapa.y
	var compensacion_pivote = celda_size / 2.0
	
	var posicion_centro_real = Vector2(
		offset_x + (centro_x_idx * celda_size.x), 
		offset_y + (centro_y_idx * celda_size.y)
	) + compensacion_pivote
	
	# Instanciamos al jefe en el centro de la grilla limpia
	var jefe = escena_jefe.instantiate()
	jefe.global_position = posicion_centro_real
	add_child(jefe)
	
	print("¡IA del Núcleo Central acoplada y área de 5x5 completamente despejada!")
