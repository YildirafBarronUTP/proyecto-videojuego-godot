extends StaticBody2D

@onready var timer: Timer = $Timer
@onready var area_deteccion: Area2D = $AreaDeteccion
# Referenciamos la caja de colisión sólida de la bomba (el muro)
@onready var colision_solida: CollisionShape2D = $CollisionShape2D 

func _ready() -> void:
	# 1. Apagamos el muro sólido INMEDIATAMENTE al nacer para que no empuje a nadie
	colision_solida.disabled = true
	
	timer.timeout.connect(_on_timer_timeout)
	
	# 2. Esperamos el frame de físicas para que el radar lea tranquilamente
	await get_tree().physics_frame
	
	var cuerpos_dentro = area_deteccion.get_overlapping_bodies()
	for cuerpo in cuerpos_dentro:
		if cuerpo is CharacterBody2D:
			# Les damos el "pase VIP" a los jugadores que están tocando el radar
			add_collision_exception_with(cuerpo)
	
	# 3. Encendemos el muro sólido de nuevo. Como ya tienen su pase VIP, no los botará.
	colision_solida.disabled = false
	
	area_deteccion.body_exited.connect(_on_cuerpo_salio)

func _on_cuerpo_salio(body: Node2D) -> void:
	if body is CharacterBody2D:
		remove_collision_exception_with(body)

func _on_timer_timeout() -> void:
	print("¡Boom! La bomba detonó en: ", global_position)
	queue_free()