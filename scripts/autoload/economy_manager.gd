extends Node

signal balance_changed(new_balance: float)
signal transaction(amount: float, category: String, description: String)
signal bankruptcy()

const STARTING_BALANCE := 500_000.0

var balance: float = STARTING_BALANCE
var daily_pass_price: float = 35.0

var revenue_categories: Dictionary = {
	"ski_passes": 0.0,
	"lift_tickets": 0.0,
	"other": 0.0,
}

var expense_categories: Dictionary = {
	"maintenance": 0.0,
	"staff": 0.0,
	"utilities": 0.0,
	"other": 0.0,
}

var monthly_history: Array = []
var _current_month_revenue: float = 0.0
var _current_month_expenses: float = 0.0


func _ready() -> void:
	TimeManager.day_changed.connect(_on_day_changed)
	TimeManager.month_changed.connect(_on_month_changed)


func can_afford(amount: float) -> bool:
	return balance >= amount


func purchase(amount: float, description: String = "") -> bool:
	if not can_afford(amount):
		return false
	balance -= amount
	_current_month_expenses += amount
	expense_categories["other"] += amount
	emit_signal("balance_changed", balance)
	emit_signal("transaction", -amount, "purchase", description)
	if balance < 0.0:
		emit_signal("bankruptcy")
	return true


func add_revenue(amount: float, category: String = "other", description: String = "") -> void:
	balance += amount
	_current_month_revenue += amount
	if revenue_categories.has(category):
		revenue_categories[category] += amount
	else:
		revenue_categories[category] = amount
	emit_signal("balance_changed", balance)
	emit_signal("transaction", amount, category, description)


func add_expense(amount: float, category: String = "other", description: String = "") -> void:
	balance -= amount
	_current_month_expenses += amount
	if expense_categories.has(category):
		expense_categories[category] += amount
	else:
		expense_categories[category] = amount
	emit_signal("balance_changed", balance)
	emit_signal("transaction", -amount, category, description)
	if balance < 0.0:
		emit_signal("bankruptcy")


func _on_day_changed(day: int, month: int, year: int) -> void:
	# Daily maintenance costs paid by network graph registered infrastructure
	var daily_total := 0.0
	for slope in NetworkGraph.all_slopes:
		if slope.is_open:
			daily_total += slope.maintenance_cost_per_day
	for lift in NetworkGraph.all_lifts:
		if lift.is_open:
			daily_total += lift.get_daily_maintenance()
	if daily_total > 0.0:
		add_expense(daily_total, "maintenance", "Entretien quotidien")


func _on_month_changed(month: int, year: int) -> void:
	monthly_history.append({
		"month": month,
		"year": year,
		"revenue": _current_month_revenue,
		"expenses": _current_month_expenses,
		"balance": balance,
	})
	_current_month_revenue = 0.0
	_current_month_expenses = 0.0


func format_money(amount: float) -> String:
	var abs_amount := absi(int(amount))
	var result := str(abs_amount)
	var formatted := ""
	var count := 0
	for i in range(result.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			formatted = " " + formatted
		formatted = result[i] + formatted
		count += 1
	if amount < 0.0:
		formatted = "-" + formatted
	return formatted + " €"
