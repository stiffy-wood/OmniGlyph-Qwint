class_name CardMoveInfo

var target_pos: Vector3
var face_up: bool
var card_facing_target: Vector3

func _init(target_pos: Vector3, face_up: bool, card_facing_target: Vector3):
	self.target_pos = target_pos
	self.face_up = face_up
	self.card_facing_target = card_facing_target
