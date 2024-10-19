@icon("res://addons/vector/logo.svg")
## Matrix api handler (must be added as an autoload script or with Engine.register_singleton)

class_name vector
extends Node

# import scripts
var api_script = preload("res://addons/vector/api.gd")

# create vars for script objects
var api = api_script.new()

# other vars
var client = HTTPClient.new()
var userToken :String= ""

## used as the actual server to talk to when doing matrix stuff
## this should be obtained from the get_well_known by asking
## the home_server for the /.well-known/matrix/client/ and then
## setting the base_url from that json object to our base_url here
var base_url : String = ""

## the domain that holds the user this should only
## ever be used by passing it to the get_well_known
## endpoint so we can get the base_url of the user's
## homeserver
var home_server :String= ""
var headers :PackedStringArray= ["content-type: application/json"]

## this is the "since" field from the sync api call
## it allows us to pass a timestamp from the server
## tell the server to give us only new updates
var next_batch :String= ''
var timeout := 3000
var uname : String

var userData : Dictionary = {}

## simple helper interface to provide a direct way to get and update the 
## current matrix user id on the userData Dictionary
var uid : String:
	set(val):
		if "login" in userData and "user_id" in userData.login:
			userData.login.user_id = val
		uid = val
	get:
		if "login" in userData and "user_id" in userData.login:
			uid = userData.login.user_id
		return uid

## used to track data about users the client knows about
## should be used to simplify displaying profiles and other user info
var known_users : Dictionary = {
	"@exmaple:matrix.example": {
		"displayname": "example",
		"presence": "online"
	}
}

# matrix enums
const PRESENCE = {"offline":"offline","online":"online","unavailable":"unavailable"}

# signals
signal user_logged_in
signal got_joined_rooms
signal got_room_state(data:Dictionary)
signal update_room(data:Dictionary)
signal leave_room(roomid:String)
signal synced(data:Dictionary)
signal got_turn_server(data:Dictionary)
signal got_room_messages(data:Dictionary)
signal got_well_known(homeserver:String, base_url:String)

# PROCESSED EVENTS SIGNALS
signal got_new_message(event:Dictionary)

var requestParent:Node = self

#threaded handling variables
var user_data_mutex := Mutex.new()

#aliases
var joinedRooms : Dictionary = {}:
	get:
		if "joined_rooms" not in userData:
			user_data_mutex.lock()
			userData.joined_rooms = {}
			user_data_mutex.unlock()
		return userData.joined_rooms
	set(val):
		joinedRooms = val
		userData.joined_rooms = joinedRooms

