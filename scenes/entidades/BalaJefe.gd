extends Area2D

@export var velocidad : float = 450.0
var direccion : Vector2 = Vector2.RIGHT

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Orientación física del proyectil hacia su trayectoria
	rotation = direccion.angle()
	if sprite:
		sprite.play("vuelo")
	
	body_entered.connect(_on_body_entered)
	
	# Destrucción de seguridad a los 5 segundos si sale del mapa
	await get_tree().create_timer(5.0).timeout
	queue_free()

func _process(delta: float) -> void:
	global_position += direccion * velocidad * delta

func _on_body_entered(body: Node) -> void:
	# 1. Ignorar colisión con el propio jefe al nacer
	if body.is_in_group("jefe") or "jefe" in body.name.to_lower() or "nucleo" in body.name.to_lower():
		return
		
	# 2. Ignorar pilares indestructibles
	if body.is_in_group("pilares") or "pilar" in body.name.to_lower():
		return
		
	# 3. IMPACTO EN VOLTIO
	if body.is_in_group("jugadores") or body.is_in_group("jugador"):
		print("¡Impacto confirmado sobre Voltio!")
		if body.has_method("recibir_dano"):
			body.recibir_dano() # 👈 Cambiado: Se quita el (1)
		elif "vidas" in body:
			body.vidas -= 1
		
		queue_free()
		return
		
	# 4. Si choca contra muros exteriores o contenedores
	print("Bala destruida por chocar contra: ", body.name)
	queue_free()
