-----------------------------------------------------------------------------------------
--
-- givehighdistinction.lua
--
-----------------------------------------------------------------------------------------

local composer = require( "composer" )
local scene = composer.newScene()
local widget = require "widget"
local physics = require( "physics")
require("modules.myFunctions")

--------------------------------------------
-- forward declarations and other locals
local trajectoryPoints
local dragPoints
local renderPathNew
local WIDTH = display.actualContentWidth
local HEIGHT = display.actualContentHeight
local x = display.contentCenterX
local y = display.contentCenterY

-- Editable Values
local FONT = native.systemFont		-- Font used throughout the project
local TIMESTEP = 0.1      			-- The lower this number, the more accurate the trajectory path, but the higher resource cost on the device.
local ANGLECHANGEVALUE = 1
local VELOCITYCHANGEVALUE = 20
local RANGECHANGEVALUE = 250

-- Default values { GLOBALS } -- these will update whenever a button is pressed
local velocity = 684
local angle = 25.65
local rad = math.rad(angle)
local gravity = 9.81
local range = math.round(velocity^2 * (2* math.sin(rad) * math.cos(rad)) / gravity) --> starting range
local dragRange = 0
local converseDragRange = 0
local ft, ft2, ft3, ft4

local drag = 0
local noDrag = 0 -- These tell the buttons to build on first press
local grid = 0



