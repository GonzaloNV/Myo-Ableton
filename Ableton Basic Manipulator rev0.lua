scriptId = 'gonzalonv.abletonbasicmanipulatorrev0'
scriptTitle = "Ableton Basic Manipulator"
scriptDetailsUrl = ""

locked = true
appTitle = ""

centreYaw = 0
centrePitch = 0
centreRoll = 0

midiYaw = 0
midiPitch = 0
midiRoll = 0

PI = 3.1416
TWOPI = PI * 2
HALFPI = PI / 2

sumOfYaws0 = 0
sumOfPitches0 = 0
sumOfRolls0 = 0

pageNumber = 0

function onForegroundWindowChange(app, title)
    --myo.debug("onForegroundWindowChange: " .. app .. ", " .. title)
    local titleMatch = string.match(title, "Ableton") ~= nil or string.match(title, "Live") ~= nil or string.match(app, "com.ableton.live") ~= nil;
    --myo.debug("Ableton Live: "  .. tostring(titleMatch))
    
    if (titleMatch) then
        myo.setLockingPolicy("none")
    end
   
    return titleMatch
end

function onPoseEdge(pose, edge)
	--myo.debug("onPoseEdge: " .. pose .. ": " .. edge)
	
	pose = conditionallySwapWave(pose)
    
    local keyEdge = edge == "off" and "up" or "down"
    
	if (pose == "fist") then
		if (edge == "on") then
			centre()
		elseif (edge  == "off") then
			escape()
		end
		fistActive = edge == "on"
	end

	if (pose == "fingersSpread") and (edge == "on") then
		pageNumber = (pageNumber + 1) % 3
		--myo.debug("Número de página: " .. pageNumber)
		if (pageNumber == 0) then
			myo.vibrate("short")
		elseif (pageNumber == 1) then
			myo.vibrate("short")
			myo.vibrate("short")
			--myo.debug("acá")
		elseif (pageNumber == 2) then
			myo.vibrate("short")
			myo.vibrate("short")
			myo.vibrate("short")
		end
	end

	if (pose == "waveOut") then
		if (edge == "on") then
			myo.midi(6, "controlChange", 20, 127)
			myo.midi(6, "controlChange", 21, 127)
			myo.vibrate ("short")
		end
	end

	if (pose == "waveIn") then
		if (edge == "on") then
			myo.midi(6, "controlChange", 20, 127)
			myo.midi(6, "controlChange", 22, 127)
			myo.vibrate("short")
		end
	end

	if (pose == "doubleTap") then
		if (edge == "on") then
			myo.midi(6, "controlChange", 19, 127)
		end
	end
end

function onPeriodic()
	if fistActive then
		local currentYaw = myo.getYaw()
		local currentPitch = myo.getPitch()
		local currentRoll = myo.getRoll()
		local deltaYaw = calculateDeltaRadians(currentYaw, centreYaw)
		local deltaPitch = calculateDeltaRadians(currentPitch, centrePitch)
		local deltaRoll = calculateDeltaRadians(currentRoll, centreRoll)
		
		sumOfYaws = midiYaw + deltaYaw
		sumOfPitches = midiPitch + deltaPitch
		sumOfRolls = midiRoll + deltaRoll

		myo.midi(6, "controlChange", 41 + 3*pageNumber, mapToMidiMessage(sumOfYaws))
		--myo.debug("MIDI yaw " .. mapToMidiMessage(sumOfYaws))
		--myo.debug("MIDI message " .. 41 + pageNumber)
		myo.midi(6, "controlChange", 42 + 3*pageNumber, mapToMidiMessage(sumOfPitches))
		--myo.debug("MIDI pitch " .. mapToMidiMessage(sumOfPitches))
		myo.midi(6, "controlChange", 43 + 3*pageNumber, mapToMidiMessage(sumOfRolls))
		--myo.debug("MIDI pitch " .. mapToMidiMessage(sumOfPitches))
	end
end

function conditionallySwapWave(pose)
	if myo.getArm() == "left" then
        if pose == "waveIn" then
            pose = "waveOut"
        elseif pose == "waveOut" then
            pose = "waveIn"
        end
    end
    return pose
end

function centre()
	--myo.debug("Centred")
	centreYaw = myo.getYaw()
	centrePitch = myo.getPitch()
	centreRoll = myo.getRoll()
	--myo.vibrate("short")	
end

function escape()
	--myo.debug("Escape!")
	if sumOfYaws < 0 then
		midiYaw = 0
	elseif sumOfYaws > HALFPI then
		midiYaw = HALFPI
	else
		midiYaw = sumOfYaws
	end

	if sumOfPitches < 0 then
		midiPitch = 0
	elseif sumOfPitches > HALFPI then
		midiPitch = HALFPI
	else
		midiPitch = sumOfPitches
	end

	if sumOfRolls < 0 then
		midiRoll = 0
	elseif sumOfRolls > HALFPI then
		midiRoll = HALFPI
	else
		midiRoll = sumOfRolls
	end
	myo.vibrate("short")
end

function calculateDeltaRadians(currentAngle, centreAngle)
	local deltaAngle = currentAngle - centreAngle
	
	if (deltaAngle > PI) then
		deltaAngle = deltaAngle - TWOPI
	elseif(deltaAngle < -PI) then
		deltaAngle = deltaAngle + TWOPI
	end
	return deltaAngle
end

function mapToMidiMessage(angle)
	local message = round(((127*angle)/HALFPI), 0)
	if message > 127 then
		return 127
	elseif message < 0 then
		return 0
	else
		return message
	end
end

function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end	

function activeAppName()
	return "Live"
end


