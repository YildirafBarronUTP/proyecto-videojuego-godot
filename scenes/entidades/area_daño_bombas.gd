extends Area2D

# Esta función recibe el impacto de la bomba y se lo pasa al jefe (su padre)
func recibir_dano(cantidad: int = 1) -> void:
	if get_parent().has_method("recibir_dano"):
		get_parent().recibir_dano(cantidad)
