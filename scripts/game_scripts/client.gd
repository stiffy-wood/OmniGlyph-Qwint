class_name Client extends Node

var player_hand_map: Dictionary = {} # Key: player id [int]; Value: [Hand]
var controller: Controller
var discard_piles: Dictionary = {} # Key: pile id [int]; Value: [DiscardPile]

func _ready():
	controller = get_parent() as Controller
	call_deferred("prepare_board")
	
func prepare_board():
	var hand_positions_on_circle = [270, 90, 180, 0, 135, 45, 225, 315]
	for angle in range(len(hand_positions_on_circle)):
		var pos = get_position_on_circle($Hands.global_position, 3, hand_positions_on_circle[angle])
		var hand = Hand.new(angle == 270, pos, hand_positions_on_circle[angle])
		if angle == 0:			
			hand.is_player = true
		player_hand_map[angle + 1] = hand
		
		$Hands.add_child(hand)
		
	var pile_positions_on_circle = [0, 135, 45, 225, 315]
	for angle in range(len(pile_positions_on_circle)):
		var pos = get_position_on_circle($Piles.global_position, 1 if pile_positions_on_circle[angle] > 0 else 0, pile_positions_on_circle[angle])
		var pile = Node3D.new()
		discard_piles[angle] = pile
		
		$Piles.add_child(pile)
		
func _exit_tree():
	print("CLIENT LEAVING")
		
func get_position_on_circle(center: Vector3, radius: float, angle_deg: float):
	var angle_rad = deg_to_rad(angle_deg)
	var x = radius * cos(angle_rad) + center.x
	var z = radius * sin(angle_rad) + center.z
	return Vector3(x, center.y, z)

func draw_card(p_id: int, card: Card):
	var hand: Hand = player_hand_map.get(p_id)
	# TODO: Fix, hand is not supposed to be null
	
	#hand.draw_card(card)
	hand.cards.append(card)
	var m_info = CardMoveInfo.new(hand.global_position, hand.is_player, $Hands.global_position)
	move_card(card, m_info)
	print("Drawing card?")
	
func move_card(card: Card, move_info: CardMoveInfo):
	var tween: Tween = create_tween()
	var dur = 0.5
	var dir = (move_info.card_facing_target - move_info.target_pos).normalized()
	var end_rot = Vector3(card.rotation.x, atan2(dir.x, dir.z), deg_to_rad(0 if move_info.face_up else 180))
	
	tween.set_parallel(true)
	tween.tween_property(card, "global_position", move_info.target_pos, dur).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(card, "global_rotation", end_rot, dur).set_trans(Tween.TRANS_CUBIC)
	tween.play()
	
