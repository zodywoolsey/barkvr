class_name matrix_api
extends Node

# comment info:
# METHOD end/point
# accepts: {variable_name:variable_type} # :fp-function parameter :qp-query parameter :bp-body parameter

# signals
signal got_well_known(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray)
signal got_versions(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray)
signal got_registration_token_validity(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray)
signal got_login(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray)
signal posted_login(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray)
signal posted_refresh(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray)
signal posted_logout(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray)
signal posted_logout_all(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray)
signal posted_account_deactivate(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray)
signal posted_account_password(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray)
signal posted_account_password_email_requestToken(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray)
signal posted_account_password_msisdn_requestToken(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray)
signal posted_register(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray)
signal got_register_available(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray)
signal posted_register_email_requesttoken(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray)
signal posted_register_msisdn_requesttoken(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray)

signal user_logged_in(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray)
signal got_joined_rooms(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray)
signal got_room_state(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray)
signal got_room_messages(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray)
signal synced(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray)

## GET /.well-known/matrix/client
## accepts: {base_url:String:fp, headers:Array:fp}
## https://spec.matrix.org/v1.6/client-server-api/#getwell-knownmatrixclient
func get_well_known(base_url:String='', headers:Array=[]):
	assert(base_url!='',"get_well_known: base_url is required")
	if headers.is_empty():
		push_warning("get_well_known: though headers are optional for this call, it is recommended to provide them")
	var res
	var client = HTTPRequest.new()
	print("getting well known for: ",base_url)
	client.use_threads = false
	Vector.requestParent.add_child(client)
	client.request_completed.connect(func(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray):
		# if result == RESULT_SUCCESS, emit signal
		if result == HTTPRequest.RESULT_SUCCESS:
			got_well_known.emit(result,response_code,headers,body)
		else:
			print_rich("[color=red]error getting well known:\n-result: {0}\n-response_code: {1}\n[/color]".format([result,response_code]))
		client.queue_free()
		)
	res = client.request(
	base_url+".well-known/matrix/client",
	headers,
	HTTPClient.METHOD_GET
	)

## GET /_matrix/client/versions
## accepts: {base_url:String:fp, headers:Array:fp}
## https://spec.matrix.org/v1.6/client-server-api/#get_matrixclientversions
func get_versions(base_url:String='', headers:Array=[]):
	assert(base_url!='',"get_versions: base_url is required")
	if headers.is_empty():
		push_warning("get_versions: though headers are optional, it is recommended to provide them")
	var res
	var client = HTTPRequest.new()
	print("getting versions for: ",base_url)
	client.use_threads = false
	Vector.requestParent.add_child(client)
	client.request_completed.connect(func(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray):
		# if result == RESULT_SUCCESS, emit signal
		if result == HTTPRequest.RESULT_SUCCESS:
			got_versions.emit(result,response_code,headers,body)
		else:
			print_rich("[color=red]error getting versions:\n-result: {0}\n-response_code: {1}\n[/color]".format([result,response_code]))
		client.queue_free()
		)
	res = client.request(
	base_url+"_matrix/client/versions",
	headers,
	HTTPClient.METHOD_GET
	)

## GET /_matrix/client/v1/register/m.login.registration_token/validity
## accepts: {base_url:String:fp, headers:Array:fp, token:String:qp}
## https://spec.matrix.org/v1.6/client-server-api/#get_matrixclientv1registermloginregistration_tokenvalidity
func get_registration_token_validity(base_url:String='', headers:Array=[], token:String=''):
	assert(base_url!='',"get_registration_token_validity: base_url is required")
	assert(token!='',"get_registration_token_validity: token is required")
	if headers.is_empty():
		push_warning("get_registration_token_validity: though headers are optional, it is recommended to provide them")
	# build query string
	var qp = ""
	if token!='':
		qp = "?token="+token
	var res
	var client = HTTPRequest.new()
	print("getting registration token validity for: ",base_url)
	client.use_threads = false
	Vector.requestParent.add_child(client)
	client.request_completed.connect(func(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray):
		# if result == RESULT_SUCCESS, emit signal
		if result == HTTPRequest.RESULT_SUCCESS:
			got_registration_token_validity.emit(result,response_code,headers,body)
		else:
			print_rich("[color=red]error getting registration token validity:\n-result: {0}\n-response_code: {1}\n[/color]".format([result,response_code]))
		client.queue_free()
		)
	res = client.request(
	base_url+"_matrix/client/v1/register/m.login.registration_token/validity"+qp,
	headers,
	HTTPClient.METHOD_GET
	)

