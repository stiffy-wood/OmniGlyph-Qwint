class_name Controller extends Node

var players: PlayerCollection
var draw_pile: DrawPile
var root: Root
signal game_closed

func _ready():
	root = get_parent() as Root
	assert(root != null, "Controller is not a subscene of Root")
	players = PlayerCollection.new("Me", root.MAX_CLIENTS)
	
	draw_pile = $Client/DrawPile
	draw_pile.pile_clicked.connect(func(): rpc_id(1, "request_draw_card"))
	draw_pile.prepare_draw_pile()
	
func _process(delta):
	if root.configured and not multiplayer.is_server() and multiplayer.multiplayer_peer.get_connection_status() == 2 and not root.connected:
		request_connect.rpc_id(1, str(players.this_player.name))
		root.connected = true
	
func close_game():
	await get_tree().create_timer(1.0).timeout
	game_closed.emit()
	queue_free()

func _exit_tree():
	print("CONTROLLER LEAVING")
	
func on_player_connected(id):	
	print("player with id ", id, " has connected")

func on_player_disconnected(id):
	print("player with id ", id, " has disconnected")	
	var p = players.find_player_by_client_id(id)
	if p == null:
		return
	players.remove_player(p.player_id)
	receive_players_update.rpc(players.serialize())
	players.print_list()

# Server methods
@rpc("any_peer", "call_local", "reliable")
func request_connect(p_name: String):
	print("player ", p_name, " requesting to connect")
	var s_id = multiplayer.get_remote_sender_id()
	
	var p_id = players.add_player(p_name, s_id)
	if p_id == 0:
		receive_kick.rpc_id(s_id, "No free slot")
		return
	
	receive_players_update.rpc(players.serialize())

@rpc("any_peer", "call_local", "reliable")
func request_draw_card():
	var s_id = multiplayer.get_remote_sender_id()
	var player = players.find_player_by_client_id(s_id)
	if player == null:
		receive_error.rpc_id(s_id, "Could not find player")
		return
	var p_id = player.player_id
	var card = draw_pile.pick_random_card()

	for p: PlayerCollection.PlayerDetails in players:
		if p.client_id == 0:
			continue
		receive_player_drew_card.rpc_id(p.client_id, p_id, card.to_dict() if p.client_id == s_id else {})

# Client methods
@rpc("authority", "call_local", "reliable")
func receive_error(message: String):
	print(message)

@rpc("authority", "call_remote", "reliable")
func receive_players_update(player_list: Array):
	players.deserialize(player_list)
	
@rpc("authority", "call_local", "reliable")
func receive_player_drew_card(p_id: int, card_dict: Dictionary):
	var p_name = players.find_player_by_player_id(p_id).name
	print("Player ", p_name, " with id ", p_id, " drew a card [My id is ", players.this_player.player_id, "]")
	var card_info = CardInfo.from_dict(card_dict) if not card_dict.is_empty() else draw_pile.BLANK_CARD_INFO
	if not card_dict.is_empty():
		print("And drew this card:\n\tSuit: ", card_info.suit, "\n\tTier: ", card_info.tier, "\n\tRank: ", card_info.rank)
		
	var card = draw_pile.get_card(card_info)
	($Client as Client).draw_card(p_id, card)
	
@rpc("authority", "call_remote", "reliable")
func receive_kick(message: String):
	print(message)
	multiplayer.multiplayer_peer = null
