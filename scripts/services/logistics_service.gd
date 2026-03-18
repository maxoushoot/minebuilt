extends RefCounted
class_name LogisticsService

func tick_simple_flow(stocks: Dictionary, production: Dictionary, consumption: Dictionary) -> Dictionary:
	var next := stocks.duplicate(true)
	for key in production.keys():
		next[key] = int(next.get(key, 0)) + int(production[key])
	for key in consumption.keys():
		next[key] = max(0, int(next.get(key, 0)) - int(consumption[key]))
	return next
