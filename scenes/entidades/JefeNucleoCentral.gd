extends StaticBody2D

var hp : int = 60

# --- REFERENCIAS EN EL INSPECTOR ---
@export var escena_bala : PackedScene # Aquí arrastrarás tu 'BalaJefe.tscn'
@export var escena_centella : PackedScene # Aquí arrastrarás tu 'CentellaTeledirigida.tscn'
@onready var sprite_jefe : AnimatedSprite2D = $AnimatedSprite2D
@onready var timer_ataque : Timer = $TimerAtaque
@onready var area_onda : Area2D = $AreaOndaChoque

func _ready() -> void:
	# El jefe inicia latiendo en su estado pasivo
	sprite_jefe.play("idle")
	
	# Aseguramos que la onda expansiva empiece totalmente inactiva y oculta
	if area_onda:
		area_onda.monitoring = false
		area_onda.scale = Vector2.ZERO
		area_onda.body_entered.connect(_on_onda_body_entered)
	
	# Configuramos el temporizador para los ataques siguientes
	timer_ataque.wait_time = 2.5
	timer_ataque.timeout.connect(_on_timer_ataque_timeout)
	
	# --- AJUSTE DE TIEMPO INICIAL ---
	await get_tree().create_timer(1.0).timeout
	
	# Forzamos a la IA a ejecutar su primer ataque de inmediato
	_on_timer_ataque_timeout()
	timer_ataque.start()

func recibir_dano(cantidad: int) -> void:
	hp -= cantidad
	print("Jefe dañado. HP restante: ", hp)
	if hp <= 0:
		morir()

func _on_timer_ataque_timeout() -> void:
	if hp <= 0: return
	
	# Anticipación de ataque: reproduce 'charge' por 0.6 segundos
	sprite_jefe.play("charge")
	await get_tree().create_timer(0.6).timeout
	sprite_jefe.play("idle")
	
	# IA TEMPORAL: Elige al azar entre Disparo en Cruz (0) y Centella Teledirigida (1)
	var ataque_aleatorio = randi() % 2
	if ataque_aleatorio == 0:
		mecanica_disparo_en_cruz()
	else:
		mecanica_centella_teledirigida()

# --- MECÁNICA 1: DISPARO EN CRUZ ---
func mecanica_disparo_en_cruz() -> void:
	print("Jefe: Lanzando Flechas en Cruz Cardinal")
	var direcciones = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	
	for dir in direcciones:
		if escena_bala:
			var bala = escena_bala.instantiate()
			bala.global_position = global_position
			bala.direccion = dir
			get_parent().add_child(bala)

# --- RF-1.8: MECÁNICA 2: ONDA DE SOBRECARGA ---
func mecanica_onda_sobrecarga() -> void:
	if not area_onda: return
	print("Jefe: ¡Liberando Onda de Sobrecarga circular!")
	
	area_onda.scale = Vector2.ZERO
	area_onda.monitoring = true
	
	var tween = create_tween()
	tween.tween_property(area_onda, "scale", Vector2(5.5, 5.5), 1.5).set_trans(Tween.TRANS_LINEAR)
	
	await tween.finished
	
	area_onda.monitoring = false
	area_onda.scale = Vector2.ZERO

# --- DETECCIÓN DE DAÑO DE LA ONDA ---
func _on_onda_body_entered(body: Node) -> void:
	if body.is_in_group("jugadores") or body.is_in_group("jugador"):
		if body.has_method("recibir_dano"):
			body.recibir_dano(1)
			print("¡La Onda de Sobrecarga golpeó a Voltio!")
		
	elif body.is_in_group("contenedores") or "contenedor" in body.name.to_lower():
		if body.has_method("destruir"):
			body.destruir()
		else:
			body.queue_free()
		print("Contenedor desintegrado por la onda de energía.")

# --- MECÁNICA 3: CENTELLA TELEDIRIGIDA ---
func mecanica_centella_teledirigida() -> void:
	if not escena_centella:
		print("¡ALERTA CRÍTICA!: La casilla 'Escena Centella' está VACÍA en el Inspector del Jefe.")
		return
		
	var lista_jugadores = get_tree().get_nodes_in_group("jugadores")
	if lista_jugadores.size() > 0:
		var posicion_voltio = lista_jugadores[0].global_position
		
		print("Jefe: ¡Fijando rayo fulminante en la posición de Voltio!")
		var rayo = escena_centella.instantiate()
		
		get_parent().add_child(rayo)
		rayo.global_position = posicion_voltio
	else:
		print("¡ALERTA DE DEPURACIÓN!: El jefe intentó atacar pero el grupo 'jugadores' regresó vacío.")
	
func morir() -> void:
	timer_ataque.stop()
	print("¡El Núcleo Central ha colapsado!")
	queue_free()
