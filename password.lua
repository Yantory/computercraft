-- Touchscreen Password System
-- Place an Advanced Monitor next to the computer (top, bottom, or side)

local monitor = peripheral.find("monitor")  -- Find the monitor
if not monitor then
    error("Monitor not found! Place an Advanced Monitor next to the computer")
end

-- Settings
local CORRECT_PASSWORD = "1234"  -- Correct password
local MAX_ATTEMPTS = 3           -- Maximum attempts allowed

-- Variables
local enteredPassword = ""
local attempts = 0
local accessGranted = false
local blocked = false

-- Function to draw the interface
local function drawInterface()
    monitor.clear()
    monitor.setTextScale(2)
    
    -- Title
    monitor.setCursorPos(2, 1)
    monitor.write("ACCESS SYSTEM")
    
    -- Password input field
    monitor.setTextScale(1)
    monitor.setCursorPos(2, 4)
    monitor.write("Password: ")
    
    -- Display stars instead of characters
    local stars = ""
    for i = 1, #enteredPassword do
        stars = stars .. "*"
    end
    monitor.setCursorPos(2, 5)
    monitor.write(stars)
    
    -- Attempts message
    monitor.setCursorPos(2, 7)
    if blocked then
        monitor.setTextColor(colors.red)
        monitor.write("ACCESS BLOCKED!")
    elseif accessGranted then
        monitor.setTextColor(colors.green)
        monitor.write("ACCESS GRANTED!")
    else
        monitor.setTextColor(colors.orange)
        monitor.write("Attempts left: " .. (MAX_ATTEMPTS - attempts))
    end
    
    monitor.setTextColor(colors.white)
    
    -- Buttons
    drawButton(2, 9, 6, 3, "7", colors.lightGray)
    drawButton(10, 9, 6, 3, "8", colors.lightGray)
    drawButton(18, 9, 6, 3, "9", colors.lightGray)
    
    drawButton(2, 13, 6, 3, "4", colors.lightGray)
    drawButton(10, 13, 6, 3, "5", colors.lightGray)
    drawButton(18, 13, 6, 3, "6", colors.lightGray)
    
    drawButton(2, 17, 6, 3, "1", colors.lightGray)
    drawButton(10, 17, 6, 3, "2", colors.lightGray)
    drawButton(18, 17, 6, 3, "3", colors.lightGray)
    
    drawButton(2, 21, 6, 3, "0", colors.lightGray)
    drawButton(10, 21, 10, 3, "CLEAR", colors.red)
    drawButton(22, 21, 10, 3, "ENTER", colors.green)
end

-- Function to draw a button
function drawButton(x, y, w, h, text, color)
    -- Draw button background
    for yPos = y, y + h - 1 do
        for xPos = x, x + w - 1 do
            monitor.setCursorPos(xPos, yPos)
            monitor.setBackgroundColor(color)
            monitor.write(" ")
        end
    end
    
    -- Draw centered text
    local textX = x + math.floor((w - string.len(text)) / 2)
    local textY = y + math.floor(h / 2)
    monitor.setCursorPos(textX, textY)
    monitor.setBackgroundColor(color)
    monitor.setTextColor(colors.black)
    monitor.write(text)
    monitor.setTextColor(colors.white)
    monitor.setBackgroundColor(colors.black)
end

-- Function to check if a click is inside a button area
local function isClickInArea(clickX, clickY, x, y, w, h)
    return clickX >= x and clickX < (x + w) and clickY >= y and clickY < (y + h)
end

-- Function to add a digit
local function addDigit(digit)
    if blocked or accessGranted then return end
    if #enteredPassword < 8 then  -- Maximum password length
        enteredPassword = enteredPassword .. digit
    end
end

-- Function to check the password
local function checkPassword()
    if blocked or accessGranted then return end
    
    if enteredPassword == CORRECT_PASSWORD then
        accessGranted = true
        -- Uncomment the line below to open a door
        -- redstone.setOutput("back", true)
    else
        enteredPassword = ""
        attempts = attempts + 1
        if attempts >= MAX_ATTEMPTS then
            blocked = true
        end
    end
end

-- Function to reset the system
local function reset()
    enteredPassword = ""
    attempts = 0
    blocked = false
    accessGranted = false
    -- Uncomment the line below to close a door
    -- redstone.setOutput("back", false)
end

-- Main loop
monitor.clear()
drawInterface()

print("System started. Touch the monitor to enter the password.")
print("Hold Ctrl+T to exit")

while true do
    local event, side, x, y = os.pullEvent("monitor_touch")
    
    -- Check digit buttons (0-9)
    local digitButtons = {
        {2, 9, 6, 3, "7"}, {10, 9, 6, 3, "8"}, {18, 9, 6, 3, "9"},
        {2, 13, 6, 3, "4"}, {10, 13, 6, 3, "5"}, {18, 13, 6, 3, "6"},
        {2, 17, 6, 3, "1"}, {10, 17, 6, 3, "2"}, {18, 17, 6, 3, "3"},
        {2, 21, 6, 3, "0"}
    }
    
    for _, btn in ipairs(digitButtons) do
        if isClickInArea(x, y, btn[1], btn[2], btn[3], btn[4]) then
            addDigit(btn[5])
            drawInterface()
        end
    end
    
    -- CLEAR button
    if isClickInArea(x, y, 10, 21, 10, 3) then
        enteredPassword = ""
        drawInterface()
    end
    
    -- ENTER button
    if isClickInArea(x, y, 22, 21, 10, 3) then
        checkPassword()
        drawInterface()
    end
    
    -- Auto-reset 5 seconds after successful entry (optional)
    if accessGranted then
        sleep(5)
        reset()
        drawInterface()
    end
    
    -- Auto-reset block after 30 seconds
    if blocked then
        sleep(30)
        reset()
        drawInterface()
    end
end
