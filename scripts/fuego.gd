extends Area2D

func _ready() -> void:
	# El fuego desaparece automáticamente después de 0.6 segundos
	var timer = $Timer
	if timer:
		timer.wait_time = 0.6
		timer.one_shot = true
		timer.timeout.connect(queue_free) # Se auto-destruye
		timer.start()
	
	# Detectar al instante si nació sobre un jugador, y también a los que entren caminando
	body_entered.connect(_on_body_entered)
	
	# Pequeño retraso de un frame para garantizar que las colisiones estén cargadas
	await get_tree().physics_frame
	verificar_jugadores_existentes()

func verificar_jugadores_existentes() -> void:
	var cuerpos = get_overlapping_bodies()
	for cuerpo in cuerpos:
		_on_body_entered(cuerpo)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_method("recibir_dano"):
		body.recibir_dano()