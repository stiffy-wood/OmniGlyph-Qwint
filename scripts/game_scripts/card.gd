class_name Card extends Node3D
# Public
var card_info: CardInfo

func _init(c: CardInfo):
	card_info = c
	
# Public
func move_card(target: Transform3D):
	var tween = create_tween()
	tween.tween_property(self, "transform", target, 0.5).set_trans(Tween.TRANS_CUBIC)
	tween.play()
	print("Moving card?")

func _exit_tree():
	print("CARD LEAVING")

