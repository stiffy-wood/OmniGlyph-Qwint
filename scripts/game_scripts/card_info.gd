class_name CardInfo

var suit: int
var tier: int
var rank: int

func _init(s: int, t: int, r: int):
	suit = s
	tier = t
	rank = r

func to_dict() -> Dictionary:
	return {
		"suit": suit,
		"tier": tier,
		"rank": rank
	}
	
static func from_dict(data: Dictionary) -> CardInfo:
	return CardInfo.new(data["suit"], data["tier"], data["rank"])

func equals(other: CardInfo):
	return other.suit == suit and other.tier == tier and other.rank == rank
