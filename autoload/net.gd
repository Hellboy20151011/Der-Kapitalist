extends Node
class_name Net

var base_url := "http://localhost:3000"
var token: String = ""

func _headers() -> PackedStringArray:
	var h := PackedStringArray(["Content-Type: application/json"])
	if token != "":
		h.append("Authorization: Bearer %s" % token)
	return h

func post_json(path: String, body: Dictionary) -> Dictionary:
	var http := HTTPRequest.new()
	add_child(http)
	var err := http.request(base_url + path, _headers(), HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		http.queue_free()
		return {"ok": false, "error": "request_failed"}
	var result = await http.request_completed
	http.queue_free()

	var code: int = result[1]
	var bytes: PackedByteArray = result[3]
	var text := bytes.get_string_from_utf8()
	var data = {}
	if text != "":
		data = JSON.parse_string(text)
	return {"ok": code >= 200 and code < 300, "code": code, "data": data}

func get_json(path: String) -> Dictionary:
	var http := HTTPRequest.new()
	add_child(http)
	var err := http.request(base_url + path, _headers(), HTTPClient.METHOD_GET)
	if err != OK:
		http.queue_free()
		return {"ok": false, "error": "request_failed"}
	var result = await http.request_completed
	http.queue_free()

	var code: int = result[1]
	var bytes: PackedByteArray = result[3]
	var text := bytes.get_string_from_utf8()
	var data = {}
	if text != "":
		data = JSON.parse_string(text)
	return {"ok": code >= 200 and code < 300, "code": code, "data": data}