extends Node

# Steam networking template by yours truly
# Uncomment to use, requires GodotSteam's custom godot build. Built for v4.3
# This isnt really desinged to work out of the box, theres a lot of stuff you will need to change

#const PACKET_READ_LIMIT : int = 32
#const NET_DATA_DEFAULT : Dictionary = {} # add data here that joining clients need to know immediately
#
#enum SendType {
	#ALL,
	#ALL_EXCLUSIVE,
	#LIST,
	#ONE
#}
#
#enum PacketType {
	#HANDSHAKE,
	#LEAVE,
	#POSITION,
	#LOOK_DIR,
	#GAMESTATE,
	#NET_DATA
#}
#
#enum InterpolateProcess {
	#DEFAULT,
	#VEC2_SPLIT_ANGLES
#}
#
#
#signal net_data_update(id : int, type : String, value : Variant)
#signal lobby_joined
#signal player_joined(id : int)
#signal player_left(id : int)
#
#var is_host : bool = false
#
#var lobby_id : int = 0
#
#var lobby_players : Array = []
#
#var max_players : float = 4
#
#var packet_number : int = 0
#
#var gamestate_recived  : bool = false
#
#var serialized_objects : Array[Callable] = [] # callable funcs that return the state of every relivent object
#
#var player_net_data : Dictionary = {
	#
#}
#
#var steam_id : int = 0
#
#var steam_username : String = ""
#
## NETWORK DEBUG SETTINGS
#const PRINT_PACKET_DEBUG = true
#const PRINT_PACKET_DEBUG_BLACKLIST : Array[PacketType] = [PacketType.POSITION, PacketType.LOOK_DIR]
#
#const ARTIFICIAL_LATENCY = false
#const PERCENT_PACKET_DROP = 1
#const DELAY = 120.0
#const VARIATION = 5.0
#
#func _ready() -> void:
	#OS.set_environment("SteamAppID", str(480))
	#OS.set_environment("SteamGameID", str(480))
	#Debug.push(Steam.steamInit(false, 480)["verbal"], Debug.INFO)
	#
	#
	#steam_id = Steam.getSteamID()
	#steam_username = Steam.getPersonaName()
	#Debug.push(steam_username + " " + str(steam_id), Debug.INFO)
	#
	#Steam.lobby_created.connect(_on_lobby_created)
	#Steam.lobby_joined.connect(_on_lobby_joined)
	#Steam.p2p_session_request.connect(_on_session_request)
	#player_joined.connect(_on_player_joined)
	#
	#serialized_objects.append(serialize)
	#
	#Debug.track(self, "ARTIFICIAL_LATENCY", false, "Artificial Latency Enabled")
	#
	#if ARTIFICIAL_LATENCY:
		#Debug.track(self, "DELAY", false, "Ping (ms)")
		#Debug.track(self, "VARIATION", false, "Ping Variation (ms)")
		#Debug.track(self, "PERCENT_PACKET_DROP", false, "Packet Drop %")
	#
	#Debug.track(self, "player_net_data")
	#
#
#func _process(delta: float) -> void:
	#if lobby_id > 0:
		#read_all_packets()
		#
#
#func create_lobby(type : Steam.LobbyType = Steam.LobbyType.LOBBY_TYPE_PUBLIC):
	#if lobby_id == 0: 
		#Steam.createLobby(Steam.LobbyType.LOBBY_TYPE_PUBLIC, max_players)
#
#func join_lobby(id : int = -2):
	#if id != -2:
		#Steam.joinLobby(id)
	#else:
		#Steam.joinLobby(lobby_id)
#
#func leave_lobby(id : int = -2):
	#send_network_leave()
	#if id != -2:
		#Steam.leaveLobby(id)
	#else:
		#Steam.leaveLobby(lobby_id)
#
#func _on_lobby_created(connect: int, id : int):
	#if connect == 1:
		#lobby_id = id
		#Steam.setLobbyJoinable(lobby_id, true)
		#Steam.setLobbyData(lobby_id, "name", Steam.getPersonaName() + "'s Lobby")
		#var set_relay : bool = Steam.allowP2PPacketRelay(true)
		#
		#Debug.push("lobby id: " + str(lobby_id) + " coppied to clipboard", Debug.INFO)
		#DisplayServer.clipboard_set(str(lobby_id))
		#
		#
#
#func _on_lobby_joined(id : int, perms : int, locked : int, response : int):
	#if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		#lobby_id = id
		#get_lobby_players()
		#send_network_handshake()
		#
		## remove this if ur not doing a gamestate sync
		#gamestate_recived = false
		#send(SendType.ALL_EXCLUSIVE, PacketType.GAMESTATE, {"type": "request"}, true)
	#
