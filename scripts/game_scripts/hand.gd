class_name Hand extends Node3D

var is_player: bool

var cards: Array[Card] = []

func _init(is_player: bool, position: Vector3, orientation: float):
	self.is_player = is_player
	transform.origin = position
	transform.basis = transform.basis.rotated(Vector3.UP, orientation)

	var cfg = ConfigFile.new()
	cfg.load("res://scripts/root_scripts/config.cfg")
	if cfg.get_value("Debug", "IS_DEBUG", false):
		print("Creating a hand at ", position)
		var m = CSGSphere3D.new()
		m.radius = 0.1
		add_child(m)

func draw_card(card: Card):
	cards.append(card)
	card.move_card(transform)
	print("Drawing card to hand?")

