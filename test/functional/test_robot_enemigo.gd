extends GutTest

var EscenaRobot = preload("res://scenes/entidades/RobotEnemigo.tscn")
var robot: CharacterBody2D = null

func before_each():
	robot = EscenaRobot.instantiate()
	add_child_autoqfree(robot)

func test_salud_inicial_robot():
	assert_eq(robot.hp, 3, "El robot cazador debe iniciar con 3 puntos de vida.")

func test_robot_recibe_dano_de_bomba():
	robot.recibir_dano(1)
	assert_eq(robot.hp, 2, "El robot debe tener 2 HP tras recibir un impacto.")

func test_robot_muere_al_recibir_tres_impactos():
	# Nodo auxiliar para simular que hay otro robot en el mapa y evitar la cinemática de 4s
	var robot_auxiliar = Node.new()
	robot_auxiliar.add_to_group("robots_cazadores")
	add_child_autoqfree(robot_auxiliar)

	robot.recibir_dano(1)
	robot.recibir_dano(1)
	robot.recibir_dano(1)

	await wait_seconds(0.1)

	# Comprobación de liberación de memoria de GUT
	assert_freed(robot, "El robot debe ser eliminado de la escena al llegar a 0 HP.")
