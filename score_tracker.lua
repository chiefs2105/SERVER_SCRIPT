-- score_tracker.lua

-- Require the score_utils file
local score_utils = require('score_utils')  -- Make sure the path is correct

local requiredSpeed = 0
 
local totalScore = 0  -- Total score of the player
local comboMeter = 1  -- Combos for scoring
local comboColor = 0  -- Color for the combo display
local highestScore = 0  -- Highest score achieved
local wheelsWarningTimeout = 0  -- Timer for wheel warning
local carsState = {}  -- State of other cars
local lastComboGainSize = 1 -- Base size of the text
local lastComboGainAlpha = 1 -- Opacity of the text
local lastComboGainAnimationDuration = 0.5 -- Duration of the animation in seconds
local lastComboGainAnimationTime = 0 -- Timer for animation
local uiVisible = true

-- Define your sprite array and animation variables
local animationTime = 0  -- Time elapsed for animation
local currentFrame = 1  -- Current frame index in the sprite animation
local frameDuration = .06  -- Duration of each frame in seconds (adjust as needed)
 
-- Timer variables for transparency change
local transparencyTimer = 0
local transparencyDuration = 10  -- Time for which the transparency is 0 (in seconds)
local isTransparencyZero = false  -- Flag to track if transparency is 0
local spriteArray = {}
-- Flag to track if this is the first load of the UI
local isFirstLoad = true
 
function loadSprites()
    for i = 0, 299 do  -- Assuming you have 299 images
        local spriteURL = string.format("https://raw.githubusercontent.com/chiefs2105/New-UI/main/Ui_%05d.png", i)
        table.insert(spriteArray, spriteURL)
    end
end
 
-- Playtime Variables
local totalPlaytime = 0 -- Total playtime in seconds
local playtimeStorage = ac.storage('totalPlaytime', totalPlaytime) -- Storage for playtime
totalPlaytime = playtimeStorage:get() -- Load total playtime from storage
 
-- Score storage
local stored = {}
stored.new_playerscore1 = ac.storage('newplayerscore1', highestScore) -- Storage for player score
highestScore = stored.new_playerscore1:get() -- Load highest score from storage
 
-- Connection count storage
local connectionStorage = ac.storage('connectionCount', 0)
local connectionCount = connectionStorage:get()  -- Load connection count from storage
 
-- Initialize runtime variable
local runtime = 0  -- Runtime for current play session
local speedMultiplier = 1 -- Speed multiplier based on player's speed
local proximityMultiplier = 1 -- Proximity multiplier based on distances to other cars
 
-- Variable to track if the player has connected
local hasConnected = false
 
-- Variable to track the last combo gain from overtakes
local lastComboGain = 0
 
-- Define a maximum gain rate for the combo meter
local maxComboGainPerUpdate = 2 -- Adjust this value to control the gain rate
 
-- Function to format playtime in HH:MM:SS
local function formatPlaytime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end
 
-- Function to determine player's tier based on score
local function getTier(score)
    if score >= 20000000 then return "Heartbroken"
    elseif score >= 15000000 then return "Master"
    elseif score >= 10000000 then return "Professional"
    elseif score >= 7500000 then return "Prodigy"
    elseif score >= 5000000 then return "Expert"
    elseif score >= 3000000 then return "Skillful"
    elseif score >= 2000000 then return "Experienced"
    elseif score >= 1000000 then return "Competent"
    elseif score >= 500000 then return "Apprentice"
    elseif score >= 250000 then return "Accustomed"
    elseif score >= 100000 then return "Novice"
    elseif score >= 50000 then return "Amateur"
    elseif score >= 10000 then return "Trainee"
    elseif score >= 1000 then return "Beginner"
    else return "Noob"
    end
end
 
-- Function to get the name of the current map/track
local function getCurrentMap()
    local trackName = ac.getTrackName()
    if trackName then
        return trackName
    else
        return "Unknown Track"
    end
end
 
-- Example usage: add a debug message for the current map/track
local function debugCurrentMap()
    local currentMap = getCurrentMap()  -- Get the current map/track name
    local debugMessage = "Debug: Current Map is " .. currentMap
end
 
