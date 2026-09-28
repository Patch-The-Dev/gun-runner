--!strict

export type RateLimiter = {
	allow: (
		self: RateLimiter,
		key: string | number,
		intervalSeconds: number,
		now: number?
	) -> boolean,
	clear: (self: RateLimiter, key: string | number) -> (),
	clearAll: (self: RateLimiter) -> (),
}

local RateLimiter = {}
RateLimiter.__index = RateLimiter

function RateLimiter.new(): RateLimiter
	return setmetatable({
		_lastSeen = {} :: { [string | number]: number },
	}, RateLimiter) :: RateLimiter
end

function RateLimiter:allow(key: string | number, intervalSeconds: number, now: number?): boolean
	assert(intervalSeconds >= 0, "intervalSeconds must be non-negative")
	local timestamp = now or os.clock()
	local previous = self._lastSeen[key]
	if previous ~= nil and timestamp - previous < intervalSeconds then
		return false
	end
	self._lastSeen[key] = timestamp
	return true
end

function RateLimiter:clear(key: string | number)
	self._lastSeen[key] = nil
end

function RateLimiter:clearAll()
	table.clear(self._lastSeen)
end

return RateLimiter
