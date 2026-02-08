extends RefCounted
class_name Buffer

enum Type {
	VALUE_QUEUE,
	NODE_METHOD
}

signal buffer_value_removed(value : Variant)

var size : int
var data : Array
var type : Type
var method : String
var args : Array

func  _init(_size : int, _type : Type = Type.VALUE_QUEUE) -> void:
	assert(_size > 1)
	size = _size
	type = _type

func set_method(_method_string : String, _args : Array = []):
	method = _method_string
	args = _args

func push(value : Variant):
	match type:
		Type.VALUE_QUEUE, Type.NODE_METHOD:
			data.append(value)
			if data.size() > size:
				var removed : Node = data.pop_front()
				buffer_value_removed.emit(removed)
				if type == Type.NODE_METHOD: removed.callv(method, args)

func pull():
	var removed : Variant = data.pop_front()
	buffer_value_removed.emit(removed)
	if type == Type.NODE_METHOD: removed.callv(method, args)
	return removed

func pull_back():
	var removed : Variant = data.pop_back()
	buffer_value_removed.emit(removed)
	if type == Type.NODE_METHOD: removed.callv(method, args)
	return removed
