extends Node

# NetworkGraph — registry for all hubs, slopes and lifts; BFS pathfinding

var all_hubs: Array = []
var all_slopes: Array = []
var all_lifts: Array = []
var village_hub = null  # Reference to the default village hub


func register_hub(hub) -> void:
	if not all_hubs.has(hub):
		all_hubs.append(hub)
		if hub.hub_type == 0:  # Hub.Type.VILLAGE_SPAWN
			village_hub = hub


func register_slope(slope) -> void:
	if not all_slopes.has(slope):
		all_slopes.append(slope)


func register_lift(lift) -> void:
	if not all_lifts.has(lift):
		all_lifts.append(lift)


func unregister_hub(hub) -> void:
	all_hubs.erase(hub)
	if village_hub == hub:
		village_hub = null


func unregister_slope(slope) -> void:
	all_slopes.erase(slope)


func unregister_lift(lift) -> void:
	all_lifts.erase(lift)


## BFS through slopes to find a route back to the village hub.
## Returns an array of hubs from `from_hub` to `village_hub`, or empty if none.
func find_path_to_village(from_hub) -> Array:
	if village_hub == null or from_hub == village_hub:
		return [from_hub] if from_hub == village_hub else []

	var visited := {}
	var queue := [[from_hub]]
	visited[from_hub] = true

	while queue.size() > 0:
		var path: Array = queue.pop_front()
		var current = path[-1]

		# Explore connected slopes (departure → arrival)
		for slope in current.connected_slope_departures:
			if slope.arrival_hub != null and not visited.has(slope.arrival_hub):
				var new_path := path.duplicate()
				new_path.append(slope.arrival_hub)
				if slope.arrival_hub == village_hub:
					return new_path
				visited[slope.arrival_hub] = true
				queue.append(new_path)

		# Explore connected lifts (arrival → departure, going up then down)
		for lift in current.connected_lift_arrivals:
			if lift.departure_hub != null and not visited.has(lift.departure_hub):
				var new_path := path.duplicate()
				new_path.append(lift.departure_hub)
				if lift.departure_hub == village_hub:
					return new_path
				visited[lift.departure_hub] = true
				queue.append(new_path)

	return []


func get_network_stats() -> Dictionary:
	var open_slopes := 0
	var open_lifts := 0
	for slope in all_slopes:
		if slope.is_open:
			open_slopes += 1
	for lift in all_lifts:
		if lift.is_open:
			open_lifts += 1

	return {
		"total_hubs": all_hubs.size(),
		"total_slopes": all_slopes.size(),
		"total_lifts": all_lifts.size(),
		"open_slopes": open_slopes,
		"open_lifts": open_lifts,
	}


func find_nearest_hub(world_position: Vector3, max_radius: float = 50.0):
	var nearest = null
	var nearest_dist := max_radius * max_radius
	for hub in all_hubs:
		var dist_sq := hub.global_position.distance_squared_to(world_position)
		if dist_sq < nearest_dist:
			nearest_dist = dist_sq
			nearest = hub
	return nearest
