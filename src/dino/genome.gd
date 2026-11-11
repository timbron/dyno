class_name Genome
extends Resource
## Heritable DNA mutations carried by a lineage. Skills die with the dino; the genome is
## what the next generation can inherit.

@export var mutation_ids: Array[StringName] = []


func has_mutation(id: StringName) -> bool:
	return mutation_ids.has(id)


func add_mutation(id: StringName) -> void:
	if not has_mutation(id):
		mutation_ids.append(id)


## Returns the offspring genome: each mutation passes on with [param pass_chance].
func inherit(rng: RandomNumberGenerator, pass_chance: float = 0.5) -> Genome:
	var child := Genome.new()
	for id: StringName in mutation_ids:
		if rng.randf() <= pass_chance:
			child.mutation_ids.append(id)
	return child
