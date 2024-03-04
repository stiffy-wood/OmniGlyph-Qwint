class_name Root extends Node
const MAX_CLIENTS = 8 
var config = ConfigFile.new()

signal player_count_changed(total_player_count)
var player_count = 1

var game_scene = preload("res://scenes/game.tscn")
var menu_scene = preload("res://scenes/menu.tscn")

var is_menu = true
var is_switching = false
var load_time = 0
func _init():
	add_child(menu_scene.instantiate())
	init_menu()
	config.load("res://scripts/root_scripts/config.cfg")

var connected = false
var configured = false
func _process(delta):
	if Input.is_action_just_pressed("Connect"):
		configure_network(false, true, "127.0.0.1")
		configured = true
		
	if Input.is_action_just_pressed("Host"):
		configure_network(true, true)
		configured = true
		connected = false
	
	if Input.is_action_just_pressed("ChangeScene"):
		await switch_to_game() if is_menu else await switch_to_menu()
	if is_switching:
		load_time += delta
	if load_time > 0 and not is_switching:
		print("Switching scenes took ", load_time, " seconds!")
		load_time = 0
	
func init_menu():
	var menu = get_child(0) as Menu
	if menu == null:
		return
		
	menu.start.connect(func (): 
		if multiplayer.is_server():
			start_game.rpc()
		)

func switch_to_game():
	var menu = get_child(0) as Menu
	await switch_scene(game_scene, menu.close_menu, menu.menu_closed)
	
func switch_to_menu():
	var game = get_child(0) as Controller
	await switch_scene(menu_scene, game.close_game, game.game_closed)
	init_menu()
	
func switch_scene(new_scene, close_func, scene_closed_signal):
	print("changing scene!")
	is_switching = true
	close_func.call()
	print("closing func called")
	await scene_closed_signal
	print("Signal received")
	add_child(new_scene.instantiate())
	print("added scene")
	is_switching = false
	is_menu = not is_menu

func configure_network(is_host: bool = true, is_multiplayer: bool = false, address: String = "127.0.0.1"):
	print("Configuring network:", 
	"\n\tis_host: ", is_host, 
	"\n\tis_multiplayer: ", is_multiplayer, 
	"\n\taddress: ", address)
	
	var peer = ENetMultiplayerPeer.new()
	var port = config.get_value("Network", "PORT", 666)
	
	if is_host:
		var result = peer.create_server(port, MAX_CLIENTS if is_multiplayer else 1)
		if result != OK:
			print("Failed to create server: ", result)
			return
		if not is_multiplayer:
			peer.set_bind_ip("127.0.0.1")
		
		multiplayer.multiplayer_peer.peer_connected.connect(player_joined)
		multiplayer.multiplayer_peer.peer_disconnected.connect(player_left)
		
	else:
		var result = peer.create_client(address, port)
		if result != OK:
			print("Failed to connect: ", result)
		
	multiplayer.multiplayer_peer = peer	

func player_left(p_id):
	player_count -= 1
	receive_player_count_update.rpc(player_count)
	
func player_joined(p_id):
	player_count += 1
	receive_player_count_update.rpc(player_count)

@rpc("authority", "call_local", "reliable")
func receive_player_count_update(total_player_count):
	player_count_changed.emit(total_player_count)
	
@rpc("authority", "call_local", "reliable")
func start_game():
	switch_to_game()
	
	
	
