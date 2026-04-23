extends Area2D

func _ready() -> void:
	var timer = $Timer
	if timer:
		timer.wait_time = 0.6
		timer.one_shot = true
		timer.timeout.connect(queue_free)
		timer.start()
	
	body_entered.connect(_on_body_entered)
	
	await get_tree().physics_frame
	verificar_jugadores_existentes()

func verificar_jugadores_existentes() -> void:
	var cuerpos = get_overlapping_bodies()
	for cuerpo in cuerpos:
		_on_body_entered(cuerpo)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_method("recibir_dano"):
		body.recibir_dano()