## GET /_matrix/client/v3/login
## accepts: {base_url:String:fp, headers:Array:fp}
## https://spec.matrix.org/v1.6/client-server-api/#get_matrixclientv3login
func get_login(base_url:String='', headers:Array=[]):
	assert(base_url!='',"get_login: base_url is required")
	if headers.is_empty():
		push_warning("get_login: though headers are optional, it is recommended to provide them")
	var res
	var client = HTTPRequest.new()
	print("getting login configuration for: ",base_url)
	client.use_threads = false
	Vector.requestParent.add_child(client)
	client.request_completed.connect(func(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray):
		# if result == RESULT_SUCCESS, emit signal
		if result == HTTPRequest.RESULT_SUCCESS:
			got_login.emit(result,response_code,headers,body)
		else:
			print_rich("[color=red]error getting login configuration:\n-result: {0}\n-response_code: {1}\n[/color]".format([result,response_code]))
		client.queue_free()
		)
	res = client.request(
	base_url+"_matrix/client/v3/login",
	headers,
	HTTPClient.METHOD_GET
	)

## POST /_matrix/client/v3/login
## accepts: {home_server:String:fp, headers:Array:fp, address:String:bp, device_id:String:bp, identifier:Dictionary:bp, initial_device_display_name:String:bp, medium:String:bp, password:String:bp, refresh_token:bool:bp, token:String:bp, type:String:bp, user:String:bp}
## https://spec.matrix.org/v1.6/client-server-api/#post_matrixclientv3login
## identifier accepts: {type:String, user:String, medium:String, address:String, phone:String, country:String}
## https://spec.matrix.org/v1.6/client-server-api/#identifier-types
## type accepts: {m.login.password, m.login.token}
func post_login(home_server:String='', headers:Array=[], address:String='', device_id:String='', identifier:Dictionary={}, initial_device_display_name:String='', medium:String='', password:String='', refresh_token:bool=false, token:String='', type:String='', user:String=''):
	assert(home_server!='',"post_login: home_server is required")
	assert(type!='',"post_login: type is required {m.login.password or m.login.token}")
	if headers.is_empty():
		push_warning("post_login: though headers are optional, it is recommended to provide them")
	var res
	var client = HTTPRequest.new()
	print("posting login for: ",home_server)
	client.use_threads = false
	Vector.requestParent.add_child(client)
	client.request_completed.connect(func(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray):
		# if result == RESULT_SUCCESS, emit signal
		if result == HTTPRequest.RESULT_SUCCESS:
			posted_login.emit(result,response_code,headers,body)
		else:
			print("error posting login:\n	result: {0}\n	response_code: {1}\n".format([result,response_code]))
		client.queue_free()
		)
	# build request body with provided login info
	var bodyDict = {}
	if type!='':
		bodyDict["type"] = type
	if address!='':
		bodyDict["address"] = address
	if device_id!='':
		bodyDict["device_id"] = device_id
	if !identifier.is_empty():
		bodyDict["identifier"] = identifier
	if initial_device_display_name!='':
		bodyDict["initial_device_display_name"] = initial_device_display_name
	if medium!='':
		bodyDict["medium"] = medium
	if password!='':
		bodyDict["password"] = password
	if refresh_token:
		bodyDict["refresh_token"] = refresh_token
	if token!='':
		bodyDict["token"] = token
	if user!='':
		bodyDict["user"] = user
	# creates and sends the request
	res = client.request(
	home_server+"_matrix/client/v3/login",
	headers,
	HTTPClient.METHOD_POST,
	str(bodyDict)
	)
	
