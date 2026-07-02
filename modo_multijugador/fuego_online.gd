extends Area2D

var tiempo_vida: float = 0.6
var es_visual_solo: bool = false
@onready var sonido_explosion: AudioStreamPlayer2D = $SonidoExplosion

func _ready() -> void:
	if not es_visual_solo:
		add_to_group("fuego_activo_online") 
	
	var timer = $Timer
	if timer:
		timer.wait_time = tiempo_vida
		timer.one_shot = true
		timer.start()
		
	if sonido_explosion and not sonido_explosion.playing:
		sonido_explosion.play()
	
	# El servidor es el único juez del daño
	if multiplayer.is_server():
		timer.timeout.connect(queue_free)
		
		if not es_visual_solo:
			body_entered.connect(_on_body_entered)
			await get_tree().physics_frame
			verificar_jugadores_existentes()
	else:
		if es_visual_solo:
			modulate.a = 0.7 

func verificar_jugadores_existentes() -> void:
	var cuerpos = get_overlapping_bodies()
	for cuerpo in cuerpos:
		_on_body_entered(cuerpo)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_method("recibir_dano"):
		body.recibir_dano()