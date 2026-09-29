--!strict

local RequestBudget = {}
RequestBudget.__index = RequestBudget

export type RequestBudget = typeof(setmetatable(
	{} :: {
		_buckets: { [Player]: { [string]: { tokens: number, updatedAt: number } } },
	},
	RequestBudget
))

local POLICIES = table.freeze({
	Read = { capacity = 8, refill = 4 },
	Mutation = { capacity = 4, refill = 2 },
	Claim = { capacity = 2, refill = 1 },
})

function RequestBudget.new(): RequestBudget
	return setmetatable({ _buckets = {} }, RequestBudget)
end

function RequestBudget:allow(player: Player, category: string, now: number?): boolean
	local policy = POLICIES[category]
	assert(policy ~= nil, "Unknown request budget category")
	local timestamp = now or os.clock()
	local playerBuckets = self._buckets[player]
	if playerBuckets == nil then
		playerBuckets = {}
		self._buckets[player] = playerBuckets
	end
	local bucket = playerBuckets[category]
	if bucket == nil then
		bucket = { tokens = policy.capacity, updatedAt = timestamp }
		playerBuckets[category] = bucket
	end
	bucket.tokens = math.min(
		policy.capacity,
		bucket.tokens + math.max(0, timestamp - bucket.updatedAt) * policy.refill
	)
	bucket.updatedAt = timestamp
	if bucket.tokens < 1 then
		return false
	end
	bucket.tokens -= 1
	return true
end

function RequestBudget:forget(player: Player)
	self._buckets[player] = nil
end

return RequestBudget
