extends Area2D

@onready var timer: Timer = $Timer

func _ready() -> void:
	# Nos añadimos al grupo para que la IA registre dónde hay peligro activo
	add_to_group("fuego_activo")
	
	# Configuramos el temporizador que ya creaste a 5 segundos y lo encendemos
	timer.wait_time = 5.0
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	timer.start()
	
	# Conectamos la señal nativa de colisión de Area2D para detectar cuerpos
	body_entered.connect(_on_body_entered)
	
	# Hacemos un chequeo rápido inicial por si se instanció justo encima de algo
	await get_tree().create_timer(0.05).timeout
	for cuerpo in get_overlapping_bodies():
		_procesar_impacto(cuerpo)

func _on_body_entered(body: Node2D) -> void:
	_procesar_impacto(body)

func _procesar_impacto(objeto: Node2D) -> void:
	# 1. Si toca al jugador
	if objeto.is_in_group("jugadores") and objeto.has_method("recibir_dano"):
		objeto.recibir_dano()
		
	# 2. Si toca un contenedor destruible (caja)
	elif objeto.is_in_group("contenedores") or "hp" in objeto:
		if objeto.has_method("recibir_dano"):
			objeto.recibir_dano(1)
		elif "hp" in objeto:
			objeto.hp -= 1
			if objeto.hp <= 0:
				if objeto.has_method("generar_bonificacion"):
					objeto.generar_bonificacion()
				objeto.queue_free()

func _on_timer_timeout() -> void:
	# Pasados los 5 segundos, el fuego se desvanece de la escena
	queue_free()
