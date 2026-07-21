extends StaticBody2D

# --- ESTADÍSTICAS DEL JEFE ---
var hp : int = 10                  # Requiere 10 impactos de bomba para ser derrotado
var es_invulnerable : bool = false # Evita sufrir múltiples golpes con la misma explosión

# --- REFERENCIAS EN EL INSPECTOR ---
@export var escena_bala : PackedScene
@export var escena_centella : PackedScene
@onready var sprite_jefe : AnimatedSprite2D = $AnimatedSprite2D
@onready var timer_ataque : Timer = $TimerAtaque
@onready var area_onda : Area2D = $AreaOndaChoque

func _ready() -> void:
	add_to_group("enemigos")
	sprite_jefe.play("idle")
	
	if area_onda:
		area_onda.monitoring = false
		area_onda.scale = Vector2.ZERO
		area_onda.body_entered.connect(_on_onda_body_entered)
	
	timer_ataque.wait_time = 2.5
	timer_ataque.timeout.connect(_on_timer_ataque_timeout)
	
	await get_tree().create_timer(1.0).timeout
	_on_timer_ataque_timeout()
	timer_ataque.start()

# --- SISTEMA DE DAÑO POR BOMBAS (10 IMPACTOS) ---
func recibir_dano(cantidad: int = 1) -> void:
	if hp <= 0 or es_invulnerable: return

	hp -= cantidad
	print("¡Bomba impactó al Núcleo Central! HP restante: ", hp)

	if hp <= 0:
		morir()
		return

	# Parpadeo rojo e invulnerabilidad de 1.0 segundo (Tomado de tu Jefe 1)
	es_invulnerable = true
	var tween = create_tween().set_loops(3)
	tween.tween_property(sprite_jefe, "modulate", Color(1, 0, 0, 1), 0.1)
	tween.tween_property(sprite_jefe, "modulate", Color(1, 1, 1, 1), 0.1)

	await get_tree().create_timer(1.0).timeout
	es_invulnerable = false

func _on_timer_ataque_timeout() -> void:
	if hp <= 0: return
	
	sprite_jefe.play("charge")
	await get_tree().create_timer(0.6).timeout
	sprite_jefe.play("idle")
	
	var ataque_aleatorio = randi() % 2
	if ataque_aleatorio == 0:
		mecanica_disparo_en_cruz()
	else:
		mecanica_centella_teledirigida()

func mecanica_disparo_en_cruz() -> void:
	print("Jefe: Lanzando Flechas/Balas en Cruz")
	var direcciones = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	
	for dir in direcciones:
		if escena_bala:
			var bala = escena_bala.instantiate()
			bala.global_position = global_position
			bala.direccion = dir
			get_parent().add_child(bala)

func mecanica_centella_teledirigida() -> void:
	if not escena_centella: return
		
	var lista_jugadores = get_tree().get_nodes_in_group("jugadores")
	if lista_jugadores.size() > 0:
		var posicion_voltio = lista_jugadores[0].global_position
		print("Jefe: ¡Fijando rayo en la posición de Voltio!")
		var rayo = escena_centella.instantiate()
		get_parent().add_child(rayo)
		rayo.global_position = posicion_voltio

func _on_onda_body_entered(body: Node) -> void:
	if body.is_in_group("jugadores") or body.is_in_group("jugador"):
		if body.has_method("recibir_dano"):
			body.recibir_dano(1)

func morir() -> void:
	timer_ataque.stop()
	print("¡El Núcleo Central ha colapsado!")
	queue_free()