#func _on_session_request(id):
	#var requester : String = Steam.getFriendPersonaName(id)
	#Steam.acceptP2PSessionWithUser(id)
#
#func send_network_handshake():
	#send(SendType.ALL, PacketType.HANDSHAKE, steam_username, true)
#
#func send_network_leave():
	#print("leave")
	#send(SendType.ALL_EXCLUSIVE, PacketType.LEAVE, steam_username, true)
#
#func get_lobby_players():
	#lobby_players.clear()
	#
	#var num_players : int = Steam.getNumLobbyMembers(lobby_id)
	#for i in range(num_players):
		#var steam_id : int = Steam.getLobbyMemberByIndex(lobby_id, i)
		#var steam_username : String = Steam.getFriendPersonaName(steam_id)
		#print(steam_username)
		#lobby_players.append({"steam_id": steam_id, "steam_name": steam_username})
#
#func send_fast_reliable(send_type : SendType, packet_type : PacketType, packet_data : Variant, to : Variant = 0):
	#send(send_type, packet_type, packet_data, false, to)
	#send(send_type, packet_type, packet_data, true, to)
#
##var interpolated_count : Dictionary = {
	##
##}
#
#
#
#func send(send_type : SendType, packet_type : PacketType, packet_data : Variant, reliable : bool, to : Variant = 0):
	#if ARTIFICIAL_LATENCY and packet_type:
		#if not reliable and randi_range(1, 100) <= PERCENT_PACKET_DROP:
			#return
		#await get_tree().create_timer(randf_range((DELAY - VARIATION)/1000.0, (DELAY + VARIATION)/1000.0)).timeout
		#
	#var packet
	#
	#match packet_type:
		## custom packet packing goes here
		#_:
			#packet = [packet_number, Time.get_unix_time_from_system(), PacketType.keys()[int(packet_type)], packet_data]
	#
	#packet_number += 1
	#
	#var packet_bytes : PackedByteArray
	#var send_method : Steam.P2PSend = Steam.P2PSend.P2P_SEND_RELIABLE if reliable else Steam.P2PSend.P2P_SEND_UNRELIABLE
	#packet_bytes.append_array(var_to_bytes(packet))
	#
	#match send_type:
		#SendType.ONE:
			#Steam.sendP2PPacket(to, packet_bytes, send_method)
		#
		#SendType.ALL:
			#read_packet(0, packet)
			#for player in lobby_players:
				#if player["steam_id"] != steam_id:
					#Steam.sendP2PPacket(player["steam_id"], packet_bytes, send_method)
			#
		#SendType.ALL_EXCLUSIVE:
			#for player in lobby_players:
				#if player["steam_id"] != steam_id:
					#Steam.sendP2PPacket(player["steam_id"], packet_bytes, send_method)
		#
		#
		#SendType.LIST:
			#for player in to:
				#Steam.sendP2PPacket(player, packet_bytes, send_method)
		#
		#_:
			#Debug.push("Packet send type invalid: " + str(send_type), Debug.ALERT)
#
#func read_all_packets(channel : int = 0):
	#var read_count : int = 0
	#
	#while read_count <= PACKET_READ_LIMIT and Steam.getAvailableP2PPacketSize(channel) > 0:
		#read_packet(channel)
		#read_count += 1
#
#func clean_seralized_objects():
	#for object : Callable in serialized_objects:
		#if not object.is_valid():
			#serialized_objects.erase(object)
#
##func out_of_order(num : int, sender : int,  type : String):
	##var previous_packet_numbers = player_net_data[sender]["prev_packet_num"]
	##if num < previous_packet_numbers[type]:
		##return true
	##previous_packet_numbers[type] = num
	##return false