## POST /_matrix/client/v3/refresh
## accepts: {base_url:String:fp, headers:Array:fp, refresh_token:String:bp}
## https://spec.matrix.org/v1.6/client-server-api/#post_matrixclientv3refresh
func post_refresh(base_url:String='', headers:Array=[], refresh_token:String=''):
	assert(base_url!='',"post_refresh: base_url is required")
	assert(refresh_token!='',"post_refresh: refresh_token is required")
	if headers.is_empty():
		push_warning("post_refresh: though headers are optional, it is recommended to provide them")
	var res
	var client = HTTPRequest.new()
	print("posting refresh for: ",base_url)
	client.use_threads = false
	Vector.requestParent.add_child(client)
	client.request_completed.connect(func(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray):
		# if result == RESULT_SUCCESS, emit signal
		if result == HTTPRequest.RESULT_SUCCESS:
			posted_refresh.emit(result,response_code,headers,body)
		else:
			print("error posting refresh:\n	result: {0}\n	response_code: {1}\n".format([result,response_code]))
		client.queue_free()
		)
	# build request body with provided refresh info
	var bodyDict = {}
	if refresh_token!='':
		bodyDict["refresh_token"] = refresh_token
	# creates and sends the request
	res = client.request(
	base_url+"_matrix/client/v3/refresh",
	headers,
	HTTPClient.METHOD_POST,
	str(bodyDict)
	)

## POST /_matrix/client/v3/logout
## accepts: {base_url:String:fp, headers:Array:fp}
## https://spec.matrix.org/v1.6/client-server-api/#post_matrixclientv3logout
## requires auth
func post_logout(base_url:String='', headers:Array=[]):
	assert(base_url!='',"post_logout: base_url is required")
	assert(!headers.is_empty(),"post_logout: must at least provide an auth header")
	var res
	var client = HTTPRequest.new()
	print("posting logout for: ",base_url)
	client.use_threads = false
	Vector.requestParent.add_child(client)
	client.request_completed.connect(func(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray):
		# if result == RESULT_SUCCESS, emit signal
		if result == HTTPRequest.RESULT_SUCCESS:
			posted_logout.emit(result,response_code,headers,body)
		else:
			print("error posting logout:\n	result: {0}\n	response_code: {1}\n".format([result,response_code]))
		client.queue_free()
		)
	res = client.request(
	base_url+"_matrix/client/v3/logout",
	headers,
	HTTPClient.METHOD_POST
	)

## POST /_matrix/client/v3/logout/all
## accepts: {base_url:String:fp, headers:Array:fp}
## https://spec.matrix.org/v1.6/client-server-api/#post_matrixclientv3logoutall
## requires auth
func post_logout_all(base_url:String='', headers:Array=[]):
	assert(base_url!='',"post_logout_all: base_url is required")
	assert(!headers.is_empty(),"post_logout_all: must at least provide an auth header")
	var res
	var client = HTTPRequest.new()
	print("posting logout_all for: ",base_url)
	client.use_threads = false
	Vector.requestParent.add_child(client)
	client.request_completed.connect(func(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray):
		# if result == RESULT_SUCCESS, emit signal
		if result == HTTPRequest.RESULT_SUCCESS:
			posted_logout_all.emit(result,response_code,headers,body)
		else:
			print("error posting logout_all:\n	result: {0}\n	response_code: {1}\n".format([result,response_code]))
		client.queue_free()
		)
	res = client.request(
	base_url+"_matrix/client/v3/logout/all",
	headers,
	HTTPClient.METHOD_POST
	)

