--!strict

local RateLimiter = {}
RateLimiter.__index = RateLimiter

export type RateLimiter = typeof(setmetatable(
	{} :: {
		_lastSeen: { [string | number]: number },
	},
	{} :: typeof(RateLimiter)
))

function RateLimiter.new(): RateLimiter
	return setmetatable({
		_lastSeen = {} :: { [string | number]: number },
	}, RateLimiter)
end

function RateLimiter.allow(
	self: RateLimiter,
	key: string | number,
	intervalSeconds: number,
	now: number?
): boolean
	assert(intervalSeconds >= 0, "intervalSeconds must be non-negative")
	local timestamp = now or os.clock()
	local previous = self._lastSeen[key]
	if previous ~= nil and timestamp - previous < intervalSeconds then
		return false
	end
	self._lastSeen[key] = timestamp
	return true
end

function RateLimiter.clear(self: RateLimiter, key: string | number)
	self._lastSeen[key] = nil
end

function RateLimiter.clearAll(self: RateLimiter)
	table.clear(self._lastSeen)
end

return RateLimiter
