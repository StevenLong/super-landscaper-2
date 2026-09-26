# The season's money: payday pays the shark, short means the heavies take your dearest
# kit (you keep the change), nothing left means bankrupt, the last payment wins.
extends SceneTree


func _initialize() -> void:
	var g: Node = root.get_node("Game")
	g.save_path = "user://test_best.cfg"
	g.new_run(7)
	assert(not g.payday_due() and g.payment() == g.PAYMENTS[0], "a new season owes week 1's payment")
	g.jobs_done = g.JOBS_PER_WEEK
	assert(g.payday_due(), "after the week's jobs, payday")
	# Enough cash: paid, on to week 2.
	g.money = g.PAYMENTS[0] + 10
	var r: Dictionary = g.settle_payday()
	assert(r.outcome == "paid" and g.money == 10 and g.week == 2 and not g.payday_due(), "paid, $10 left, week 2")
	# Short: the heavies take the dearest kit first, until it covers it.
	g.owned.assign(["push", "petrol", "rideon"])
	g.equipped = "rideon"
	g.upgrades.assign(["blades"])
	g.jobs_done = 2 * g.JOBS_PER_WEEK
	g.money = 0
	r = g.settle_payday()
	assert(r.taken == ["rideon"], "the ride-on alone covers $250: nothing else goes")
	assert(r.outcome == "repossessed" and g.money == g.resale("rideon") - g.PAYMENTS[1], "you keep the change")
	assert(g.equipped == "petrol", "back on your best remaining mower")
	# Selling yourself: same rate; the push mower is never on the list.
	assert(g.sellable() == ["petrol", "blades"], "sellable, dearest first, no push mower")
	g.sell("blades")
	assert("blades" not in g.upgrades, "sold")
	# Nothing left covers it: bankrupt.
	g.jobs_done = 3 * g.JOBS_PER_WEEK
	g.money = 0
	r = g.settle_payday()
	assert(r.outcome == "bankrupt" and g.run_over_reason == "bankrupt" and g.owned == ["push"], "stripped and still short: bankrupt")
	# The last payment wins the season.
	g.new_run(7)
	g.week = g.PAYMENTS.size()
	g.jobs_done = g.week * g.JOBS_PER_WEEK
	g.money = g.PAYMENTS[-1]
	r = g.settle_payday()
	assert(r.outcome == "won" and g.run_over_reason == "won", "paying week 4 wins")
	# Zero reputation: still one job, the dregs, at half pay.
	g.new_run(7)
	g.reputation = 0.0
	var dregs: Array = g.make_offers()
	assert(dregs.size() == 1 and dregs[0].persona == "grump", "the dregs: one hostile job")
	print("PASS season")
	quit()