## POST /_matrix/client/v3/account/deactivate
## accepts: {base_url:String:fp, headers:Array:fp, auth:Dictionary:bp, id_server:String:bp}
## https://spec.matrix.org/v1.6/client-server-api/#post_matrixclientv3accountdeactivate
## auth accepts: {session:String, type:String}
## https://spec.matrix.org/v1.6/client-server-api/#user-interactive-authentication-api
## requires auth
# TODO: look into how to handle the interactive auth
func post_account_deactivate(base_url:String='', headers:Array=[], auth:Dictionary={}, id_server:String=''):
	assert(base_url!='',"post_account_deactivate: base_url is required")
	assert(!headers.is_empty(),"post_account_deactivate: must at least provide an auth header")
	var res
	var client = HTTPRequest.new()
	print("posting account_deactivate for: ",base_url)
	client.use_threads = false
	Vector.requestParent.add_child(client)
	client.request_completed.connect(func(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray):
		# if result == RESULT_SUCCESS, emit signal
		if result == HTTPRequest.RESULT_SUCCESS:
			posted_account_deactivate.emit(result,response_code,headers,body)
		else:
			print("error posting account_deactivate:\n	result: {0}\n	response_code: {1}\n".format([result,response_code]))
		client.queue_free()
		)
	# build request body with provided info
	var bodyDict = {}
	if !auth.is_empty():
		bodyDict["auth"] = auth
	if id_server!='':
		bodyDict["id_server"] = id_server
	res = client.request(
	base_url+"_matrix/client/v3/account/deactivate",
	headers,
	HTTPClient.METHOD_POST,
	str(bodyDict)
	)

## POST /_matrix/client/v3/account/password
## accepts: {base_url:String:fp, headers:Array:fp, auth:Dictionary:bp, logout_devices:bool:bp, new_password:String:bp}
## https://spec.matrix.org/v1.6/client-server-api/#post_matrixclientv3accountpassword
## auth accepts: {session:String, type:String}
## https://spec.matrix.org/v1.6/client-server-api/#user-interactive-authentication-api
## requires auth
func post_account_password(base_url:String='', headers:Array=[], auth:Dictionary={}, logout_devices:bool=false, new_password:String=''):
	assert(base_url!='',"post_account_password: base_url is required")
	assert(!headers.is_empty(),"post_account_password: must at least provide an auth header")
	assert(new_password!='',"post_account_password: new_password is required")
	var res
	var client = HTTPRequest.new()
	print("posting account_password for: ",base_url)
	client.use_threads = false
	Vector.requestParent.add_child(client)
	client.request_completed.connect(func(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray):
		# if result == RESULT_SUCCESS, emit signal
		if result == HTTPRequest.RESULT_SUCCESS:
			posted_account_password.emit(result,response_code,headers,body)
		else:
			print("error posting account_password:\n	result: {0}\n	response_code: {1}\n".format([result,response_code]))
		client.queue_free()
		)
	# build request body with provided info
	var bodyDict = {}
	if !auth.is_empty():
		bodyDict["auth"] = auth
	if logout_devices:
		bodyDict["logout_devices"] = logout_devices
	if new_password!='':
		bodyDict["new_password"] = new_password
	res = client.request(
	base_url+"_matrix/client/v3/account/password",
	headers,
	HTTPClient.METHOD_POST,
	str(bodyDict)
	)

## POST /_matrix/client/v3/account/password/email/requestToken
## accepts: {base_url:String:fp, headers:Array:fp, client_secret:String:bp, email:String:bp, id_access_token:String:bp, id_server:String:bp, next_link:String:bp, send_attempt:String:bp}
## https://spec.matrix.org/v1.6/client-server-api/#post_matrixclientv3accountpasswordemailrequesttoken
func post_account_password_email_requestToken(base_url:String='', headers:Array=[], client_secret:String='', email:String='', id_access_token:String='', id_server:String='', next_link:String='', send_attempt:String=''):
	assert(base_url!='',"post_account_password_email_requestToken: base_url is required")
	if headers.is_empty():
		push_warning("post_account_password_email_requestToken: though headers are optional, it is recommended to provide them")
	var res
	var client = HTTPRequest.new()
	print("posting account_password for: ",base_url)
	client.use_threads = false
	Vector.requestParent.add_child(client)
	client.request_completed.connect(func(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray):
		# if result == RESULT_SUCCESS, emit signal
		if result == HTTPRequest.RESULT_SUCCESS:
			posted_account_password_email_requestToken.emit(result,response_code,headers,body)
		else:
			print("error posting post_account_password_email_requestToken:\n	result: {0}\n	response_code: {1}\n".format([result,response_code]))
		client.queue_free()
		)
	# build request body with provided info
	var bodyDict = {}
	if client_secret!='':
		bodyDict["client_secret"] = client_secret
	if email!='':
		bodyDict["email"] = email
	if id_access_token!='':
		bodyDict["id_access_token"] = id_access_token
	if id_server!='':
		bodyDict["id_server"] = id_server
	if next_link!='':
		bodyDict["next_link"] = next_link
	if send_attempt!='':
		bodyDict["send_attempt"] = send_attempt
	# make request
	res = client.request(
	base_url+"_matrix/client/v3/account/password",
	headers,
	HTTPClient.METHOD_POST,
	str(bodyDict)
	)

