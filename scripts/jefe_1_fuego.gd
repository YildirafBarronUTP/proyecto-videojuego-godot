extends Area2D

@onready var timer: Timer = $Timer

func _ready() -> void:
	add_to_group("fuego_activo")
	set_collision_mask_value(6, true)
	
	timer.wait_time = 7.0
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	timer.start()
	
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	await get_tree().create_timer(0.05).timeout
	
	for cuerpo in get_overlapping_bodies():
		_procesar_impacto(cuerpo)
		
	for area in get_overlapping_areas():
		_procesar_impacto(area)

func _on_body_entered(body: Node2D) -> void:
	_procesar_impacto(body)

func _on_area_entered(area: Area2D) -> void:
	_procesar_impacto(area)

func _procesar_impacto(objeto: Node2D) -> void:
	if objeto.is_in_group("jugadores") and objeto.has_method("recibir_dano"):
		var vidas_antes = objeto.vidas if "vidas" in objeto else 0
		objeto.recibir_dano()
		var vidas_despues = objeto.vidas if "vidas" in objeto else 0
		
		if vidas_antes == 0 or vidas_despues < vidas_antes:
			var jefe = get_tree().get_first_node_in_group("jefe_verdugo")
			if jefe != null and jefe.has_method("reproducir_risa_aleatoria"):
				jefe.reproducir_risa_aleatoria()
		
	elif objeto.is_in_group("contenedores") or "hp" in objeto:
		if objeto.has_method("recibir_dano"):
			objeto.recibir_dano(1)
		elif "hp" in objeto:
			objeto.hp -= 1
			if objeto.hp <= 0:
				if objeto.has_method("generar_bonificacion"):
					objeto.generar_bonificacion()
				objeto.queue_free()
				
	elif objeto.is_in_group("bonificaciones"):
		print("🔥 ¡Confirmado! El fuego calcinó el área de bonificación.")
		objeto.queue_free()

func _on_timer_timeout() -> void:
	queue_free()
