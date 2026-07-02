extends Area2D

@onready var mirilla : Sprite2D = $MirillaSprite
@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var collision : CollisionShape2D = $CollisionShape2D

@export var tiempo_advertencia : float = 1.0   # Tiempo que parpadea la mira a los pies de Voltio
@export var velocidad_caida : float = 2800.0   # Velocidad extrema para el efecto de impacto fulminante

var fase_caida : bool = false

func _ready() -> void:
	# Fase 1: La mirilla advierte en el suelo, el rayo se mantiene oculto
	collision.disabled = true
	sprite.visible = false
	mirilla.visible = true
	
	# Forzamos tamaño gigante por código para el rayo vertical
	sprite.scale = Vector2(3.5, 5.5)
	
	body_entered.connect(_on_body_entered)
	iniciar_secuencia_alerta()

func iniciar_secuencia_alerta() -> void:
	var tiempo_transcurrido = 0.0
	var intervalo_parpadeo = 0.1
	
	while tiempo_transcurrido < tiempo_advertencia:
		mirilla.visible = !mirilla.visible
		await get_tree().create_timer(intervalo_parpadeo).timeout
		tiempo_transcurrido += intervalo_parpadeo
		
	# Fase 2: Termina la advertencia y apagamos la mirilla
	mirilla.visible = false
	
	# Colocamos el rayo arriba en el cielo (fuera de pantalla)
	sprite.position.y = -800.0
	sprite.visible = true
	sprite.play("vuelo")
	
	fase_caida = true

func _physics_process(delta: float) -> void:
	if fase_caida:
		# Descenso supersónico hacia Y = 0 (el suelo)
		sprite.position.y += velocidad_caida * delta
		
		if sprite.position.y >= 0:
			fase_caida = false
			sprite.position.y = 0 
			
			# Encendemos la colisión en el suelo un breve instante
			collision.position.y = 0
			collision.disabled = false
			
			print("¡EL TRUENO HA IMPACTADO LA CASILLA!")
			await get_tree().create_timer(0.12).timeout
			queue_free()

func _on_body_entered(body: Node) -> void:
	if (body.is_in_group("jugadores") or body.is_in_group("jugador")) and body.has_method("recibir_dano"):
		body.recibir_dano(1)
		print("¡Voltio fue fulminado por el rayo vertical!")