## POST /_matrix/client/v3/account/password/msisdn/requestToken
## accepts: {base_url:String:fp, headers:Array:fp, client_secret:String:bp, country:String:bp, id_access_token:String:bp, id_server:String:bp, next_link:String:bp, phone_number:String:bp, send_attempt:String:bp}
## https://spec.matrix.org/v1.6/client-server-api/#post_matrixclientv3accountpasswordmsisdnrequesttoken
func post_account_password_msisdn_requestToken(base_url:String='', headers:Array=[], client_secret:String='', country:String='', id_access_token:String='', id_server:String='', next_link:String='', phone_number:String='', send_attempt:String=''):
	assert(base_url!='',"post_account_password_msisdn_requestToken: base_url is required")
	if headers.is_empty():
		push_warning("post_account_password_msisdn_requestToken: though headers are optional, it is recommended to provide them")
	var res
	var client = HTTPRequest.new()
	print("posting account_password for: ",base_url)
	client.use_threads = false
	Vector.requestParent.add_child(client)
	client.request_completed.connect(func(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray):
		# if result == RESULT_SUCCESS, emit signal
		if result == HTTPRequest.RESULT_SUCCESS:
			posted_account_password_msisdn_requestToken.emit(result,response_code,headers,body)
		else:
			print("error posting post_account_password_msisdn_requestToken:\n	result: {0}\n	response_code: {1}\n".format([result,response_code]))
		client.queue_free()
		)
	# build request body with provided info
	var bodyDict = {}
	if client_secret!='':
		bodyDict["client_secret"] = client_secret
	if country!='':
		bodyDict["country"] = country
	if id_access_token!='':
		bodyDict["id_access_token"] = id_access_token
	if id_server!='':
		bodyDict["id_server"] = id_server
	if next_link!='':
		bodyDict["next_link"] = next_link
	if phone_number!='':
		bodyDict["phone_number"] = phone_number
	if send_attempt!='':
		bodyDict["send_attempt"] = send_attempt
	# make request
	res = client.request(
	base_url+"_matrix/client/v3/account/password",
	headers,
	HTTPClient.METHOD_POST,
	str(bodyDict)
	)

## POST /_matrix/client/v3/register
## accepts: {base_url:String:fp, headers:Array:fp, kind:String:qp, auth:Dictionary:bp, device_id:String:bp, inhibit_login:bool:bp, initial_device_display_name:String:bp, password:String:bp, refresh_token:bool:bp, username:String:bp}
## https://spec.matrix.org/v1.6/client-server-api/#post_matrixclientv3register
## auth accepts: {session:String, type:String}
## https://spec.matrix.org/v1.6/client-server-api/#user-interactive-authentication-api
## kind accepts: ["guest","user"]
func post_register(base_url:String='', headers:Array=[], kind:String='user', auth:Dictionary={}, device_id:String='', inhibit_login:bool=false, initial_device_display_name:String='', password:String='', refresh_token:bool=false, username:String=''):
	assert(base_url!='',"post_register: base_url is required")
	if headers.is_empty():
		push_warning("post_register: though headers are optional, it is recommended to provide them")
	var res
	var client = HTTPRequest.new()
	print("registering for: ",base_url)
	client.use_threads = false
	Vector.requestParent.add_child(client)
	client.request_completed.connect(func(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray):
		# if result == RESULT_SUCCESS, emit signal
		if result == HTTPRequest.RESULT_SUCCESS:
			posted_register.emit(result,response_code,headers,body)
		else:
			print("error posting post_register:\n	result: {0}\n	response_code: {1}\n".format([result,response_code]))
		client.queue_free()
		)
	# build query string
	var qp = ""
	if kind!='':
		qp += "?kind="+kind
		
	# build request body with provided info
	var bodyDict = {}
	if auth!=null:
		bodyDict["auth"] = auth
	if device_id!='':
		bodyDict["device_id"] = device_id
	if inhibit_login!=false:
		bodyDict["inhibit_login"] = inhibit_login
	if initial_device_display_name!='':
		bodyDict["initial_device_display_name"] = initial_device_display_name
	if password!='':
		bodyDict["password"] = password
	if refresh_token!=false:
		bodyDict["refresh_token"] = refresh_token
	if username!='':
		bodyDict["username"] = username
	# make request
	res = client.request(
	base_url+"_matrix/client/v3/register"+qp,
	headers,
	HTTPClient.METHOD_POST,
	str(bodyDict)
	)

