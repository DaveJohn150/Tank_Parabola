--> UPDATE the RANGE if VELOCITY or ANGLE are edited
function updateRange(angle, gravity, velocity)
	local update = velocity^2 * (2* math.sin(math.rad(angle)) * math.cos(math.rad(angle))) / gravity
	return update
end

--> UPDATE the ANGLE if VELOCITY or RANGE are edited
function updateAngle(gravity, range, velocity)
	local update = math.deg(math.asin((gravity * range/velocity^2)) / 2)
	return update
end

--> CALCULATE total FLIGHT TIME of the bullet
function calcFlightTime(angle, gravity, velocity)
	rad = math.rad(angle)
	local flightTime = 2 * velocity * math.sin(rad) / gravity
	return flightTime
end

--> CALCULATE max HEIGHT of the parabola
function calcMaxHeight(angle, gravity, velocity)
	local maxHeight = (velocity^2 * math.sin(math.rad(angle))^2)/(2*gravity)
	return maxHeight
end