function scene:create( event )
	local sceneGroup = self.view
	----------------------
	--> START GRAPHICS <--
	local cloud = display.newImageRect( "clouds-hq.png", WIDTH, 100)
	cloud.anchorX = display.screenOriginX
	cloud.x, cloud.y = 0, display.contentCenterY + 20
	local cloud2 = display.newImageRect( "clouds-hq.png", WIDTH, 100)
	cloud2.anchorX = display.screenOriginX
	cloud2.x, cloud2.y = WIDTH, display.contentCenterY + 20
	-- Background imagery
	local background = display.newImageRect( "background-noclouds.png", WIDTH, HEIGHT )
	background.anchorX = 0
	background.anchorY = 0
	background.x = 0 + display.screenOriginX
	background.y = 0 + display.screenOriginY
	-- Insert the tanky boi
	local tank = display.newImageRect( "tank.png", 40, 20)
	tank.x, tank.y = -50, 255
	transition.moveTo(tank, { x=1, y=255, time=2000 })
	local buildGrid = display.newGroup();
	
	-- Insert text fields
	local angleText = display.newText("Angle", 20, 50, FONT, 14)
	angleText.x = display.contentCenterX - 150
	angleText.y = display.contentHeight - 35
	local velocityText = display.newText("Velocity", 20, 50, FONT, 14)
	velocityText.x = display.contentCenterX
	velocityText.y = display.contentHeight - 35
	local rangeText = display.newText("Range", 20, 50, FONT, 14)
	rangeText.x = display.contentCenterX + 150
	rangeText.y = display.contentHeight - 35

	-- Info Panel Stuff
	local infoPanel = display.newRect(x+231,y-100,80,100);
	infoPanel:setFillColor(0,0,0,0.6);
	infoPanel.strokeWidth = 1
	local header = display.newText("Ranges", 20, 50, FONT, 12);
	header.x = x+231
	header.y = y - 140
	local infoPanel2 = display.newRect(x+231,y+5,80,100);
	infoPanel2:setFillColor(0,0,0,0.6);
	infoPanel2.strokeWidth = 1
	local header2 = display.newText("Flight Time", 20, 50, FONT, 12);
	header2.x = x+231
	header2.y = y - 35
	local rangeTextBlue = display.newText("", 20, 50, FONT, 10)
	rangeTextBlue:setFillColor(0.2,0.9,1)
	rangeTextBlue.x = x+231
	rangeTextBlue.y = y -120
	local rangeTextGreen = display.newText("", 20, 50, FONT, 10)
	rangeTextGreen:setFillColor(0,0.8,0)
	rangeTextGreen.x = x+231
	rangeTextGreen.y = y -105
	local dragRangeTextOrange = display.newText("", 20, 50, FONT, 10)
	dragRangeTextOrange:setFillColor(1,0.5,0);
	dragRangeTextOrange.x = x+231
	dragRangeTextOrange.y = y - 90
	local dragRangeTextRed = display.newText("", 20, 50, FONT, 10)
	dragRangeTextRed:setFillColor(0.8,0,0);
	dragRangeTextRed.x = x+231
	dragRangeTextRed.y = y - 75
	
	local flightTimeTextBlue = display.newText("", 20, 50, FONT, 10)
	flightTimeTextBlue:setFillColor(0.2,0.9,1)
	flightTimeTextBlue.x = x+231
	flightTimeTextBlue.y = y - 15
	local flightTimeTextGreen = display.newText("", 20, 50, FONT, 10)
	flightTimeTextGreen:setFillColor(0,0.8,0)
	flightTimeTextGreen.x = x+231
	flightTimeTextGreen.y = y
	local flightTimeTextOrange = display.newText("", 20, 50, FONT, 10)
	flightTimeTextOrange:setFillColor(1,0.5,0)
	flightTimeTextOrange.x = x+231
	flightTimeTextOrange.y = y + 15
	local flightTimeTextRed = display.newText("", 20, 50, FONT, 10)
	flightTimeTextRed:setFillColor(0.8,0,0)
	flightTimeTextRed.x = x+231
	flightTimeTextRed.y = y + 30
	
	-- Checkbox Texts
	local dragText = display.newText("Drag", 20, 50, FONT, 14)
	dragText.x = display.contentCenterX + 140
	dragText.y = display.contentCenterY - 148
	local noDragText = display.newText("No Drag", 20, 50, FONT, 14)
	noDragText.x = display.contentCenterX
	noDragText.y = display.contentCenterY - 148
	local gridText = display.newText("Grid", 20, 50, FONT, 14)
	gridText.x = display.contentCenterX - 160
	gridText.y = display.contentCenterY - 148

	-- insert a grid to graph trajectory points
	local function renderGrid()
		buildGrid:removeSelf();
		buildGrid = display.newGroup();
		buildGrid.x = 0
		buildGrid.y = 255
		local gridXLength = display.contentWidth/10 				-- 50,000/5,000 is 10, we need 10 gridlines on the x axis
		local gridYLength = ((display.contentHeight - 100) * -1)/5 	-- Multiplied by -1 to flip axis from top to bottom left
		for i = 0, 10, 1 do
			local XLine = display.newLine(buildGrid,i*gridXLength,0,i*gridXLength, gridYLength*5);
			XLine:setStrokeColor(0.6,0.6,0.6)
			local textMarker = display.newText({text = i*5000, x = i*gridXLength, y = 5, FONT, fontSize = 8});
			textMarker:setFillColor(0,0,0)
			buildGrid:insert(textMarker);
		end
		for i = 0, 5, 1 do
			local YLine = display.newLine(buildGrid,0,i*gridYLength,gridXLength*10,i*gridYLength);
			YLine:setStrokeColor(0.6,0.6,0.6)
			local textMarker = display.newText({text = i*5000, x = -10, y = i*gridYLength, FONT, fontSize = 8});
			textMarker:setFillColor(0,0,0)
			buildGrid:insert(textMarker);
		end
	end

	-- Checkbox Image
	local options = {
		width = 30.5,
		height = 32,
		numFrames = 2,
		sheetContentWidth = 62,
		sheetContentHeight = 32
	}
	local checkboxSheet = graphics.newImageSheet( "Checkbox.png", options)

	local function renderTextFields()
		angleTextBox.text = string.format("%.2f", angle)
		rangeTextBox.text = string.format("%.2f", range)
		velocityTextBox.text = string.format("%.2f", velocity)
		if noDrag == 1 then 
			local ft = calcFlightTime(angle, gravity, velocity)
			local ft2 = calcFlightTime(90-angle, gravity, velocity)
			rangeTextBlue.text = string.format("%.2f", range)
			rangeTextGreen.text = string.format("%.2f", range)
			flightTimeTextBlue.text = string.format("%.2f", ft) .. "s"
			flightTimeTextGreen.text = string.format("%.2f", ft2) .. "s"
		else 
			rangeTextBlue.text = ""
			rangeTextGreen.text = ""
			flightTimeTextBlue.text = ""
			flightTimeTextGreen.text = ""
		end		
		if drag == 1 then
			dragRangeTextOrange.text = string.format("%.2f", dragRange)
			dragRangeTextRed.text = string.format("%.2f", converseDragRange)
			flightTimeTextOrange.text = string.format("%.2f", ft3) .. "s"
			flightTimeTextRed.text = string.format("%.2f", ft4) .. "s"
		else
			dragRangeTextOrange.text = ""
			dragRangeTextRed.text = ""
			flightTimeTextOrange.text = ""
			flightTimeTextRed.text = ""
		end
	end

	-------------------------------------
	--> START TRAJECTORY CALCULATIONS <--
	local circle1, circle2, circle3, circle4
	local predictedPath1 = display.newGroup();
	local predictedPath2 = display.newGroup();
	local predictedPath3 = display.newGroup();
	local predictedPath4 = display.newGroup();
	predictedPath1.y = 255
	predictedPath2.y = 255
	predictedPath3.y = 255
	predictedPath4.y = 255

	-- Render the trajectory arrays on-screen
	local function renderPathNew(trajectoryPoints, colour)
		colour = colour or 1
		
		if colour == 1 then
			predictedPath1:removeSelf()
			predictedPath1 = display.newGroup()
			sceneGroup:insert(predictedPath1)
			predictedPath1.y = 255
		end
		if colour == 2 then
			predictedPath2:removeSelf();
			predictedPath2 = display.newGroup();
			sceneGroup:insert(predictedPath2)
			predictedPath2.y = 255
		end
		if colour == 3 then
			predictedPath3:removeSelf();
			predictedPath3 = display.newGroup();
			sceneGroup:insert(predictedPath3)
			predictedPath3.y = 255
		end
		if colour == 4 then
			predictedPath4:removeSelf();
			predictedPath4 = display.newGroup();
			sceneGroup:insert(predictedPath4)
			predictedPath4.y = 255
		end
				
		for i,points in pairs(trajectoryPoints) do
			if 	colour == 1 then
				circle1 = display.newCircle(predictedPath1,((points.x/50000) * display.contentWidth), ((points.y/25000) * (display.actualContentHeight-100) * -1), 1.3);
				circle1:setFillColor(0.2,0.9,1)		--> first line, line of angle with no drag
			elseif colour == 2 then
				circle2 = display.newCircle(predictedPath2,((points.x/50000) * display.contentWidth), ((points.y/25000) * (display.actualContentHeight-100) * -1), 1.3);
				circle2:setFillColor(0,0.8,0) 	--> second line, converse angle with no drag
			elseif colour == 3 then
				circle3 = display.newCircle(predictedPath3,((points.x/50000) * display.contentWidth), ((points.y/25000) * (display.actualContentHeight-100) * -1), 1.3);
				circle3:setFillColor(1,0.5,0) 	--> third line, angle with drag
			else
				circle4 = display.newCircle(predictedPath4,((points.x/50000) * display.contentWidth), ((points.y/25000) * (display.actualContentHeight-100) * -1), 1.3);
				circle4:setFillColor(0.8,0,0) 	--> fourth line, converse angle with drag
			end
		end
	end

	-- Calculate trajectory with Drag based off a 155m shell
	local function dragPoints(velocity, angle, color)
		local rad = math.rad(angle)
		local density = 1.2041 --in kg/m3
		local dragValue = 0.325 -- adjusted from 0.295 as these results round closer to actual flight data provided in brief
		local points = {}
		local posx, posy, time = 0, 0, 0
		local mass = 43.091 --mass of shell in kg
		local dragX, dragY, accelX, accelY
		local veloX = velocity * math.cos(rad)
		local veloY = velocity * math.sin(rad)
		while posy >= 0 do
			dragX = density/2 * veloX^2 * dragValue * (math.pi * ((0.155 / 2))^2) *-1
		--                                             ^CSA of 155mm shell         drag pushes in negative direction
			accelX = dragX/mass
				local xform = veloX * TIMESTEP + accelX /2 * TIMESTEP^2
			dragY = density/2 * veloY^2 * dragValue * (math.pi * ((0.155 / 2))^2)
			if veloY > 0 then
				dragY = dragY * -1 -- if projectile is going down then drag is upwards
			end
			dragY = dragY - mass * gravity -- Calculate the net force
			accelY = dragY / mass
				local yform = veloY * TIMESTEP + accelY/2 * TIMESTEP^2
				posx = posx + xform
				posy = posy + yform
			table.insert(points, {x = posx, y = posy});
			veloX = veloX + accelX * TIMESTEP
			veloY = veloY + accelY * TIMESTEP
			time = time + TIMESTEP
			if time > 200 then
				break
			end
		end
		if color == 3 then 
			ft3 = time
			dragRange = points[#points].x - points[1].x -- update text field for drag range
		else if color == 4 then 
			ft4 = time 
			converseDragRange = points[#points].x - points[1].x -- update text field for converse drag range
		end
		end
		renderPathNew(points, color)
		return points
	end

	-- Builds an array with basic calculated trajectory points
	local function trajectoryPoints(velocity, angle, color)
		local rad = math.rad(angle)
		local points = {}
		local posx, posy, time = 0, 0, 0
		while posy >= 0 do
			posx = velocity * time * math.cos(rad)
			posy = velocity * time * math.sin(rad) - (0.5 * gravity) * time^2
			table.insert(points,{x = posx, y = posy});
			time = time + TIMESTEP
		end
		if drag == 1 and noDrag == 1 then 
			renderPathNew(points, color)
			dragPoints(velocity, angle, 3)
			dragPoints(velocity, 90-angle, 4)
		else if noDrag == 1 then
			renderPathNew(points, color)
		else if drag == 1 then
			dragPoints(velocity, angle, 3)
			dragPoints(velocity, 90-angle, 4)
			renderTextFields()
		end
	end
	end
		return points
	end
	--> END TRAJECTORY CALCULATIONS <--
	-----------------------------------


	---------------------------------------------
	--> TEXT BOXES FOR MANUALLY ADDING VALUES <--
	local function angleTextBoxListener( event )
		if event.phase == "submitted" then
			local num = tonumber(angleTextBox.text)
			if num then 								-- Make sure the value is not too big or small
				if num >= 89 then
					num = 89
				end
				if num <= 1 then
					num = 1
			end
			angle = num									-- update all the other values
			range = updateRange(angle, gravity, velocity)
			trajectoryPoints(velocity, angle)
			trajectoryPoints(velocity, 90-angle, 2)
			renderTextFields()
		end
		end
	end

	local x = display.contentCenterX
	local y = display.contentHeight

	angleTextBox = native.newTextField( x - 152, y -15, 40, 15 )
	angleTextBox.font = native.newFont( FONT, 10 )
	angleTextBox.text = tostring(angle)
	angleTextBox.isEditable = true
	angleTextBox.inputType = "decimal"
	angleTextBox:addEventListener( "userInput", angleTextBoxListener )

	local function rangeTextBoxListener( event )
		if event.phase == "submitted" then
			local num = tonumber(rangeTextBox.text)
		if num then
			range = num
			angle = updateAngle(gravity, range, velocity)
			trajectoryPoints(velocity, angle)
			trajectoryPoints(velocity, 90-angle, 2)
			renderTextFields()
		end
		end
	end

	rangeTextBox = native.newTextField( x+157, y-15, 55, 15 )
	rangeTextBox.font = native.newFont( FONT, 10 )
	rangeTextBox.text = tostring(range)
	rangeTextBox.isEditable = true
	rangeTextBox.inputType = "decimal"
	rangeTextBox:addEventListener( "userInput", rangeTextBoxListener )

	local function velocityTextBoxListener( event )
		if event.phase == "submitted" then
			local num = tonumber(velocityTextBox.text)
			if num then
				if num <= 150 then
					num = 150
				end
				if num >= 1000 then
					num = 1000
			end
				velocity = num
				range = updateRange(angle, gravity, velocity)
				trajectoryPoints(velocity, angle)
				trajectoryPoints(velocity, 90-angle, 2)
				renderTextFields()
			end
		end
	end

	velocityTextBox = native.newTextField( x-2, y-15, 45, 15 )
	velocityTextBox.font = native.newFont( FONT, 10 )
	velocityTextBox.text = tostring(angle)
	velocityTextBox.isEditable = true
	velocityTextBox.inputType = "decimal"
	velocityTextBox:addEventListener( "userInput", velocityTextBoxListener )
	renderTextFields()
	--> END TEXT BOXES <--
	----------------------



	--------------------------------
	--> CLICK EVENTS FOR BUTTONS <--
	local function onAngleDecBtnRelease() -- Lower angle
		if angle <= 1 then
			return true
		else
			angle = angle - ANGLECHANGEVALUE
			range = updateRange(angle, gravity, velocity)
			trajectoryPoints(velocity, angle, 1)
			trajectoryPoints(velocity, 90-angle, 2)
			renderTextFields()
		end
		return true	-- Indicates successful touch
	end
	local function onAngleIncBtnRelease() -- Increase angle
		if angle >= 89 then
			return true
		else
			angle = angle + ANGLECHANGEVALUE
			range = updateRange(angle, gravity, velocity)
			trajectoryPoints(velocity, angle, 1)
			trajectoryPoints(velocity, 90-angle, 2)
			renderTextFields()
		end
		return true
	end


	local function onVelocityDecBtnRelease() -- Decrease velocity
		if velocity <= 150 then
			return true
		else
			velocity = velocity - VELOCITYCHANGEVALUE
			range = updateRange(angle, gravity, velocity)
			if tostring(angle) and tostring(range) == '-nan(ind)' then
				angle = 45
				range = updateRange(angle, gravity, velocity)
			end
			trajectoryPoints(velocity, angle, 1)
			trajectoryPoints(velocity, 90-angle, 2)
			renderTextFields()
		end
		return true
	end
	local function onVelocityIncBtnRelease() -- Increase velocity
		if velocity >= 1000 then
			return true
		else
			velocity = velocity + VELOCITYCHANGEVALUE
			range = updateRange(angle, gravity, velocity)
			if tostring(angle) and tostring(range) == '-nan(ind)' then
				angle = 45
				range = updateRange(angle, gravity, velocity)
			end
			trajectoryPoints(velocity, angle, 1)
			trajectoryPoints(velocity, 90-angle, 2)
			renderTextFields()
		end
		return true
	end


	local function onRangeDecBtnRelease() -- Decrease range
		if velocity <= 150 then
			return true
		else
			range = range - RANGECHANGEVALUE
			angle = updateAngle(gravity, range, velocity)
			trajectoryPoints(velocity, angle, 1)
			trajectoryPoints(velocity, 90-angle, 2)
			renderTextFields()
		end
		return true
	end
	local function onRangeIncBtnRelease() -- Increase range
		if velocity >= 1000 then
			return true
		else
			range = range + RANGECHANGEVALUE
			angle = updateAngle(gravity, range, velocity)

			if tostring(angle) == "-nan(ind)" then -- Recalculate angle
				velocity = velocity + 20
				angle = updateAngle(gravity, range, velocity)
			end
			trajectoryPoints(velocity, angle, 1)
			trajectoryPoints(velocity, 90-angle, 2)
			renderTextFields()
		end
		return true
	end

	----------------------
	--> ACTUAL BUTTONS <--
	-- button to remove from angle
	angleDecBtn = widget.newButton {
		labelColor = { default={ 0,0,0 }, over={ 1 } },
		defaultFile = "NegativeButton.png",
		overFile = "NegativeButtonOver.png",
		width = 18, height = 18,
		onRelease = onAngleDecBtnRelease	-- event listener function
	}
	angleDecBtn.x = x - 185
	angleDecBtn.y = display.contentHeight - 15
	-- button to add to angle
	angleIncBtn = widget.newButton {
		labelColor = { default={ 0,0,0 }, over={ 1 } },
		defaultFile = "PlusButton.png",
		overFile = "PlusButtonOver.png",
		width = 18, height = 18,
		onRelease = onAngleIncBtnRelease	-- event listener function
	}
	angleIncBtn.x = x - 185
	angleIncBtn.y = display.contentHeight - 35

	-- button to remove from velocity
	velocityDecBtn = widget.newButton {
		labelColor = { default={ 0,0,0 }, over={ 1 } },
		defaultFile = "NegativeButton.png",
		overFile = "NegativeButtonOver.png",
		width = 18, height = 18,
		onRelease = onVelocityDecBtnRelease	-- event listener function
	}
	velocityDecBtn.x = x - 40
	velocityDecBtn.y = display.contentHeight - 15
	-- button to add to velocity
	velocityIncBtn = widget.newButton {
		labelColor = { default={ 0,0,0 }, over={ 1 } },
		defaultFile = "PlusButton.png",
		overFile = "PlusButtonOver.png",
		width = 18, height = 18,
		onRelease = onVelocityIncBtnRelease	-- event listener function
	}
	velocityIncBtn.x = x - 40
	velocityIncBtn.y = display.contentHeight - 35

	-- button to decrement to range
	rangeDecBtn = widget.newButton {
		labelColor = { default={ 0,0,0 }, over={ 1 } },
		defaultFile = "NegativeButton.png",
		overFile = "NegativeButtonOver.png",
		width = 18, height = 18,
		onRelease = onRangeDecBtnRelease	-- event listener function
	}
	rangeDecBtn.x = display.contentCenterX + 110
	rangeDecBtn.y = display.contentHeight - 15

	-- button to add to range
	rangeIncBtn = widget.newButton {
		labelColor = { default={ 0,0,0 }, over={ 1 } },
		defaultFile = "PlusButton.png",
		overFile = "PlusButtonOver.png",
		width = 18, height = 18,
		onRelease = onRangeIncBtnRelease	-- event listener function
	}
	rangeIncBtn.x = display.contentCenterX + 110
	rangeIncBtn.y = display.contentHeight - 35


	-- TRAJECTORY ON / OFF EVENT
	local function TrajectoryOnOff( event )
		local switch = event.target
		if noDrag == 1 then
			noDrag = 0
			predictedPath1:removeSelf();
			predictedPath2:removeSelf();
		else
			noDrag = 1
			trajectoryPoints(velocity, angle, 1)
			trajectoryPoints(velocity, 90-angle, 2)
		end
		renderTextFields()
		return true
	end
	local checkbox = widget.newSwitch(
		{
			left = x - 50,
			top = display.contentCenterY - 160,
			style = "checkbox",
			id = "Checkbox1",
			width = 20,
			height = 20,
			onPress = TrajectoryOnOff,
			sheet = checkboxSheet,
			frameOff = 1,
			frameOn = 2
		}
	)

	-- GRID ON / OFF EVENT
	local function GridOnOff( event )
		local switch = event.target
		if grid == 1 then
			grid = 0
			buildGrid:removeSelf();
		else
			grid = 1
			renderGrid()
		end
		return true
	end
	local checkbox = widget.newSwitch(
		{	
			left = display.contentCenterX - 195,
			top = display.contentCenterY - 160,
			style = "checkbox",
			id = "Checkbox2",
			width = 20,
			height = 20,
			onPress = GridOnOff,
			sheet = checkboxSheet,
			frameOff = 1,
			frameOn = 2
		}
	)

	-- DRAG ON / OFF EVENT
	local function DragOnOff( event )
		local switch = event.target
		if drag == 1 then
			drag = 0
			predictedPath3:removeSelf();
			predictedPath4:removeSelf();		
		else
			drag = 1
			dragPoints(velocity, angle, 3)
			dragPoints(velocity, 90-angle, 4)
		end
		renderTextFields()
		return true
	end
	local checkbox = widget.newSwitch(
		{
			left = display.contentCenterX + 100,
			top = display.contentCenterY -160,
			style = "checkbox",
			id = "Checkbox3",
			width = 20,
			height = 20,
			onPress = DragOnOff,
			sheet = checkboxSheet,
			frameOff = 1,
			frameOn = 2
		}
	)

	-- Moving Clouds
	local tPrevious = system.getTimer()
	local function move(event)
		local tDelta = event.time - tPrevious
		tPrevious = event.time
		local xOffset = ( 0.01 * tDelta )
		cloud.x = cloud.x - xOffset
		cloud2.x = cloud2.x - xOffset
		if (cloud.x + cloud.contentWidth) < 0 then
			cloud:translate( WIDTH * 2, 0)
		end
		if (cloud2.x + cloud2.contentWidth) < 0 then
			cloud2:translate( WIDTH * 2, 0)
		end
	end
	Runtime:addEventListener( "enterFrame", move )


	-- all display objects must be inserted into group
	sceneGroup:insert( background ) -- very back of group
	sceneGroup:insert( cloud )
	sceneGroup:insert( cloud2 )
	sceneGroup:insert( predictedPath1 )
	sceneGroup:insert( predictedPath2 )
	sceneGroup:insert( predictedPath3 )
	sceneGroup:insert( predictedPath4 )
end


function scene:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if phase == "will" then
		-- Called when the scene is still off screen and is about to move on screen
	elseif phase == "did" then
		-- Called when the scene is now on screen
		--
		-- INSERT code here to make the scene come alive
		-- e.g. start timers, begin animation, play audio, etc.
		physics.start()------------------------------------dont need
	end
end

function scene:hide( event )
	local sceneGroup = self.view
	local phase = event.phase
	if event.phase == "will" then

	elseif phase == "did" then

	end
end

function scene:destroy( event )

	composer.removeScene(scene)
	local sceneGroup = self.view
end

---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-----------------------------------------------------------------------------------------

return scene