## GET /_matrix/client/v3/register/available
## accepts: {base_url:String:fp, headers:Array:fp, username:String:qp}
## https://spec.matrix.org/v1.6/client-server-api/#get_matrixclientv3registeravailable
func get_register_available(base_url:String='', headers:Array=[], username:String=''):
	assert(base_url!='',"get_register_available: base_url is required")
	if headers.is_empty():
		push_warning("get_register_available: though headers are optional, it is recommended to provide them")
	var res
	var client = HTTPRequest.new()
	print("getting register_available for: ",base_url)
	client.use_threads = false
	Vector.requestParent.add_child(client)
	client.request_completed.connect(func(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray):
		# if result == RESULT_SUCCESS, emit signal
		if result == HTTPRequest.RESULT_SUCCESS:
			got_register_available.emit(result,response_code,headers,body)
		else:
			print("error getting get_register_available:\n	result: {0}\n	response_code: {1}\n".format([result,response_code]))
		client.queue_free()
		)
	# build query string
	var qp = ""
	if username!='':
		qp += "?username="+username
	# make request
	res = client.request(
	base_url+"_matrix/client/v3/register/available",
	headers,
	HTTPClient.METHOD_GET,
	)

## POST /_matrix/client/v3/register/email/requestToken
## accepts: {base_url:String:fp, headers:Array:fp, client_secret:String:bp, email:String:bp, id_access_token:String:bp, id_server:String:bp, send_attempt:int:bp, sid:String:bp}
## https://spec.matrix.org/v1.6/client-server-api/#post_matrixclientv3registeremailrequesttoken
func post_register_email_requesttoken(base_url:String='', headers:Array=[], client_secret:String='', email:String='', id_access_token:String='', id_server:String='', send_attempt:int=-99, sid:String=''):
	assert(base_url!='',"post_register_email_requesttoken: base_url is required")
	if headers.is_empty():
		push_warning("post_register_email_requesttoken: though headers are optional, it is recommended to provide them")
	var res
	var client = HTTPRequest.new()
	print("registering email_requesttoken for: ",base_url)
	client.use_threads = false
	Vector.requestParent.add_child(client)
	client.request_completed.connect(func(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray):
		# if result == RESULT_SUCCESS, emit signal
		if result == HTTPRequest.RESULT_SUCCESS:
			posted_register_email_requesttoken.emit(result,response_code,headers,body)
		else:
			print("error posting post_register_email_requesttoken:\n	result: {0}\n	response_code: {1}\n".format([result,response_code]))
		client.queue_free()
		)
	# build request body with provided info
	var bodyDict = {}
	if client_secret!='':
		bodyDict["client_secret"] = client_secret
	if email!='':
		bodyDict["email"] = email
	if id_access_token!='':
		bodyDict["id_access_token"] = id_access_token
	if id_server!='':
		bodyDict["id_server"] = id_server
	if send_attempt!=-99:
		bodyDict["send_attempt"] = send_attempt
	if sid!='':
		bodyDict["sid"] = sid
	# make request
	res = client.request(
	base_url+"_matrix/client/v3/register/email/requestToken",
	headers,
	HTTPClient.METHOD_POST,
	str(bodyDict)
	)

