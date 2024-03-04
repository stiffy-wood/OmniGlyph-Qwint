class_name PlayerCollection

class PlayerName:
	var name: String
	var id: int
	func _init(n: String, id: int = 0):
		name = n
		self.id = randi() % 9999 if id == 0 else id
	
	func _to_string():
		return "{name}#{id}".format({"name": name, "id": str(id).pad_zeros(4 - len(str(id)))})
	
	func equals(other: PlayerName):
		return other.name == name and other.id == id
	
	static func from_str(s: String) -> PlayerName:
		var parts: PackedStringArray = s.split("#")
		return PlayerName.new("".join(parts.slice(0, -1)), int(parts[-1]))
		
	func to_dict() -> Dictionary:
		return {
			"name": name,
			"id": id
		}
	
	static func from_dict(data: Dictionary) -> PlayerName:
		if data.is_empty():
			return null
		return PlayerName.new(data.get("name", ""), data.get("id", 0))

class PlayerDetails:	
	var client_id: int
	var player_id: int
	var name: PlayerName

	func _init(n: String, p_id: int = 0, c_id: int = 0):
		client_id = c_id
		player_id = p_id
		name = null
		if n != "":
			name = PlayerName.new(n)
		
	func to_dict() -> Dictionary:
		return {
			"player_id": player_id,
			"name": null if name == null else name.to_dict()
		}
		
	static func from_dict(data: Dictionary) -> PlayerDetails:
		if data.is_empty():
			return null
		var p = PlayerDetails.new("", data.get("player_id", 0))
		var n = data.get("name")
		p.name = n if n == null else PlayerName.from_dict(n)
		return p
		
		
# Public
var this_player: PlayerDetails:
	get:
		return find_player_by_name(_this_player_name)
		
var players: Array[PlayerDetails]

# Private
var _this_player_name: PlayerName

var _start: int = 0
var _cur: int
var _end:
	get:
		return len(players)
var _inc: int = 1

func _init(this_player_name: String = "", number_of_players: int = 0):	
	players = []
	for i in range(number_of_players):
		players.append(PlayerDetails.new("", i + 1))
	
	if this_player_name != "":
		_this_player_name = PlayerName.new(this_player_name)
		players[0].name = _this_player_name
		players[0].client_id = 1
		
func should_continue():
	return _cur < _end

func _iter_init(arg):
	_cur = _start
	return should_continue()

func _iter_next(arg):
	_cur += _inc
	return should_continue()
	
func _iter_get(arg):
	return players[_cur]
	
# Public
func add_player(n: String, c_id: int) -> int:
	for p in players:
		if p.name == null:
			p.client_id = c_id
			p.name = PlayerName.from_str(n)
			return p.player_id
	return 0
	
func remove_player(p_id: int):
	for p in players:
		if p.player_id == p_id:
			p.client_id = 0
			p.name = null

func update_player_list(p_c: PlayerCollection):
	players = p_c.players

func find_player_by_player_id(p_id: int) -> PlayerDetails:
	return find_player(func(p: PlayerDetails): return p.player_id == p_id)

func find_player_by_client_id(c_id: int) -> PlayerDetails:
	return find_player(func(p: PlayerDetails): return p.client_id == c_id)

func find_player_by_name(n: PlayerName) -> PlayerDetails:
	return find_player(func(p: PlayerDetails): return p.name.equals(n))

func print_list():
	for p in players:
		print("Player: ", p.name,
			"\n\tP_ID: ", p.player_id,
			"\n\tC_ID: ", p.client_id)
			
func serialize() -> Array[Dictionary]:
	var serialiazed: Array[Dictionary] = []
	for p in players:
		serialiazed.append(p.to_dict())
	return serialiazed
	
func deserialize(data: Array):
	var new_players: Array[PlayerDetails] = []
	for p in data:
		new_players.append(PlayerDetails.from_dict(p))
	players = new_players
	
# Private
func find_player(f: Callable) -> PlayerDetails:
	for p in players:
		if f.call(p):
			return p
	return null
