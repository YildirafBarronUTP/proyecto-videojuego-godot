extends StaticBody2D

var hp: int = 1
@onready var sprite: Sprite2D = $Sprite2D
@onready var colision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	# Lo metemos en un grupo propio, o puedes tratarlo como contenedor si quieres que suelte cosas
	add_to_group("pilares_agrietados") 

func recibir_dano(cantidad: int) -> void:
	hp -= cantidad
	if hp <= 0:
		destruir()

func destruir() -> void:
	sprite.hide()
	colision.set_deferred("disabled", true)
	
	# Liberamos el GPS matemático para la IA
	var nivel_principal = get_tree().current_scene
	if nivel_principal and "astar_grid" in nivel_principal and nivel_principal.astar_grid != null:
		var celda_liberada = nivel_principal.pos_a_celda(global_position)
		nivel_principal.astar_grid.set_point_solid(celda_liberada, false)
		
	queue_free()