## POST /_matrix/client/v3/register/msisdn/requestToken
## accepts: {base_url:String:fp, headers:Array:fp, client_secret:String:bp, country:String:bp, id_access_token:String:bp, id_server:String:bp, next_link:String:bp, phone_number:String:bp, send_attempt:int:bp}
## https://spec.matrix.org/v1.6/client-server-api/#post_matrixclientv3registermsisdnrequesttoken
func post_register_msisdn_requesttoken(base_url:String='', headers:Array=[], client_secret:String='', country:String='', id_access_token:String='', id_server:String='', next_link:String='', phone_number:String='', send_attempt:int=-99):
	assert(base_url!='',"post_register_msisdn_requesttoken: base_url is required")
	if headers.is_empty():
		push_warning("post_register_msisdn_requesttoken: though headers are optional, it is recommended to provide them")
	var res
	var client = HTTPRequest.new()
	print("registering msisdn_requesttoken for: ",base_url)
	client.use_threads = false
	Vector.requestParent.add_child(client)
	client.request_completed.connect(func(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray):
		# if result == RESULT_SUCCESS, emit signal
		if result == HTTPRequest.RESULT_SUCCESS:
			posted_register_msisdn_requesttoken.emit(result,response_code,headers,body)
		else:
			print("error posting post_register_msisdn_requesttoken:\n	result: {0}\n	response_code: {1}\n".format([result,response_code]))
		client.queue_free()
		)
	# build request body with provided info
	var bodyDict = {}
	if client_secret!='':
		bodyDict["client_secret"] = client_secret
	if country!='':
		bodyDict["country"] = country
	if id_access_token!='':
		bodyDict["id_access_token"] = id_access_token
	if id_server!='':
		bodyDict["id_server"] = id_server
	if next_link!='':
		bodyDict["next_link"] = next_link
	if phone_number!='':
		bodyDict["phone_number"] = phone_number
	if send_attempt!=-99:
		bodyDict["send_attempt"] = send_attempt
	# make request
	res = client.request(
	base_url+"_matrix/client/v3/register/msisdn/requestToken",
	headers,
	HTTPClient.METHOD_POST,
	str(bodyDict)
	)

## GET /_matrix/client/v3/rooms/{roomId}/messages
## accepts: {roomId:String:fp, dir:String:qp, filter:String:qp, from:String:qp, limit:int:qp, to:String:qp}
## https://spec.matrix.org/v1.7/client-server-api/#get_matrixclientv3roomsroomidmessages
func get_room_messages(base_url:String='', headers:Array=[], roomId: String = '', dir: String = '', filter:String = '', from:String = '', limit:int = -99, to:String = ''):
	assert(roomId=='',"get_room_messages: roomId is required")
	if dir == '':
		dir = 'b'
	if headers.is_empty():
		push_warning("get_room_messages: headers are required to be set for this call, due to authentication requirements")
	var res
	var client = HTTPRequest.new()
	print("getting room_messages for: ",roomId)
	client.use_threads = false
	Vector.requestParent.add_child(client)
	client.request_completed.connect(func(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray):
		# if result == RESULT_SUCCESS, emit signal
		if result == HTTPRequest.RESULT_SUCCESS:
			got_room_messages.emit(result,response_code,headers,body)
		else:
			print("error getting room_messages:\n	result: {0}\n	response_code: {1}\n".format([result,response_code]))
		client.queue_free()
		)
	# build request body with provided info
	var bodyDict = {}
	if dir!='':
		bodyDict["dir"] = dir
	if filter!='':
		bodyDict["filter"] = filter
	if from!='':
		bodyDict["from"] = from
	if limit!=-99:
		bodyDict["limit"] = limit
	if to!='':
		bodyDict["to"] = to
	# make request
	res = client.request(
	base_url+"_matrix/client/v3/rooms/"+roomId+"/messages",
	headers,
	HTTPClient.METHOD_GET,
	str(bodyDict)
	)
	


















