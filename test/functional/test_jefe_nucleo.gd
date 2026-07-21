extends GutTest

var EscenaJefe = preload("res://scenes/entidades/JefeNucleoCentral.tscn")
var jefe: Node2D = null

func before_each():
	jefe = EscenaJefe.instantiate()
	add_child_autoqfree(jefe)

func test_jefe_resistencia_inicial():
	assert_eq(jefe.hp, 10, "El Núcleo Central debe iniciar con 10 de salud.")

func test_invulnerabilidad_temporal_jefe():
	# Primer golpe
	jefe.recibir_dano(1)
	assert_eq(jefe.hp, 9, "El jefe debe quedar con 9 HP tras el primer golpe.")
	assert_true(jefe.es_invulnerable, "El jefe debe volverse invulnerable inmediatamente.")
	
	# Intento de golpe inmediato durante la invulnerabilidad
	jefe.recibir_dano(1)
	assert_eq(jefe.hp, 9, "El golpe recibido durante la invulnerabilidad debe ignorarse.")