#
#func read_packet(channel : int = 0, override_packet : Array = []):
	#var packet_size = Steam.getAvailableP2PPacketSize(channel)
	#if packet_size > 0 or override_packet != []:
		#var sender : int
		#var packet_data_raw
		#if override_packet == []:
			#var packet : Dictionary = Steam.readP2PPacket(packet_size, channel)
			#sender = packet["remote_steam_id"] 
			#packet_data_raw = bytes_to_var(packet["data"])
		#else:
			#sender = steam_id
			#packet_data_raw = override_packet
	#
		#var packet_number = packet_data_raw[0]
		#var packet_timestamp = packet_data_raw[1]
		#var packet_type = PacketType.get(packet_data_raw[2])
		#var packet_data = packet_data_raw[3]
		#if PRINT_PACKET_DEBUG and not PRINT_PACKET_DEBUG_BLACKLIST.has(packet_type): 
			#prints(PacketType.keys()[packet_type], packet_timestamp, packet_data)
		#
		## all non-interpolated packet logic happens here
		#match packet_type:
			#PacketType.HANDSHAKE:
				#Debug.push("Player " + str(packet_data) + " joined!")
				#get_lobby_players()
				#if not player_net_data.has(sender):
					#player_net_data[sender] = NET_DATA_DEFAULT.duplicate(true)
				#
				#if sender != steam_id: # and not Global.get_puppet_player(sender) (add your own check here)
					#pass # Global.create_puppet_player(sender) (create a puppet player)
				#
				#player_joined.emit(sender)
				#return
			#
			#PacketType.LEAVE:
				#Debug.push("Player " + str(packet_data) + " is no longer with us.")
				#get_lobby_players()
				#player_net_data.erase(sender)
				#
				#if sender != steam_id:
					#pass # Global.remove_puppet_player(sender) (delete puppet player)
				#
				#player_left.emit(sender)
				#return
			#
			#PacketType.NET_DATA:
				#if not player_net_data.has(sender):
					#player_net_data[sender] = NET_DATA_DEFAULT.duplicate(true)
				#
				#player_net_data[sender][packet_data[0]] = packet_data[1]
				#net_data_update.emit(sender, packet_data[0], packet_data[1])
				#return
			#
			#PacketType.GAMESTATE: # you could remove this if your game doesnt need it
				## example object state:
				##func serialize(requester_id):
					##var out : Dictionary = {
						##"scene": "res://Scenes/Machines/pump.tscn",
						##"parent": "machine_holder",
						##"properties": [
							##["position", position], 
							##["rotation", rotation], 
							##["pressure", pressure],
							##["battery_power", battery_power],
							##["quality", quality],
							##["functional", functional],
							##["increase_variation", increase_variation],
							##["variation_mult", variation_mult],
							##["variation_target", variation_target],
							##["variation_speed", variation_speed],
							##["is_serialized_instance", true]
						##]
					##}
				#
				#
				#match packet_data["type"]:
					#"request":
						#clean_seralized_objects()
						#var gamestate : Array = []
						#for object : Callable in serialized_objects:
							#if object.is_valid():
								#gamestate.append(object.call(sender))
						#
						#send(SendType.ONE, PacketType.GAMESTATE, {"type": "respond", "gamestate": gamestate}, true, sender)
					#
					#"respond":
						#if not gamestate_recived:
							#gamestate_recived = true
							#
							#var gamestate : Array = packet_data["gamestate"]
							## Global.reset_objects() (clear all existing objects)
							##loop over all object serializations in the recived gamestate
							#for object in gamestate:
								## does it exist?
								#if object != {}:
									## is the object a scene or an absolute path to a particular node?
									#if object.has("scene"):
										## instantiate the scene of the serialized object
										#var inst = load(object["scene"]).instantiate()
										## loop thru all serialized properties of that object to set the state
										#for property : Array in object["properties"]:
											## check for different flags that could be put at the start 
											## to indicate different ways to handle the data
											#match property[0]:
												#"node":
													## set the property of a specific node in this scene
													#if property[2] != "item_data":
														#inst.get_node(property[1]).set(property[2], property[3])
													#else:
														#var new_item = ItemData.new()
														#new_item.reconstruct(property[4])
														#inst.get_node(property[1]).set(property[3], new_item)
												#
												#"func", "func_abs":
													## run a function with args in this scene
													#var args : Array = []
													#for arg in range(property.size() - 3):
														#var to_add = property[arg + 3]
														#if to_add is String:
															#var split = to_add.split(":")
															#match split[0]:
																#"node":
																	#args.append(inst.get_node(split[1])) # my tab indentation level peaked here, probably the most ive done xD
																#
																#_:
																	#args.append(to_add)
														#else: args.append(to_add)
													#var call = Callable(inst.get_node(property[1]) if property[0] == "func" else get_node(property[1]), property[2])
													#if args.size() != 0: call.callv(args)
													#else: call.call()
												#
												## feel free to add more custom interperiters to the serialization here
												#_:
													## set propperty in the instantiated scene
													#inst.set(property[0], property[1])
										#
										##Global.get(object["parent"]).add_child(inst) (instanciate the scene at location object["parent"] relitive to something, add your own implementation)
										#
									#elif object.has("path"):
										#for property : Array in object["properties"]:
											#get_node(object["path"]).set(property[0], property[1])
										#
								#
							## add logic for what should happen after all serialized data is recived/processed
							##Global.trans.switch_scene(packet_data["area"])
							##Global.trans.fake_trans_to_level("from_black_one_way")
				#return
							#
			#
		#
		#var puppet_player = null # Global.get_puppet_player(sender) (get your ghost player using the steam id)
		#
		## interpolated packets go here
		#if puppet_player:
			#match packet_type:
				#PacketType.POSITION:
					#push_to_interpolate_buffer("position", packet_data, packet_number, packet_timestamp, puppet_player)
