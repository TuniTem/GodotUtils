class_name Promise
## Object to handle awaits on multiple signals

# modified from https://github.com/godotengine/godot-proposals/issues/6243#issuecomment-1419495665

signal completed

enum Mode {
	ANY,
	ALL
}

var mode : int = Mode.ANY
var _signals : Dictionary[Signal, bool] = {}
var _connected_callables : Array[Callable] = []

func _init(signals: Array[Signal], _mode: Mode = Mode.ANY, delete_on_completion : bool = true) -> void:
	Util.active_promises.append(self)
	if delete_on_completion: completed.connect(delete)
	mode = _mode
	match mode:
		Mode.ANY:
			for sig in signals:
				sig.connect(_on_signal)
				
		Mode.ALL:
			for sig in signals:
				sig.connect(_on_signal.bind(sig))
				_signals[sig] = false


func _on_signal(arg1: Variant = null, arg2: Variant = null, arg3: Variant = null, arg4: Variant = null, arg5: Variant = null, arg6 : Variant = null) -> void:
	match mode:
		Mode.ANY:
			_emit()
		Mode.ALL:
			for arg in [arg1, arg2, arg3, arg4, arg5, arg6]:
				if typeof(arg) == TYPE_SIGNAL and _signals.has(arg):
					_signals[arg] = true
			
			for key in _signals.keys():
				if not _signals[key]:
					return
			
			_emit()

func _emit():
	completed.emit()
	for callable : Callable in _connected_callables:
		callable.call()

func connect_call(callable : Callable):
	_connected_callables.append(callable)

func delete(): 
	Util.active_promises.erase(self) # Sepuku
