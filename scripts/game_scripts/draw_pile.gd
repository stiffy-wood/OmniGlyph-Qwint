class_name DrawPile extends Area3D
# Public 
var BLANK_CARD_INFO: CardInfo = CardInfo.new(-1, -1, -1)
signal pile_clicked
var cards = []

# Private
var suit_textures = [
	load("res://textures/cards/Touch.png"),
	load("res://textures/cards/Light.png"),
	load("res://textures/cards/Force.png"),
	load("res://textures/cards/Psyche.png"),
	load("res://textures/cards/Omni.png"),
]

var tier_textures = [
	load("res://textures/cards/Tier1.png"),
	load("res://textures/cards/Tier2.png"),
	load("res://textures/cards/Tier3.png"),
	load("res://textures/cards/Tier4.png"),
	load("res://textures/cards/Tier5.png")
]

var rank_textures = [
	load("res://textures/cards/Rank1.png"),
	load("res://textures/cards/Rank2.png"),
	load("res://textures/cards/Rank3.png"),
	load("res://textures/cards/Rank4.png"),
	load("res://textures/cards/Rank5.png"),
	load("res://textures/cards/Rank6.png"),
	load("res://textures/cards/Rank7.png"),
	load("res://textures/cards/Rank8.png"),
	load("res://textures/cards/Rank9.png"),
]

var card_base_texture = load("res://textures/cards/Card_base.png")
var card_back_texture = load("res://textures/cards/Back.png")
var card_model = load("res://card.blend")

var base_weight = 5
var suit_weights: Dictionary = {} # Key: [int], Value: int
var tier_weights: Dictionary = {} # Key: [int], Value: int
var rank_weights: Dictionary = {} # Key: tier [int], Value: Dictionary [Key: [int], Value: int]

func _ready():
	for suit_tier in range(5):
		suit_weights[suit_tier] = base_weight
		tier_weights[suit_tier] = base_weight
		for rank in range(1 + (suit_tier*2)):
			if not rank_weights.has(suit_tier):
				rank_weights[suit_tier] = {}
			rank_weights[suit_tier][rank] = base_weight
	
	set_process_input(true)
	
func _input_event(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
		pile_clicked.emit()

func _exit_tree():
	print("DRAWPILE LEAVING")

# Public
func prepare_draw_pile():	
	var y_offset = 0.001
	var current_y = 0
	for s in range(5):
		for t in range(5):
			for r in range(1 + (2*t)):
				var card = get_card(BLANK_CARD_INFO)
				card.transform.origin.y = current_y
				current_y += y_offset
				cards.append(card)
				
				
func get_card(c: CardInfo) -> Card:
	var textures = [
		card_base_texture, 
		card_back_texture,
		null,
		null,
		null
	]
	if is_in_range_inclusive(0, len(suit_textures), c.suit):
		textures[2] = suit_textures[c.suit]
	if is_in_range_inclusive(0, len(tier_textures), c.tier):
		textures[3] = tier_textures[c.tier]
	if is_in_range_inclusive(0, len(rank_textures), c.rank):
		textures[4] = rank_textures[c.rank]
	return create_card(c, textures)

func print_weights():
	print("\nCurrent Weights:")
	print("\tSuits:")
	for i in suit_weights:
		print("\t\t", i, ": ", suit_weights[i])
	print("\tTiers And Ranks:")
	for i in tier_weights:
		print("\t\t", i, ": ", tier_weights[i])
		for j in rank_weights[i]:
			print("\t\t\t", j, ": ", rank_weights[i][j])

func pick_random_card() -> CardInfo:
	var suit = pick_random_card_part(suit_weights)
	var tier = pick_random_card_part(tier_weights)
	var rank = pick_random_card_part(rank_weights[tier])
	
	return CardInfo.new(suit, tier, rank)

# Private
func create_card(c: CardInfo, textures: Array) -> Card:
	var card = Card.new(c)
	
	var model = card_model.instantiate()
	var mesh = model.get_child(0, true)
	card.add_child(model)
	
	var mat = ShaderMaterial.new()
	mat.shader = preload("res://materials/card.gdshader")
	mat.set_shader_parameter("card_textures", textures)
	mat.set_shader_parameter("textures_used", textures.map(func(t): return t != null))
	mesh.set_surface_override_material(0, mat)
	
	add_child(card)
	card.global_rotate(Vector3(1, 0, 0), deg_to_rad(180))
	return card

func set_mat_texture(mat: Material, texture: Texture):
	mat.albedo_texture = texture
	return mat
	
func set_mesh_texture(mesh: MeshInstance3D, index: int, texture: Texture):
	var mat = StandardMaterial3D.new()
	mesh.set_surface_override_material(index, set_mat_texture(mat, texture))
	
func is_in_range_inclusive(min: int, max: int, n: int):
	return min <= n and n <= max
	
func pick_random_card_part(weights: Dictionary) -> int:
	var total_weight = 0
	for weight in weights.values():
		total_weight += weight
		
	var random_num = randi() % total_weight
	var running_weight = 0
	var choice = 0
	
	for item in weights.keys():
		running_weight += weights[item]
		if running_weight > random_num and choice == 0:
			choice = item
			weights[item] = max(1, weights[item]-1)
		else:
			weights[item] += 1
		
	return choice