#
				#PacketType.LOOK_DIR:
					#push_to_interpolate_buffer("rotation", packet_data, packet_number, packet_timestamp, puppet_player)
#
#
#const DEFAULT_BUFFER_READ_THERSHOLD = 5
#const DEFAULT_MAX_IDLE_TIME = 0.2
#const DEFAULT_TELEPORT_THRESHOLD = 1.0
#const FRAMES_BEFORE_IDLE = 4
#
#var interpolated_properties : Dictionary = {}
#
## network interpolation logic
#func push_to_interpolate_buffer(property_tag : String, value : Variant, packet_number : int, timestamp : float, local_node : Node = null):# push packet data to it's buffer to be interpolated
	#if local_node != null: property_tag += str(local_node.get_instance_id())
	#if not interpolated_properties.has(property_tag):
		#_create_interpolated_property(property_tag, local_node)
	#
	#var property = interpolated_properties[property_tag]
	#
	#if property["last_recived_time"] < 0:
		#property["last_recived_time"] = timestamp
		#return
	#
	#if timestamp - property["last_recived_time"] > 0:
		#property["buffer"].append([packet_number, value, timestamp - property["last_recived_time"]])
		#property["buffer"].sort_custom(Util.sort_ascending)
		#property["last_recived_time"] = timestamp
#
#func get_interpolated_value(property_tag : String, local_node : Node = null, default : Variant = null): # read from buffer and return a current value
	#if local_node != null: property_tag += str(local_node.get_instance_id())
	#
	#if interpolated_properties.has(property_tag):
		#if interpolated_properties[property_tag]["value"] != null:
			#return interpolated_properties[property_tag]["value"]
		#
		#else: 
			#interpolated_properties[property_tag]["value"] = default
			#interpolated_properties[property_tag]["previous_value"] = default
	#
	#return default
#
## interpolate any value!
#func set_custom_interpolate_properties(property_tag : String, local_node : Node = null, read_threshold : int = DEFAULT_BUFFER_READ_THERSHOLD, teleport_threshold : float = DEFAULT_TELEPORT_THRESHOLD, idle_time : float = DEFAULT_MAX_IDLE_TIME, custom_process : InterpolateProcess = InterpolateProcess.DEFAULT):
	#if local_node != null: property_tag += str(local_node.get_instance_id())
	#if not interpolated_properties.has(property_tag):
		#_create_interpolated_property(property_tag, local_node)
	#
	#interpolated_properties[property_tag]["buffer_read_threshold"] = read_threshold
	#interpolated_properties[property_tag]["teleport_threshold"] = teleport_threshold
	#interpolated_properties[property_tag]["max_idle_time"] = idle_time
	#interpolated_properties[property_tag]["custom_process"] = custom_process
	#
#
#func _create_interpolated_property(property_tag : String, local_node : Node = null):
	#interpolated_properties[property_tag] = { 
		#"local_node" : local_node,
		#"value" : null,
		#"buffer" : [],
		#"reading" : false,
		#"previous_value" : null,
		#"last_recived_time" : -1.0,
		#"idle_time" : 0.0,
		#"interpolate_time" : 0.0,
		#"buffer_read_threshold" : DEFAULT_BUFFER_READ_THERSHOLD,
		#"teleport_threshold" : DEFAULT_TELEPORT_THRESHOLD,
		#"max_idle_time" : DEFAULT_MAX_IDLE_TIME,
		#"custom_process" : InterpolateProcess.DEFAULT
	#}.duplicate()
#var interpolated_send_last : Dictionary = {
	#
