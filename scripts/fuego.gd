extends Area2D

var tiempo_vida: float = 0.6
var es_visual_solo: bool = false

func _ready() -> void:
	if not es_visual_solo:
		add_to_group("fuego_activo") # Solo el fuego letal asusta a la IA
	
	var timer = $Timer
	if timer:
		timer.wait_time = tiempo_vida
		timer.one_shot = true
		timer.timeout.connect(queue_free)
		timer.start()
	
	if not es_visual_solo:
		body_entered.connect(_on_body_entered)
		await get_tree().physics_frame
		verificar_jugadores_existentes()
	else:
		# Easter egg: Hacemos que el fuego "de altura" sea un poco transparente
		modulate.a = 0.7 

func get_tiempo_restante() -> float:
	if has_node("Timer"):
		return $Timer.time_left
	return 0.0

func verificar_jugadores_existentes() -> void:
	var cuerpos = get_overlapping_bodies()
	for cuerpo in cuerpos:
		_on_body_entered(cuerpo)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_method("recibir_dano"):
		body.recibir_dano()