func login_username_password(homeserver:String,username:String,password:String):
	var client = HTTPRequest.new()
	client.use_threads = false
	Vector.requestParent.add_child(client)
	client.request_completed.connect(func(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray):
		user_logged_in.emit(result,response_code,headers,body)
		client.queue_free()
		)
	var loginDict = {
		"type": "m.login.password",
		"password": password,
		"user": username,
		"device_id": OS.get_unique_id(),
		"initial_device_display_name": "bark"
		}
	var response = await Vector.connect_to_homeserver(homeserver)
	assert(response == OK)
	response = client.request(
		"https://"+homeserver+"/_matrix/client/v3/login",
		Vector.headers,
		HTTPClient.METHOD_POST,
		str(loginDict)
		)
	assert(response == OK)
	assert(client.get_http_client_status()==0)

func get_joined_rooms():
	print('getting joined rooms')
	var res
	if Vector.userData['login'].has("access_token"):
		var client = HTTPRequest.new()
		client.use_threads = false
		Vector.requestParent.add_child(client)
		client.request_completed.connect(func(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray):
			got_joined_rooms.emit(result,response_code,headers,body)
			client.queue_free()
			)
		res = client.request(
		Vector.base_url+"_matrix/client/v3/joined_rooms",
		Vector.headers,
		HTTPClient.METHOD_GET
		)
	else:
		printerr("User token not assigned yet, try logging the user in first.")

## GET /_matrix/client/v3/sync
## accepts: {since:String, filter:String, set_presence:String, timeout:int, full_state:bool}
## https://spec.matrix.org/v1.6/client-server-api/#get_matrixclientv3sync
func sync(options:Dictionary):
	var res
	var client = HTTPRequest.new()
	client.use_threads = false
	Vector.requestParent.add_child(client)
	client.request_completed.connect(func(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray):
		synced.emit(result,response_code,headers,body)
		client.queue_free()
		)
	var qp = ''
	if !options.is_empty():
		qp = "?"
		if options.has('since'):
			qp += "since="+str(options.since)
		if options.has('filter'):
			qp += "&filter="+str(options.filter)
		if options.has('set_presence'):
			qp += "&set_presence="+str(options.set_presence)
		if options.has('timeout'):
			qp += "&timeout="+str(options.timeout)
		if options.has('full_state'):
			qp += "&full_state="+str(options.full_state)
	res = client.request(
	Vector.base_url+"_matrix/client/v3/sync"+qp,
	Vector.headers,
	HTTPClient.METHOD_GET
	)
	print("url: ",Vector.base_url+"_matrix/client/v3/sync"+qp)
	
## Get the state events for the current state of a room
## Url: /_matrix/client/v3/rooms/{roomId}/state
func get_room_state(room_id:String):
	var client = HTTPRequest.new()
	client.use_threads = false
	Vector.requestParent.add_child(client)
	client.request_completed.connect(func(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray):
		got_room_state.emit(result,response_code,headers,body)
		client.queue_free()
		)
	var res
	res = client.request(
		Vector.base_url+"_matrix/client/v3/rooms/{0}/state".format([room_id]),
		Vector.headers,
		HTTPClient.METHOD_GET
		)
	
## Gets a list of message and state events for a room. It uses pagination query parameters to paginate history in the room.
## Url: /_matrix/client/v3/rooms/{roomId}/messages
#func get_room_messages(room_id:String, dir:String='', filter:String='',from:String='', limit:int=-1, to:String=''):
#	var res
#	if Vector.client.get_status() == HTTPClient.STATUS_CONNECTED:
#		res = Vector.client.request(HTTPClient.METHOD_GET, "/_matrix/client/v3/rooms/{0}/messages?limit={1}".format([
#			room_id,
#			limit if limit<-1 else 100
#			]),Vector.headers)
#		var msg = await Vector.readRequestBytes()
#		return JSON.parse_string(msg)
	
## Gets a list of aliases for the specified room
## Url: /_matrix/client/v3/rooms/{roomId}/aliases
func get_room_aliases(room_id:String):
	var res
	if Vector.client.get_status() == HTTPClient.STATUS_CONNECTED:
		res = Vector.client.request(
			HTTPClient.METHOD_GET,
			"/_matrix/client/v3/rooms/{0}/aliases".format([room_id]),
			Vector.headers)
		var msg = await Vector.readRequestBytes()
		var pmsg = JSON.parse_string(msg)
		return pmsg