#}
#
## sends a packed every [param stagger_ammount] times this func is called, useful for interpolation
#func send_staggered_packet(send_type : SendType, packet_type : PacketType, packet_data : Variant, property_tag : String, local_node : Node = null, stagger_ammount : int = 10, reliable = false, send_without_change: bool = true, to : Variant = 0):
	#if local_node != null: property_tag += str(local_node.get_instance_id())
	#if not interpolated_send_last.has(property_tag):
		#interpolated_send_last[property_tag] = {"count": 0, "last" : [], "frames_off" : 0, "delta" : 0.0}
		#
	#var property = interpolated_send_last[property_tag]
	#if not send_without_change and property["last"].size() >= 3 and property["last"][2] == packet_data:
		#return
	#property["last"] = [send_type, packet_type, packet_data, reliable]
	##if not Engine.is_in_physics_frame():
		##var delta : float = 1.0/Engine.get_frames_per_second()
		##property["delta"] += delta
		##if property["delta"] > 1.0/Engine.physics_ticks_per_second:
			##property["delta"] -= Engine.physics_ticks_per_second
			##property["count"] += 1
	##
	##else:
	#property["count"] += 1
	#
	#
	#
	#if property["count"] >= stagger_ammount or property["frames_off"] > FRAMES_BEFORE_IDLE:
		#send(send_type, packet_type, packet_data, reliable, to)
		#property["count"] = 0
	#
	#property["frames_off"] = 0
#
#func _cap_interpolated_packets():
	#for key in interpolated_send_last.keys():
		#var property = interpolated_send_last[key]
		#property["frames_off"] += 1
		#if property["frames_off"] == FRAMES_BEFORE_IDLE:
			#send(property["last"][0], property["last"][1], property["last"][2], property["last"][3])
			#
#
#func _interpolate_values(delta : float):
	#for key in interpolated_properties.keys():
		#var property : Dictionary = interpolated_properties[key]
		#if property["local_node"] != null and not is_instance_valid(property["local_node"]):
			#interpolated_properties.erase(key)
			#continue
			#
		#if property["buffer"].size() >= property["buffer_read_threshold"]:
			#property["reading"] = true
		#
		#elif property["buffer"].size() == 0:
			#property["reading"] = false
		#
		#elif not property["reading"]:
			#property["idle_time"] += delta
			#if property["idle_time"] > property["max_idle_time"]:
				#property["reading"] = true
				#
		#else:
			#property["idle_time"] = 0.0
		#
		#if property["reading"]:
			#if property["buffer"][0][2] > property["teleport_threshold"]:
				#property["buffer"].pop_front()
				#
			#if property["buffer"].size() != 0:
				#var curr_buffer = property["buffer"][0]
				#
				#if property["interpolate_time"] >= curr_buffer[2]:
					#property["previous_value"] = property["value"]
					#property["interpolate_time"] -= curr_buffer[2]
					#property["buffer"].pop_front()
					#if property["buffer"].size() != 0: curr_buffer = property["buffer"][0]
				#
				#if property["buffer"].size() != 0 and property["interpolate_time"] < curr_buffer[2]:
					#var progress = clamp(property["interpolate_time"] / curr_buffer[2], 0.0, 1.0)
					#match property["custom_process"]:
						#InterpolateProcess.VEC2_SPLIT_ANGLES:
							#var out = Vector2.ZERO
							#out.x = lerp_angle(property["previous_value"].x, curr_buffer[1].x, progress)
							#out.y = lerp_angle(property["previous_value"].y, curr_buffer[1].y, progress)
							#property["value"] = out
							#
						#InterpolateProcess.DEFAULT:
							#match typeof(property["value"]):
								#TYPE_VECTOR3, TYPE_VECTOR2:
									#property["value"] = property["previous_value"].lerp(curr_buffer[1], progress)
								#
								#TYPE_FLOAT:
									#property["value"] = lerpf(property["previous_value"], curr_buffer[1], progress)
								#
								#TYPE_INT:
									#property["value"] = roundi(lerpf(property["previous_value"], curr_buffer[1], progress))
								#
								#TYPE_BOOL:
									#property["value"] = curr_buffer[1]
								#
								#TYPE_NIL:
									#print("Null interpolated value: ", interpolated_properties.find_key(property))
									#
								#_: 
									#printerr("Unknown value type: " + str(typeof(property["value"])))
				#
				#property["interpolate_time"] += delta
 #
#func _physics_process(delta: float) -> void:
	#_interpolate_values(delta)
	#_cap_interpolated_packets()
#
#func serialize(requester_id):
	#return {
		#"path" : get_path(),
		#"properties": [
			#["player_net_data", player_net_data]
		#]
	#}
#
#func _on_player_joined(id : int):
	#pass # do whateva
