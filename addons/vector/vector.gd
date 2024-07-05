@icon("res://addons/vector/logo.svg")
## Matrix api handler (must be added as an autoload script named "Vector")

class_name vector
extends Node

# import scripts
var api_script = preload("res://addons/vector/api.gd")

# create vars for script objects
var api = api_script.new()

# other vars
var client = HTTPClient.new()
var userToken :String= ""
var base_url :String= ""
var home_server :String= ""
var headers :PackedStringArray= ["content-type: application/json"]
var next_batch :String= ''
var timeout := 3000
var joinedRooms
var userData : Dictionary = {}
var uname : String
var uid : String

# matrix enums
const PRESENCE = {"offline":"offline","online":"online","unavailable":"unavailable"}

# signals
signal user_logged_in
signal got_joined_rooms
signal got_room_state(data:Dictionary)
signal update_room(data:Dictionary)
signal synced(data:Dictionary)
signal got_turn_server(data:Dictionary)
signal got_room_messages(data:Dictionary)

var requestParent:Node

func _ready():
	add_child(api)
	requestParent = get_tree().get_first_node_in_group('requestParent')
	api.user_logged_in.connect(func(result:int,response_code:int,header:PackedStringArray,body:PackedByteArray):
		var msg = body.get_string_from_ascii()
		var msgJson : Dictionary = JSON.parse_string(msg)
		if msgJson:
			if msgJson.has('errcode'):
				Notifyvr.send_notification(msgJson.error)
				#print(msgJson)
				if msgJson.has('retry_after_ms'):
					Notifyvr.send_notification("Please try again after: "+str(msgJson.retry_after_ms/1000)+" seconds")
				return
			if msgJson.has('access_token') and msgJson.has('well_known'):
				if !userData.has("login"):
					userData.login = {}
				userData.login.user_id = msgJson.user_id
				uname = userData.login.user_id.split(':')[0].right(-1)
				uid = userData.login.user_id
				userToken = msgJson.access_token
				base_url = msgJson.well_known["m.homeserver"].base_url
				userData['login'] = msgJson
				userData['login']['home_server'] = home_server
				saveUserDict()
				if userToken != "":
					headers.push_back("Authorization: Bearer {0}".format([userToken]))
					#print(headers)
					user_logged_in.emit()
					#print('logged in')
					get_turn_server()
			else:
				print('Some error occurred')
		else:
			print('couldn\'t parse json\nbody:',msg)
	)
	api.got_joined_rooms.connect(func(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray):
		var msg = body.get_string_from_ascii()
		var msgJson = JSON.parse_string(msg)
		joinedRooms = msgJson['joined_rooms']
		userData['joined_rooms'] = msgJson['joined_rooms']
		saveUserDict()
		got_joined_rooms.emit()
		)
	api.got_room_state.connect(func(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray):
		var msg = body.get_string_from_ascii()
		var msgJson = JSON.parse_string(msg)
		got_room_state.emit({
			"result_code": result,
			"response_code": response_code,
			"headers": headers,
			"body": msgJson
		})
	)
	api.got_room_messages.connect(func(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray):
		var msg = body.get_string_from_ascii()
		var msgJson = JSON.parse_string(msg)
		if result == 0:
			got_room_messages.emit({
				"result_code": result,
				"response_code": response_code,
				"headers": headers,
				"body": msgJson
			})
		else:
			print("error getting messages")
	)
	api.synced.connect(func(result:int,response_code:int,header:PackedStringArray,body:PackedByteArray):
		var msg = body.get_string_from_ascii()
		var msgJson = JSON.parse_string(msg)
		if msgJson.has('next_batch'):
			userData.next_batch = msgJson.next_batch
		if "rooms" in msgJson:
			#print('has rooms')
			#print(msgJson.rooms)
			if "join" in msgJson.rooms:
				#print('has join')
				#print(msgJson.rooms.join)
				for room in msgJson.rooms.join:
					if "timeline" in msgJson.rooms.join[room]:
						#print(msgJson.rooms.join[room].timeline)
						if "events" in msgJson.rooms.join[room].timeline:
							for event in msgJson.rooms.join[room].timeline.events:
								pass
								#if "type" in event:
									#print(event.type)
								#else:
									#print("event has no type:\n"+str(event.content))
		print('synced')
	)
	api.got_turn_server.connect(func(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray):
		var msg = body.get_string_from_ascii()
		var msgJson = JSON.parse_string(msg)
		got_turn_server.emit(msgJson)
	)
	api.placed_room_send.connect(func(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray):
		pass
	)

