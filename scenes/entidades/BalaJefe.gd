extends Area2D

@export var velocidad : float = 450.0
var direccion : Vector2 = Vector2.RIGHT

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Hace que el sprite rote físicamente hacia el vector cardinal inyectado por el jefe
	rotation = direccion.angle()
	if sprite:
		sprite.play("vuelo")
	
	# Conectamos las señales de colisión
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	# Movimiento rectilíneo constante en base a la dirección
	global_position += direccion * velocidad * delta

func _on_body_entered(body: Node) -> void:
	# 1. CORRECCIÓN CRÍTICA: Si la bala toca al propio jefe al nacer, ignoramos el impacto
	if body.is_in_group("jefe") or "jefe" in body.name.to_lower() or "nucleo" in body.name.to_lower():
		return
		
	# 2. NUEVA FILTRACIÓN: Si la bala toca un pilar indestructible, lo ignora y sigue de largo
	if body.is_in_group("pilares") or "pilar" in body.name.to_lower():
		return
		
	# DEPURACIÓN: Esto nos escribirá en la consola qué objeto exacto tocó la bala si se rompe antes de tiempo
	print("Bala destruida por chocar contra: ", body.name)
		
	# 3. Si toca a Voltio (Jugador), le resta 1 vida y se destruye
	if body.is_in_group("jugador") and body.has_method("recibir_dano"):
		body.recibir_dano(1)
		print("¡Voltio fue impactado por una flecha rosa!")
		queue_free()
		return
		
	# 4. Si choca contra cualquier otra estructura sólida (como los muros perimetrales)
	queue_free()
