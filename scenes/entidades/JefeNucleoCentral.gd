extends StaticBody2D

# --- ESTADÍSTICAS DEL JEFE ---
var hp : int = 10                  # Requiere 10 impactos de bomba para ser derrotado
var es_invulnerable : bool = false # Evita sufrir múltiples golpes con la misma explosión

# --- REFERENCIAS EN EL INSPECTOR ---
@export var escena_bala : PackedScene
@export var escena_centella : PackedScene
@export var ruta_menu_principal : String = "res://scenes/ui/menu_principal.tscn"

@onready var sprite_jefe : AnimatedSprite2D = $AnimatedSprite2D
@onready var timer_ataque : Timer = $TimerAtaque
@onready var area_onda : Area2D = $AreaOndaChoque

func _ready() -> void:
	add_to_group("enemigos")
	add_to_group("jefe")
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

	# Parpadeo rojo e invulnerabilidad de 1.0 segundo
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
	if hp <= 0: return
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
	if lista_jugadores.is_empty():
		lista_jugadores = get_tree().get_nodes_in_group("jugador")
		
	if not lista_jugadores.is_empty():
		var posicion_voltio = lista_jugadores[0].global_position
		print("Jefe: ¡Fijando rayo en la posición de Voltio!")
		var rayo = escena_centella.instantiate()
		get_parent().add_child(rayo)
		rayo.global_position = posicion_voltio

func _on_onda_body_entered(body: Node) -> void:
	if body.is_in_group("jugadores") or body.is_in_group("jugador"):
		if body.has_method("recibir_dano"):
			body.recibir_dano()

func morir() -> void:
	remove_from_group("enemigos")
	remove_from_group("jefe")
	if timer_ataque:
		timer_ataque.stop()
	print("¡El Núcleo Central ha sido destruido!")
	mostrar_mensaje_victoria()

# --- VICTORIA FINAL Y REGRESO AL MENÚ ---
func mostrar_mensaje_victoria() -> void:
	if get_tree() == null or get_parent() == null: return
	
	set_physics_process(false)
	hide() 
	
	# 1. Detener la música de fondo del mapa del jefe
	for nodo in get_parent().get_children():
		if (nodo is AudioStreamPlayer or nodo is AudioStreamPlayer2D) and nodo.playing:
			nodo.stop()
			
	# 2. Reproducir audio de victoria
	var cancion_victoria = load("res://sounds/soundtrack/Nivel2/ganar.wav")
	if cancion_victoria != null:
		var audio_victoria = AudioStreamPlayer.new()
		audio_victoria.stream = cancion_victoria
		get_parent().add_child(audio_victoria)
		audio_victoria.play()
	else:
		print("¡Ojo! Falta tu archivo ganar.wav, avanzando en silencio...")
	
	# 3. Mostrar pantalla de felicitaciones
	var canvas = CanvasLayer.new()
	get_tree().root.add_child(canvas)
	
	var fondo = ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.8) 
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT) 
	canvas.add_child(fondo)
	
	var texto = Label.new()
	texto.text = "¡NÚCLEO CENTRAL DESTRUIDO!\n\n¡HAS COMPLETADO EL JUEGO!\n\nRegresando al Menú Principal..."
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto.set_anchors_preset(Control.PRESET_FULL_RECT)
	texto.add_theme_font_size_override("font_size", 42) 
	canvas.add_child(texto)
	
	if get_tree() == null: return
	await get_tree().create_timer(4.0).timeout
	
	if get_tree() != null:
		# 4. Comprobación flexible de la ruta del Menú Principal
		var destino = ruta_menu_principal
		if not ResourceLoader.exists(destino):
			if ResourceLoader.exists("res://scenes/ui/menu_principal.tscn"):
				destino = "res://scenes/ui/menu_principal.tscn"
			elif ResourceLoader.exists("res://scenes/menu_principal.tscn"):
				destino = "res://scenes/menu_principal.tscn"
				
		get_tree().change_scene_to_file(destino)
		canvas.queue_free()
		queue_free()
