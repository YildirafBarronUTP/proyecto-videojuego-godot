extends Node2D
class_name Bombardeo

@export var escena_fuego: PackedScene
@export var escena_pilar_agrietado: PackedScene # La crearemos luego, por ahora déjala vacía

var posicion_objetivo: Vector2

func _ready() -> void:
	global_position = posicion_objetivo
	
	# El retraso del satélite
	await get_tree().create_timer(1.0).timeout
	detonar()

func detonar() -> void:
	# El bombardeo aéreo siempre tiene rango 1 (Centro + 4 adyacentes)
	var celdas = [
		Vector2.ZERO,
		Vector2(0, -128.0), # Arriba
		Vector2(0, 128.0),  # Abajo
		Vector2(-128.0, 0), # Izquierda
		Vector2(128.0, 0)   # Derecha
	]
	
	for offset in celdas:
		var pos_evaluar = global_position + offset
		procesar_casilla(pos_evaluar, offset == Vector2.ZERO)
		
	queue_free()

func procesar_casilla(pos: Vector2, es_centro: bool) -> void:
	var es_visual = false
	var pilar_para_agrietar = null
	
	# Usamos el escáner de físicas de Godot para ver qué hay en esa coordenada exacta
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var resultados = space_state.intersect_point(query)
	
	for hit in resultados:
		var collider = hit.collider
		if collider.is_in_group("muros"):
			es_visual = true
		elif collider.is_in_group("pilares"):
			es_visual = true
			if es_centro:
				pilar_para_agrietar = collider
		elif collider.is_in_group("contenedores"):
			# El misil atraviesa y destruye las cajas instantáneamente
			collider.recibir_dano(99) 
	
	# Generamos el fuego
	if escena_fuego:
		var nuevo_fuego = escena_fuego.instantiate()
		nuevo_fuego.global_position = pos
		nuevo_fuego.es_visual_solo = es_visual
		get_parent().add_child(nuevo_fuego)
		
	# Lógica del Pilar Agrietado (Impacto Directo)
	if pilar_para_agrietar != null and escena_pilar_agrietado != null:
		var pos_pilar = pilar_para_agrietar.global_position
		pilar_para_agrietar.queue_free()
		var nuevo_pilar = escena_pilar_agrietado.instantiate()
		nuevo_pilar.global_position = pos_pilar
		get_parent().call_deferred("add_child", nuevo_pilar)
