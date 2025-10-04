class_name UniqueIdentifierGenerator

const MAX_GENERATION_ATTEMPTS : int = 3000

var _generation_attempts : int

var _generated_ids : Array[int] = []
var _rand : RandomNumberGenerator = RandomNumberGenerator.new()

func _init(seed : int = -1, max_generation_attempts : int = MAX_GENERATION_ATTEMPTS) -> void:
	if seed == -1:
		randomize()
	else:
		_rand.seed = seed
	_generation_attempts = max_generation_attempts

func create_unique_id() -> int:
	for i in MAX_GENERATION_ATTEMPTS:
		var test_id : int = _rand.randi()
		if not _generated_ids.has(test_id):
			_generated_ids.append(test_id)
			return test_id
	
	printerr("MAX UID GENERATION ATTEMPTS EXCEEDED, THIS REALLY SHOULD NOT HAPPEN!! CONTINUING GRACEFULLY AND YOU WILL NOT NOTICE ANYTHING BREAK UNLESS UR REALLY UNLUCKY BUT LIKE TOTTALLY FIX THIS COS THE UID SYSTEM JUST ISNT WORKING")
	return randi()
