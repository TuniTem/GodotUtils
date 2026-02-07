extends RefCounted
class_name Buffer

enum Type {
	POP_BACK
}

signal buffer_value_removed(value : Variant)

var size : int
var data : Array
var type : Type

func  _init(_size : int, _type : Type = Type.POP_BACK) -> void:
	assert(_size > 1)
	size = _size
	type = _type

func push(value : Variant):
	match type:
		Type.POP_BACK:
			data.append(value)
			if data.size() > size:
				buffer_value_removed.emit(data.pop_front())

func pull():
	var removed : Variant = data.pop_front()
	buffer_value_removed.emit(removed)
	return removed

func pull_back():
	var removed : Variant = data.pop_back()
	buffer_value_removed.emit(removed)
	return removed