-- Initialize season variable
local season = "Season 1"  -- You can change this manually when a new season starts
 
 
-- New variables for linear interpolation
local targetPB = highestScore
local currentPB = highestScore
local targetScore = totalScore
local currentScore = totalScore
 
 
local lerpSpeed = 4  -- Adjust the speed of the transition (higher value = faster)
 
function script.update(dt)
    -- Update targetPB based on the highest score (if the player's score surpasses the previous PB)
    if totalScore > targetPB then
        targetPB = totalScore
    end
 
    -- Linear interpolation to smoothly update the currentPB
    currentPB = currentPB + (targetPB - currentPB) * lerpSpeed * dt
 
 
	-- Initialize the sprite loading
	loadSprites()
    local player = ac.getCarState(1)  -- Get state of player car
    local playerCount = ac.getSimState().carsCount
    debugCurrentMap()
 
    -- Check if player is driving the YZF-R1 and don't count points if they are
    local playerCarName = ac.getCarName(0)
    if playerCarName == "Yamaha YZF-R1" then
        uiVisible = false
        return  -- Exit the update function early, no points will be counted for this player
    end
 
    -- Loop through all cars in the simulation
    for i = 0, playerCount do
        -- Skip the player car (index 1)
        if i == 0 then
            -- Handle player car logic separately, if neededF-- near
            -- For example, output the player's car name:
            local playerCarName = ac.getCarName(0)
        else
            -- Skip updating proximity multiplier for cars in this range (21 to 71)
            if i >= 21 and i <= 71 then
                goto continue
            end
 
            -- Handle other cars
            local otherCar = ac.getCarState(i)
            -- Add any necessary logic for other cars here
        end
 
        -- Continue to next iteration if car is within range 21 to 71
        ::continue:: -- This should be outside of the if block to be valid Lua syntax
    end
 
    -- UI visibility toggle
    if ac.isKeyPressed(9) then
         uiVisible = not uiVisible
    end
 
    -- Update total playtime and runtime
    totalPlaytime = totalPlaytime + dt
    playtimeStorage:set(totalPlaytime) -- Persist playtime in storage
    if totalScore > 0 then
        runtime = runtime + dt -- Increment runtime only if the player has points
    end
 
    -- Reset score and runtime if speed is below 10 km/h
    if player.speedKmh < 10 then
        totalScore = 0
        comboMeter = 1 -- Reset combo meter if needed
        runtime = 0 -- Reset runtime
    end
 
    -- Calculate combo fading and speed multiplier
    local comboFadingRate = 1.35 * math.lerp(1, 0.1, math.lerpInvSat(player.speedKmh, 65, 200)) + player.wheelsOutside
    comboMeter = math.max(1, comboMeter - dt * comboFadingRate)
    speedMultiplier = math.min(player.speedKmh / 60, 5)  -- Max multiplier at 200 km/h
 
    -- Calculate proximity multiplier based on distances between player and others
proximityMultiplier = 1 -- Reset proximity multiplier each update
local sim = ac.getSimState()
local playerCount = sim.carsCount

-- Calculate proximity multiplier based on distances between player and others
proximityMultiplier = 1 -- Reset proximity multiplier each update
local sim = ac.getSimState()
local playerCount = sim.carsCount

-- Calculate proximity multiplier based on distances between player and others
proximityMultiplier = 1 -- Reset proximity multiplier each update
local sim = ac.getSimState()
local playerCount = sim.carsCount

for i = 1, playerCount do
    if i ~= 1 then -- Skip self
        if i >= 21 and i <= 71 then
            -- Skip updating the proximity multiplier for cars in this range
            goto continue
        end

        local otherCar = ac.getCarState(i)
        local distance = (otherCar.pos - player.pos):length()

        -- Calculate proximity multiplier based on distance
        if distance >= 1 and distance <= 20 then
            -- Linear scaling: when distance = 1, multiplier = 5; when distance = 15, multiplier = 1
            proximityMultiplier = 4.7 - (distance - 1) * (4 / 19)
        end

    end
    ::continue::
end
 
    -- Ensure proximity multiplier does not go below 1
    proximityMultiplier = math.max(1, math.min(proximityMultiplier, 3.0))
 
    -- Initialize car state storage
    while playerCount > #carsState do
        carsState[#carsState + 1] = {}
    end
 
    -- Handle wheel warning
    if wheelsWarningTimeout > 0 then
        wheelsWarningTimeout = wheelsWarningTimeout - dt
    elseif player.wheelsOutside > 0 then
        addMessage("Car is outside", -1)  -- Notify about wheels outside
        wheelsWarningTimeout = 60
    end
 
    -- Update states for each car
    for i = 1, playerCount do
        local car = ac.getCarState(i)
        local state = carsState[i]
 
        if car.pos:closerToThan(player.pos, 10) then
            local drivingAlong = math.dot(car.look, player.look) > 0.2
            if not drivingAlong then
                state.drivingAlong = false
                -- Increase combo meter if near miss
                if not state.nearMiss and car.pos:closerToThan(player.pos, 3) then
                    state.nearMiss = true
                    comboMeter = comboMeter + math.min(maxComboGainPerUpdate, 1) * speedMultiplier + (proximityMultiplier / 3)
                end
            end
 
            if car.collidedWith == 0 then
                state.collided = true
                -- Check for new high score
                if totalScore > highestScore then
                    highestScore = math.floor(totalScore)
                    stored.new_playerscore1:set(highestScore)  -- Store new highest score
                    local runtimeStr = formatPlaytime(runtime) -- Format runtime
                    local playerCarName = ac.getCarName(0)  -- Get the name of the car the player is driving
                    local currentMap = getCurrentMap()  -- Get the current map/track name
 
                    -- Send the highscore message including the player's car name, map, and season
                    ac.sendChatMessage("set a NEW highscore of " 
                        .. string.format("%0.0f", totalScore):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "") 
                        .. " pts in " .. runtimeStr 
                        .. " using the " .. playerCarName 
                        .. " on " .. currentMap)
                end
                totalScore = 0  -- Reset total score
                comboMeter = 1  -- Reset combo meter
                runtime = 0  -- Reset runtime when score resets
            end
 
            -- Overtaking logic
            if not state.overtaken and not state.collided and state.drivingAlong then
                local posDir = (car.pos - player.pos):normalize()
                local posDot = math.dot(posDir, car.look)
                state.maxPosDot = math.max(state.maxPosDot, posDot)
                if posDot < -0.5 and state.maxPosDot > 0.5 then
                    lastComboGain = math.min(maxComboGainPerUpdate, 1) * speedMultiplier + (proximityMultiplier / 3)
                    comboMeter = comboMeter + lastComboGain
                    totalScore = totalScore + math.ceil(comboMeter * 3)  -- Update totalScore based on comboMeter
                    comboColor = comboColor + 10
                    state.overtaken = true
                    -- Start the animation for lastComboGain
                    lastComboGainAnimationTime = lastComboGainAnimationDuration
                    lastComboGainSize = 1.5 -- Increase size for animation effect
                    lastComboGainAlpha = 1 -- Reset alpha for visibility
                end
            end
        else
            -- Reset state if not close to player
            state.maxPosDot = -1
            state.overtaken = false
            state.collided = false
            state.drivingAlong = true
            state.nearMiss = false
        end
    end
end
 
-- Function to store and display messages
local messages = {}
 
function addMessage(text, mood)
    for i = math.min(#messages + 1, 4), 2, -1 do
        messages[i] = messages[i - 1]  -- Shift messages up
        messages[i].targetPos = i
    end
    messages[1] = {text = text, age = 0, targetPos = 1, mood = mood}  -- Add new message
end


-- Helper function to format runtime as HH:MM:SS
function formatTime(seconds)
    local hours = math.floor(seconds / 3600)  -- Get the number of hours
    local minutes = math.floor((seconds % 3600) / 60)  -- Get the number of minutes
    local remainingSeconds = math.floor(seconds % 60)  -- Get the remaining seconds

    -- Format and return the time string in HH:MM:SS format
    return string.format("%02d:%02d:%02d", hours, minutes, remainingSeconds)
end

function script.drawUI()
    if not uiVisible then
        return -- Don't draw UI if uiVisible is false
    end
        local uiState = ac.getUiState()
    score_utils.update_messages(messages)  -- Use the utility function to update messages

    -- Load sprites once
    loadSprites()

    -- Update animation state
    animationTime = animationTime + uiState.dt  -- Increase animation time by delta time
    if animationTime >= frameDuration then
        animationTime = animationTime - frameDuration  -- Reset animation time
        currentFrame = currentFrame + 1  -- Move to the next frame
        if currentFrame > #spriteArray then
            currentFrame = 1  -- Loop back to the first frame if at the end
        end
    end

    -- Handle transparency timer
    if isFirstLoad then
        transparencyTimer = transparencyTimer + uiState.dt
        if transparencyTimer >= transparencyDuration then
            isTransparencyZero = false
            isFirstLoad = false
        else
            isTransparencyZero = true
        end
    else
        isTransparencyZero = false
    end

    -- Set transparency
    local transparency = isTransparencyZero and 0 or 1

    -- Draw the UI window for text (e.g. PB, Tier, Score)
    ui.beginTransparentWindow("scoreDisplay", vec2(100, 100), vec2(500, 500))
    ui.beginOutline()

    ui.pushStyleVar(ui.StyleVar.Alpha, transparency)

    -- Show PB (Personal Best) with Big font
    ui.pushFont(ui.Font.Title)  -- Use a large font for PB
    local tier = getTier(highestScore)
    ui.offsetCursorX(53)
    ui.offsetCursorY(-1)
    ui.text(string.format("%d", highestScore))  -- Show High Score on one line
    ui.popFont()  -- Reset to the default font

    -- Show Tier with Small font
    ui.pushFont(ui.Font.large)
    ui.offsetCursorY(12)
    ui.offsetCursorX(-9)
    ui.text(string.format("(%s)", tier))  -- Show Tier
    ui.popFont()

    ui.offsetCursorY(15)  -- Adjust spacing for the multipliers below
    ui.offsetCursorX(106)  -- Adjust spacing for the multipliers

    -- Show Speed and Proximity with Big font
    ui.pushFont(ui.Font.Title)
    ui.text(string.format("%.2f", speedMultiplier))
    ui.sameLine(0, 38)
    ui.text(string.format("%.2f", proximityMultiplier))
    ui.sameLine(0, 38)
    ui.popFont()

    -- Display Combo with Small font
    ui.pushFont(ui.Font.Title)
    ui.text(string.format("%d", comboMeter))  -- This will display values like 1.0, 2.3, etc.
    ui.offsetCursorY(15)  -- Adjust spacing for the next line
    ui.popFont()

    -- Set positioning manually for lastComboGain and below
    ui.offsetCursorY(-40)  -- Set Y position for lastComboGain
    ui.offsetCursorX(329)  -- Set X position for lastComboGain
    ui.pushFont(ui.Font.Title)  -- Use Big font for LastCombo
    ui.text(string.format("%d", lastComboGain))  -- Show last combo gain
    ui.popFont()  -- Reset to default font

    -- Set the position for the current score at a fixed (x, y) location

    local centerX, centerY = 200, 16  -- Set the desired center position for the score
    if totalScore >= 1 then
        local scoreText = string.format("%d", totalScore)
        local estimatedCharWidth = 8  -- Estimated width per character (adjust as needed)
        local textWidth = #scoreText * estimatedCharWidth  -- Calculate the width of the score text
        ui.offsetCursorX(centerX - textWidth / 2)  -- Offset by half the width of the score text
    end
    ui.offsetCursorY(centerY)
    ui.pushFont(ui.Font.Title)  -- Use Big font for CurrentScore
    ui.text(scoreText)
    ui.popFont()

    -- Set the position for the runtime
    ui.offsetCursorY(-29)  -- Move down by 20 units for the runtime
    ui.offsetCursorX(340)  -- Set X position for the runtime
    ui.pushFont(ui.Font.Title)  -- Use Big font for Runtime
    ui.text(string.format("%s", formatTime(runtime)))  -- Display the formatted runtime
    ui.popFont()  -- Reset to default font

    ui.popStyleVar()
    ui.endOutline()
    ui.endTransparentWindow()

    -- Now, create a new transparent window for the sprites (below the text)
    ui.beginTransparentWindow("spriteDisplay", vec2(-20, 0), vec2(600, 350))
    ui.beginOutline()

    -- Draw animated sprite image (underneath the text)
    local spriteURL = spriteArray[currentFrame]
    if spriteURL then
        ui.image(spriteURL, vec2(600, 350), transparency)
    end

    ui.endOutline()
    ui.endTransparentWindow()
end