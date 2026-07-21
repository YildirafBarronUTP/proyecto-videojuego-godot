extends GutTest

var EscenaJugador = preload("res://scenes/entidades/jugador.tscn")
var EscenaBala = preload("res://scenes/entidades/BalaJefe.tscn")

var jugador: Node2D = null
var bala: Node2D = null

func before_each():
	# Instanciamos a Voltio y la bala
	jugador = EscenaJugador.instantiate()
	add_child_autoqfree(jugador)
	jugador.global_position = Vector2(100, 100)
	
	bala = EscenaBala.instantiate()
	add_child_autoqfree(bala)
	bala.global_position = Vector2(100, 100)

func test_impacto_bala_resta_vida_a_voltio():
	var vidas_iniciales = jugador.vidas
	
	if bala.has_method("_on_body_entered"):
		bala._on_body_entered(jugador)
		
	assert_eq(jugador.vidas, vidas_iniciales - 1, "Voltio debería haber perdido 1 vida tras el impacto.")

func test_bala_se_destruye_tras_impactar():
	if bala.has_method("_on_body_entered"):
		bala._on_body_entered(jugador)
		
	# Damos un pequeño margen para procesar queue_free()
	await wait_seconds(0.1)
	
	# Usamos assert_freed() de GUT que verifica de forma segura si el nodo fue liberado
	assert_freed(bala, "La bala debe destruirse al colisionar con Voltio.")
