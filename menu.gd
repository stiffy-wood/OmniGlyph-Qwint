class_name Menu extends Control

signal menu_closed
signal start
var root;

# Called when the node enters the scene tree for the first time.
func _ready():
	$JoinButton.button_up.connect(join_button_pressed)
	$HostButton.button_up.connect(host_button_pressed)
	$StartButton.button_up.connect(start_button_pressed)
	root = get_parent() as Root
	root.player_count_changed.connect(player_count_changed)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func player_count_changed(player_count):
	$PlayerCountLabel.text = "%d/%d Players".format(player_count, root.MAX_CLIENTS)

func join_button_pressed():
	if not $AddressField.text.is_valid_ip_address():
		$AddressField.text = ""
		$AddressField.placeholder_text = "!!!INVALID IP ADDRESS!!!"
	else:
		root.configure_network(false, true, $AddressField.text)

func host_button_pressed():
	root.configure_network(true, root.player_count > 1)

func start_button_pressed():
	start.emit()

func close_menu():
	print("waiting")
	await get_tree().create_timer(2.0).timeout
	print("emitting")
	menu_closed.emit()
	print("freeing")
	queue_free()
	