func _ready():
	add_child(api)
	api.got_well_known.connect(func(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray,homeserver:String):
		var msg = body.get_string_from_ascii()
		var msgJson : Dictionary = JSON.parse_string(msg)
		if msgJson and "m.homeserver" in msgJson and "base_url" in msgJson["m.homeserver"]:
			base_url = msgJson["m.homeserver"].base_url
			got_well_known.emit(home_server, base_url)
		)
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
				#base_url = msgJson.well_known["m.homeserver"].base_url
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
		var roomdict :Dictionary = {}
		for room in msgJson['joined_rooms']:
			roomdict[room] = {}
		userData['joined_rooms'] = roomdict
		joinedRooms.merge(roomdict)
		saveUserDict()
		got_joined_rooms.emit()
		)
	api.got_room_state.connect(func(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray):
		var msg = body.get_string_from_ascii()
		var msgJson = JSON.parse_string(msg)
		if result == OK and response_code == 200:
			if "joined_rooms" in userData and msgJson is Array:
				for event in msgJson:
					process_event(event)
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
			if "chunk" in msgJson:
				msgJson.chunk.reverse()
				for event in msgJson.chunk:
					process_event(event)
			#got_room_messages.emit({
				#"result_code": result,
				#"response_code": response_code,
				#"headers": headers,
				#"body": msgJson
			#})
		else:
			print("error getting messages")
	)
	## PROCESS SYNC DATA
	api.synced.connect(func(result:int,response_code:int,header:PackedStringArray,body:PackedByteArray):
		WorkerThreadPool.add_task(func():
			var msg = body.get_string_from_ascii()
			var msgJson = JSON.parse_string(msg)
			if msgJson:
				if msgJson.has('next_batch'):
					userData.next_batch = msgJson.next_batch
					next_batch = msgJson.next_batch
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
										call_deferred("process_event",event, room)
										#if "type" in event:
											#print(event.type)
										#else:
											#print("event has no type:\n"+str(event.content))
							if "state" in msgJson.rooms.join[room]:
								#print(msgJson.rooms.join)
								if "events" in msgJson.rooms.join[room].state:
									for event in msgJson.rooms.join[room].state.events:
										call_deferred("process_event",event, room)
									call_deferred("emit_signal","got_room_state",{
										"room_id": room,
										"response_code":200,
										"body":msgJson.rooms.join[room].state.events
										}
										)
					if "leave" in msgJson.rooms:
						for room in msgJson.rooms.leave:
							joinedRooms.erase(room)
							call_deferred("emit_signal", "leave_room",room)
				print('synced')
				call_deferred("emit_signal", "synced", msgJson)
				call_deferred("saveUserDict")
			else:
				call_deferred("emit_signal","synced", {"result":result})
			)
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
	if !homeserver.begins_with("https://"):
		homeserver = "https://"+homeserver
	api.login_username_password(homeserver,headers,username,password)

func get_well_known(homeserverurl:String):
	if !homeserverurl.ends_with("/"):
		homeserverurl+="/"
	api.get_well_known("https://"+homeserverurl, headers)

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
	var file = FileAccess.open(("user://logins/"+uid.validate_filename()+".datan"),FileAccess.WRITE)
	userData["home_server"] = home_server
	var tmpdata :Dictionary = userData.duplicate(true)
	var toStore = JSON.stringify(tmpdata," ")
	#var toStore = var_to_bytes(userData)
	print(toStore.length())
	file.store_string(toStore)
	file.close()
	DirAccess.remove_absolute("user://logins/"+uid.validate_filename()+".data")
	DirAccess.rename_absolute("user://logins/"+uid.validate_filename()+".datan", "user://logins/"+uid.validate_filename()+".data")

func getExistingSessions() -> PackedStringArray:
	var files = DirAccess.get_files_at("user://logins/")
	return files

func readUserDict(target_login:String=""):
	var file : FileAccess
	if target_login.is_empty() and FileAccess.file_exists("user://user.data"):
		file = FileAccess.open("user://user.data",FileAccess.READ)
	else:
		file = FileAccess.open("user://logins/"+target_login,FileAccess.READ_WRITE)
	if file:
		WorkerThreadPool.add_task(_load_user_dictionary.bind(file),true)
		#_load_user_dictionary(file)

func _load_user_dictionary(file:FileAccess):
	var read :String= file.get_as_text()
	userData = JSON.parse_string(read)
	# user_id, access_token, home_server, device_id, well_known{m.homeserver{base_url}}
	if userData['login'].has("access_token"):
		userToken = userData['login']["access_token"]
		headers.push_back("Authorization: Bearer {0}".format([userToken]))
		home_server = userData['login']['user_id'].split(':')[1]
		base_url = userData['login']['well_known']['m.homeserver']['base_url']
		if "login" in userData and "user_id" in userData.login:
			uid = userData.login.user_id
		if userData.has('next_batch'):
			next_batch = userData.next_batch
		if userData.has('joined_rooms'):
			#got_joined_rooms.emit()
			call_deferred("emit_signal","got_joined_rooms")
		#user_logged_in.emit()
		call_deferred("emit_signal","user_logged_in")
		#saveUserDict()
		call_deferred("saveUserDict")

func sync():
	var reqData = {}
	reqData.timeout = 30
	if !next_batch.is_empty():
		reqData['since'] = next_batch
	api.sync(base_url,headers,reqData)

func process_event(event:Dictionary, roomid:String=""):
	if !roomid.is_empty():
		event.room_id = roomid
	if "joined_rooms" not in userData:
		userData.joined_rooms = {}
	if event.room_id not in userData.joined_rooms:
		userData.joined_rooms[event.room_id] = {}
	if "state" not in userData.joined_rooms[event.room_id]:
		userData.joined_rooms[event.room_id].state = {}
	if "events" not in userData.joined_rooms[event.room_id].state:
		userData.joined_rooms[event.room_id].state = {}
	if "room_id" in event and "event_id" in event:
		if !(event["room_id"] in userData.joined_rooms):
			userData.joined_rooms[event["room_id"]] = {}
		if "state" not in userData.joined_rooms[event["room_id"]]:
			userData.joined_rooms[event["room_id"]]["state"] = {
				"events": {}
			}
		if "events" not in userData.joined_rooms[event["room_id"]]["state"]:
			userData.joined_rooms[event["room_id"]]["state"]["events"] = {}
		if "type" in event:
			match event.type:
				# ACCOUNT_DATA
				"m.push_rules":
					pass
				"m.accepted_terms":
					pass
				"m.widgets":
					pass
				"im.vector.analytics":
					pass
				"m.secret_storage.key.[key]":
					pass
				"im.vector.setting.integration_provisioning":
					pass
				"in.cinny.spaces":
					pass
				"m.cross_signing.user_signing":
					pass
				"m.cross_signing.user_signing":
					pass
				"m.megolm_backup.v1":
					pass
				"io.element.recent_emoji":
					pass
				"m.secret_storage.default_key":
					pass
				"m.cross_signing.master":
					pass
				"im.vector.setting.breadcrumbs":
					pass
				"im.vector.web.settings":
					pass
				"m.direct":
					pass
				# PRESENCE
				"m.presence":
					pass
				# ROOM TIMELINE
				"m.room.message":
					if "content" in event and "msgtype" in event.content:
						match event.content.msgtype:
							"m.text":
								got_new_message.emit(event)
							"m.image":
								got_new_message.emit(event)
								# TODO get the media here 
				"bark.session.request":
					got_new_message.emit(event)
				"bark.session.offer":
					got_new_message.emit(event)
				"bark.session.answer":
					got_new_message.emit(event)
				"bark.session.ice":
					got_new_message.emit(event)
				"m.fully_read":
					pass
				"m.receipt":
					pass
				"m.room.canonical_alias":
					pass
				"m.room.create":
					"m.room.space"
					pass
				"m.room.join_rules":
					"m.room.membership"
					pass
				#"m.room.member":
					#userData.joined_rooms[event["room_id"]]["state_events"]["users"]
				"m.room.power_levels":
					pass
				"m.room.history_visibility":
					pass
				"m.room.power_levels":
					pass
				"m.space.child":
					pass
				"m.room.topic":
					pass
				"m.space.parent":
					pass
				"m.room.guest_access":
					pass
				"m.room.name":
					pass
				
		if "joined_rooms" in userData:
			if event.room_id in userData.joined_rooms:
				if "state" in userData.joined_rooms[event.room_id]:
					if "events" in userData.joined_rooms[event.room_id].state:
						userData.joined_rooms[event.room_id]["state"]["events"][event["event_id"]] = event
