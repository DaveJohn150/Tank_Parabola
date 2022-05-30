module(..., package.seeall) -- need this to make things visible

gravity = 9.81
small = 1E-308
large = 1E308
INF = 1E309

-- cant test text field inputs?
-- Unit materials didn't cover this stuff well enough to provide adequate coverage on what we're suppose to do

--// ANGLE
function testAngle1()     --(gravity, range, velocity)
    assert_number(updateAngle(gravity, small, small))
end


--// RANGE
function testRange1()     --angle, gravity, velocity
    assert_number(updateRange(small, gravity, small))
end


--// FLIGHT TIME
function testFlight1()       --(angle, gravity, velocity)
    assert_number(calcFlightTime(small, gravity, small))
end

--// CALCULATE MAX HEIGHT
function testMaxH1()        --(angle, gravity, velocity)
    assert_number(calcMaxHeight(small, gravity, small))
end -- even if any of these return nil, it still passes?


--velocity      Angle       Time of flight      Range
-- 684          25.65       60.36               37 220
function testExpectedResult1()
    assert_equal(updateRange(25.65, gravity, 684), 37220)
end

function testExpectedResult2()
    assert_equal(updateAngle(gravity, 37220, 684), 25.65)
end

function testExpectedresult3()
    assert_equal(calcFlightTime(25.65, gravity, 684), 60.36)
end


--velocity      Angle       Time of flight      Range    w/ drag
-- 684          25.65       43.70               15 000
-- 684          11.72       23.60               10 000
-- 684          7.96        17.00               8 000
-- 684          3.99        9.10                5 000

-- Did these manually in report document.

