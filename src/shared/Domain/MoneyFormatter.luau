--!strict

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

local MoneyFormatter = {}

function MoneyFormatter.format(value: number): string
	local sign = if value < 0 then "-" else ""
	local magnitude = math.abs(value)
	if magnitude < 1_000 then
		return sign .. tostring(math.floor(magnitude + 0.5))
	end

	local group = math.min(math.floor(math.log10(magnitude) / 3), #SUFFIXES - 1)
	local scaled = magnitude / (1_000 ^ group)
	local text = if scaled >= 100
		then string.format("%.0f", scaled)
		elseif scaled >= 10 then string.format("%.1f", scaled)
		else string.format("%.2f", scaled)

	return sign .. text:gsub("%.?0+$", "") .. SUFFIXES[group + 1]
end

return table.freeze(MoneyFormatter)