func send_room_state_event(room_id:String, event_type:String, state_key:String, body:Dictionary):
	api.put_room_state(
		base_url,
		headers,
		room_id,
		event_type,
		state_key,
		body
		)

func send_room_event(room_id:String, event_type:String, body:Dictionary):
	api.put_room_send(
		base_url,
		headers,
		room_id,
		event_type,
		str( str( OS.get_unique_id(),Time.get_unix_time_from_system() ).hash()),
		body
		)

func get_turn_server():
	api.get_turn_server(base_url,headers)

func get_room_messages(room_id:String):
	api.get_room_messages(base_url,headers,room_id,'b','','',10)

func get_room_state(room_id):
	api.get_room_state(base_url, headers, room_id)

func connect_to_homeserver(homeServer:String = ""):
	var homeserverurl = "https://{0}".format([
		userData["home_server"] if homeServer == "" and userData.has("home_server") else homeServer
		])
	var response = client.connect_to_host(
		homeserverurl,
		443)
	assert(response == OK)
	while client.get_status() == client.STATUS_CONNECTING or client.get_status() == client.STATUS_RESOLVING:
		client.poll()
		await get_tree().process_frame
	return response

func login_username_password(homeserver:String,username:String,password:String):
	var homeserverurl = "https://{0}".format([
		userData["home_server"] if homeserver == "" and userData.has("home_server") else homeserver
		])
	api.login_username_password(homeserver,headers,username,password)

func get_joined_rooms():
	api.get_joined_rooms(base_url,headers,userData.login.access_token)

func readRequestBytes():
	while client.get_status() == client.STATUS_REQUESTING:
		client.poll()
		await get_tree().process_frame
	var readbytes = PackedByteArray()
	while client.get_status() == client.STATUS_BODY:
		client.poll()
		var chunk = client.read_response_body_chunk()
		if chunk.size() == 0:
			pass
		else:
			readbytes = readbytes+chunk
		await get_tree().process_frame
	var msg = readbytes.get_string_from_ascii()
	return msg

func saveUserDict():
	if !DirAccess.dir_exists_absolute("user://logins"):
		DirAccess.make_dir_absolute("user://logins")
	var file = FileAccess.open(("user://logins/"+uid.validate_filename()+".data"),FileAccess.WRITE)
	print(uid)
	print(file)
	userData["home_server"] = home_server
	var toStore = var_to_bytes(userData)
	toStore.reverse()
	file.store_var(toStore)
	file.close()

func getExistingSessions() -> PackedStringArray:
	var files = DirAccess.get_files_at("user://logins/")
	return files

func readUserDict(target_login:String=""):
	var file : FileAccess
	if target_login.is_empty():
		file = FileAccess.open("user://user.data",FileAccess.READ)
	else:
		file = FileAccess.open("user://logins/"+target_login,FileAccess.READ_WRITE)
	if file:
		var read = file.get_var()
		read.reverse()
		userData = bytes_to_var(read)
		# user_id, access_token, home_server, device_id, well_known{m.homeserver{base_url}}
		if userData['login'].has("access_token"):
			userToken = userData['login']["access_token"]
			headers.push_back("Authorization: Bearer {0}".format([userToken]))
			home_server = userData['login']['user_id'].split(':')[1]
			base_url = userData['login']['well_known']['m.homeserver']['base_url']
			if userData.has('next_batch'):
				next_batch = userData.next_batch
			if userData.has('joined_rooms'):
				joinedRooms = userData.joined_rooms
				got_joined_rooms.emit()
			user_logged_in.emit()
			return true
	Notifyvr.send_notification("faile to login with existing session")
	return false

func sync():
	var reqData = {}
	print("next batch: "+next_batch)
	if !next_batch.is_empty():
		reqData['since'] = next_batch
	api.sync(base_url,headers,reqData)
