class_name TinyNeuralNetwork
extends RefCounted

## Minimal 1-hidden-layer MLP for headless training prototypes.

const DEFAULT_HIDDEN_SIZE := 8

var input_size: int = 0
var hidden_size: int = DEFAULT_HIDDEN_SIZE
var output_size: int = 0
var weights_ih: PackedFloat32Array = PackedFloat32Array()
var bias_h: PackedFloat32Array = PackedFloat32Array()
var weights_ho: PackedFloat32Array = PackedFloat32Array()
var bias_o: PackedFloat32Array = PackedFloat32Array()


static func from_seed(input_size: int, output_size: int, rng_seed: int, hidden_size: int = DEFAULT_HIDDEN_SIZE) -> TinyNeuralNetwork:
	var net := TinyNeuralNetwork.new()
	net.input_size = input_size
	net.hidden_size = hidden_size
	net.output_size = output_size
	var rng := GameRng.new()
	rng.seed(rng_seed)
	net.weights_ih = _random_matrix(rng, input_size * hidden_size, 0.08)
	net.bias_h = _random_vector(rng, hidden_size, 0.02)
	net.weights_ho = _random_matrix(rng, hidden_size * output_size, 0.08)
	net.bias_o = _random_vector(rng, output_size, 0.02)
	return net


static func clone_from(other: TinyNeuralNetwork) -> TinyNeuralNetwork:
	var net := TinyNeuralNetwork.new()
	net.input_size = other.input_size
	net.hidden_size = other.hidden_size
	net.output_size = other.output_size
	net.weights_ih = other.weights_ih.duplicate()
	net.bias_h = other.bias_h.duplicate()
	net.weights_ho = other.weights_ho.duplicate()
	net.bias_o = other.bias_o.duplicate()
	return net


func forward(input: PackedFloat32Array) -> PackedFloat32Array:
	var hidden := PackedFloat32Array()
	hidden.resize(hidden_size)
	for h in range(hidden_size):
		var sum := bias_h[h]
		for i in range(mini(input.size(), input_size)):
			sum += input[i] * weights_ih[i * hidden_size + h]
		hidden[h] = maxf(0.0, sum)
	var output := PackedFloat32Array()
	output.resize(output_size)
	for o in range(output_size):
		var sum := bias_o[o]
		for h in range(hidden_size):
			sum += hidden[h] * weights_ho[h * output_size + o]
		output[o] = sum
	return output


func choose_action_index(logits: PackedFloat32Array, legal_mask: Array) -> int:
	var best_index := -1
	var best_score := -INF
	for i in range(mini(logits.size(), legal_mask.size())):
		if not bool(legal_mask[i]):
			continue
		var score := logits[i]
		if is_nan(score):
			score = -INF
		if score > best_score:
			best_score = score
			best_index = i
	if best_index < 0:
		for i in range(mini(logits.size(), legal_mask.size())):
			if bool(legal_mask[i]):
				return i
	return best_index


func train_supervised_step(input: PackedFloat32Array, target_index: int, learning_rate: float) -> float:
	if target_index < 0 or target_index >= output_size:
		return 0.0
	var hidden := PackedFloat32Array()
	hidden.resize(hidden_size)
	for h in range(hidden_size):
		var sum := bias_h[h]
		for i in range(mini(input.size(), input_size)):
			sum += input[i] * weights_ih[i * hidden_size + h]
		hidden[h] = maxf(0.0, sum)
	var output := forward(input)
	var loss := 0.0
	for o in range(output_size):
		var target := 1.0 if o == target_index else 0.0
		var error := output[o] - target
		loss += error * error
		bias_o[o] -= learning_rate * error
		for h in range(hidden_size):
			weights_ho[h * output_size + o] -= learning_rate * error * hidden[h]
	for h in range(hidden_size):
		var hidden_grad := 0.0
		for o in range(output_size):
			var target := 1.0 if o == target_index else 0.0
			var error := output[o] - target
			hidden_grad += error * weights_ho[h * output_size + o]
		if hidden[h] <= 0.0:
			continue
		bias_h[h] -= learning_rate * hidden_grad
		for i in range(mini(input.size(), input_size)):
			weights_ih[i * hidden_size + h] -= learning_rate * hidden_grad * input[i]
	return loss


func to_dict() -> Dictionary:
	return {
		"input_size": input_size,
		"hidden_size": hidden_size,
		"output_size": output_size,
		"weights_ih": Array(weights_ih),
		"bias_h": Array(bias_h),
		"weights_ho": Array(weights_ho),
		"bias_o": Array(bias_o),
	}


static func from_dict(data: Dictionary) -> TinyNeuralNetwork:
	var net := TinyNeuralNetwork.new()
	net.input_size = int(data.get("input_size", 0))
	net.hidden_size = int(data.get("hidden_size", DEFAULT_HIDDEN_SIZE))
	net.output_size = int(data.get("output_size", 0))
	net.weights_ih = _array_to_packed(data.get("weights_ih", []))
	net.bias_h = _array_to_packed(data.get("bias_h", []))
	net.weights_ho = _array_to_packed(data.get("weights_ho", []))
	net.bias_o = _array_to_packed(data.get("bias_o", []))
	return net


static func _random_matrix(rng: GameRng, count: int, scale: float) -> PackedFloat32Array:
	var values := PackedFloat32Array()
	values.resize(count)
	for i in range(count):
		values[i] = rng.rand_range(-scale, scale)
	return values


static func _random_vector(rng: GameRng, count: int, scale: float) -> PackedFloat32Array:
	return _random_matrix(rng, count, scale)


static func _array_to_packed(value) -> PackedFloat32Array:
	var packed := PackedFloat32Array()
	if typeof(value) != TYPE_ARRAY:
		return packed
	for entry in value:
		packed.append(float(entry))
	return packed
