@icon("res://addons/vector/vector.gd")
## Matrix api handler (must be added as an autoload script named "Vector")

class_name vector
extends Node

# import scripts
var api_script = preload("res://addons/vector/api.gd")

# create vars for script objects
var api = api_script.new()

# other vars
var client = HTTPClient.new()
var userToken = ""
var base_url = ""
var home_server = ""
var headers = ["content-type: application/json"]
var next_batch = ''
var timeout = 3000
var joinedRooms
var userData : Dictionary = {}

# matrix enums
const PRESENCE = {"offline":"offline","online":"online","unavailable":"unavailable"}

# signals
signal user_logged_in
signal got_joined_rooms
signal got_room_state(data)
signal update_room(data)
signal synced(data)

@onready var requestParent = get_tree().get_first_node_in_group("requestParent")

func _ready():
	api.user_logged_in.connect(func(result:int,response_code:int,header:PackedStringArray,body:PackedByteArray):
		var msg = body.get_string_from_ascii()
		var msgJson : Dictionary = JSON.parse_string(msg)
		if msgJson.has('errcode'):
#			Notify.sendNotification(msgJson.error)
#			if msgJson.has('retry_after_ms'):
#				Notify.sendNotification("Please try again after: "+str(msgJson.retry_after_ms/1000)+" seconds")
			return null
		userToken = msgJson.access_token
		base_url = msgJson.well_known["m.homeserver"].base_url
		userData['login'] = msgJson
		userData['login']['home_server'] = home_server
		saveUserDict()
		if userToken != "":
			headers.push_back("Authorization: Bearer {0}".format([userToken]))
			print(headers)
			user_logged_in.emit()
			print('logged in')
			return true
		else:
			return false
		)
	api.got_joined_rooms.connect(func(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray):
		var msg = body.get_string_from_ascii()
		var msgJson = JSON.parse_string(msg)
		joinedRooms = msgJson['joined_rooms']
		userData['joined_rooms'] = msgJson['joined_rooms']
		saveUserDict()
		print('got joined rooms')
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
	api.synced.connect(func(result:int,response_code:int,header:PackedStringArray,body:PackedByteArray):
		var msg = body.get_string_from_ascii()
		var msgJson = JSON.parse_string(msg)
		if msgJson.has('next_batch'):
			next_batch = msgJson.next_batch
			userData['next_batch'] = next_batch
			saveUserDict()
		synced.emit(msgJson)
		)

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
	api.login_username_password(homeserver,username,password)

func get_joined_rooms():
	api.get_joined_rooms()

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
	var file = FileAccess.open("user://user.data",FileAccess.WRITE)
	userData["home_server"] = home_server
	var toStore = var_to_bytes(userData)
	toStore.reverse()
	file.store_var(toStore)

func readUserDict():
	var file = FileAccess.open("user://user.data",FileAccess.READ)
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
			print("baseurl: ",base_url)
			if userData.has('next_batch'):
				next_batch = userData.next_batch
			if userData.has('joined_rooms'):
				joinedRooms = userData.joined_rooms
			user_logged_in.emit()
			return true
	return false

#func refresh_token(token:String):
#	var res
#	if client.get_status() == HTTPClient.STATUS_CONNECTED:
#		res = client.request(HTTPClient.METHOD_POST, "/_matrix/client/v3/refresh",headers,str({
#			"refresh_token": token
#		}))
#		var msg = await readRequestBytes()
#		var refreshedToken = JSON.parse_string(msg)
#	else:
#		printerr("Vector client not initialized yet")

func sync():
	var reqData = {}
	print(next_batch)
	if !next_batch.is_empty():
		reqData['since'] = next_batch
	api.sync(reqData)
