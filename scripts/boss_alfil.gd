extends CharacterBody2D
class_name BossAlfil

@export_category("Estadísticas")
@export var vidas: int = 1
@export var velocidad: float = 80.0 
@export var escena_plasma_equis: PackedScene 

@export_category("Habilidades")
@export var tiempo_solido: float = 10.0 
@export var tiempo_fantasma: float = 2.0 

@onready var audio_fantasma: AudioStreamPlayer2D = $AudioFantasma
@export var audio_romper: AudioStreamPlayer2D

var invulnerable: bool = false
var en_carga_de_ataque: bool = false
var jugador_ref: CharacterBody2D

func _ready() -> void:
	add_to_group("jefes")
	add_to_group("enemigos") 
	
	if has_node("TimerAtaque"):
		$TimerAtaque.timeout.connect(_on_timer_ataque_timeout)
	
	jugador_ref = get_tree().get_first_node_in_group("jugadores")
	iniciar_ciclo_fase()

func _physics_process(_delta: float) -> void:
	if vidas <= 0 or en_carga_de_ataque or jugador_ref == null:
		return
		
	# 1. Movimiento
	var direccion = global_position.direction_to(jugador_ref.global_position)
	velocity = direccion * velocidad
	move_and_slide()
	
	# 2. MODO BULLDOZER
	if get_collision_mask_value(1) == true: 
		for i in get_slide_collision_count():
			var colision = get_slide_collision(i)
			var objeto = colision.get_collider()
			
			if objeto != null and objeto.is_in_group("contenedores"):
				if objeto.has_method("recibir_dano"):
					objeto.recibir_dano(1)
					
					if audio_romper != null:
						if not audio_romper.playing:
							audio_romper.play()
						
	# 3. Animaciones
	if abs(velocity.x) > abs(velocity.y):
		$AnimatedSprite2D.play("walkRight")
		$AnimatedSprite2D.flip_h = (velocity.x < 0) 
	else:
		$AnimatedSprite2D.flip_h = false
		if velocity.y < 0:
			$AnimatedSprite2D.play("walkUp")
		elif velocity.y > 0:
			$AnimatedSprite2D.play("walkDown")

# --- DAÑO RECIBIDO POR BOMBAS ---
func recibir_dano(cantidad: int = 1) -> void:
	if invulnerable or vidas <= 0: return
		
	vidas -= cantidad
	invulnerable = true
	
	var vel_original = velocidad
	velocidad = 0.0 
	
	var tween = create_tween()
	tween.tween_property($AnimatedSprite2D, "modulate", Color.RED, 0.1)
	tween.tween_property($AnimatedSprite2D, "modulate", Color.WHITE, 0.1)
	tween.set_loops(7) 
	
	# ¡PARCHE DE SEGURIDAD! Antes de pausar, revisamos si seguimos vivos
	if get_tree() == null: return
	await get_tree().create_timer(1.5).timeout
	
	# Y volvemos a revisar al despertar por si nos borraron mientras esperábamos
	if get_tree() == null: return
	
	velocidad = vel_original 
	invulnerable = false
	
	if vidas <= 0: 
		mostrar_mensaje_victoria() 

# --- ATAQUE DEL RAYO ---
func _on_timer_ataque_timeout() -> void:
	if en_carga_de_ataque or vidas <= 0: return
	en_carga_de_ataque = true
	$AnimatedSprite2D.modulate = Color.YELLOW 
	
	if get_tree() == null: return
	await get_tree().create_timer(2.0).timeout 
	
	# Si lo mataron mientras cargaba el rayo, cancelamos el ataque
	if get_tree() == null or vidas <= 0: return
	
	if get_collision_mask_value(1) == true:
		$AnimatedSprite2D.modulate = Color.WHITE
	else:
		$AnimatedSprite2D.modulate = Color(1, 1, 1, 0.5)
	
	if escena_plasma_equis != null:
		var ataque = escena_plasma_equis.instantiate()
		ataque.global_position = global_position
		get_parent().add_child(ataque)
		
	en_carga_de_ataque = false

# --- CICLO FANTASMA ---
func iniciar_ciclo_fase() -> void:
	while is_instance_valid(self) and vidas > 0:
		set_collision_mask_value(1, true)
		if not en_carga_de_ataque: $AnimatedSprite2D.modulate.a = 1.0
		
		if get_tree() == null: break
		await get_tree().create_timer(tiempo_solido).timeout
		if vidas <= 0 or get_tree() == null or not is_instance_valid(self): break
		
		set_collision_mask_value(1, false)
		if audio_fantasma != null:
			audio_fantasma.play() 
			
		if not en_carga_de_ataque: $AnimatedSprite2D.modulate.a = 0.5
		
		if get_tree() == null: break
		await get_tree().create_timer(tiempo_fantasma).timeout

# --- GOLPE AL JUGADOR ---
func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("jugadores"):
		if body.has_method("recibir_dano"):
			body.recibir_dano() 
			
			if body.has_method("activar_efecto_dano"):
				body.activar_efecto_dano()

# --- VICTORIA CINEMATOGRÁFICA ---
func mostrar_mensaje_victoria() -> void:
	if get_tree() == null or get_parent() == null: return
	
	set_physics_process(false)
	hide() 
	
	for nodo in get_parent().get_children():
		if nodo is AudioStreamPlayer and nodo.playing:
			nodo.stop()
			
	# Escudo anti-errores: Revisamos si el archivo existe antes de cargarlo
	var cancion_victoria = load("res://sounds/soundtrack/Nivel2/ganar.wav")
	if cancion_victoria != null:
		var audio_victoria = AudioStreamPlayer.new()
		audio_victoria.stream = cancion_victoria
		get_parent().add_child(audio_victoria)
		audio_victoria.play()
	else:
		print("¡Ojo! Falta tu archivo victoria.wav, pasando en silencio...")
	
	var canvas = CanvasLayer.new()
	get_tree().root.add_child(canvas)
	
	var fondo = ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.75) 
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT) 
	canvas.add_child(fondo)
	
	var texto = Label.new()
	texto.text = "¡ALFIL DESTRUIDO!\n\nAvanzando al Nivel 3..."
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto.set_anchors_preset(Control.PRESET_FULL_RECT)
	texto.add_theme_font_size_override("font_size", 45) 
	canvas.add_child(texto)
	
	if get_tree() == null: return
	await get_tree().create_timer(4.0).timeout
	
	if get_tree() != null:
		get_tree().change_scene_to_file("res://scenes/niveles/nivel3/nivel_3.tscn")
		canvas.queue_free()
		queue_free()
