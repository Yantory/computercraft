-- Compact Touchscreen Password Lock (1 block)
local monitor = peripheral.find("monitor")
if not monitor then
    error("Monitor not found! Place an Advanced Monitor next to the computer")
end

-- Settings
local CORRECT_PASSWORD = "1234"
local MAX_ATTEMPTS = 3

-- Variables
local enteredPassword = ""
local attempts = 0
local accessGranted = false
local blocked = false

-- Screen dimensions (1 block = 7 wide, 5 tall at scale 1)
local W = 7
local H = 5

-- Button layout (3 columns, 4 rows)
-- Row 1: 1 2 3
-- Row 2: 4 5 6
-- Row 3: 7 8 9
-- Row 4: < 0 E
local buttons = {
    {char = "1", x = 1, y = 1},
    {char = "2", x = 3, y = 1},
    {char = "3", x = 5, y = 1},
    {char = "4", x = 1, y = 2},
    {char = "5", x = 3, y = 2},
    {char = "6", x = 5, y = 2},
    {char = "7", x = 1, y = 3},
    {char = "8", x = 3, y = 3},
    {char = "9", x = 5, y = 3},
    {char = "<", x = 1, y = 4},  -- Backspace
    {char = "0", x = 3, y = 4},
    {char = "E", x = 5, y = 4},  -- Enter
}

-- Draw the interface
local function draw()
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    monitor.setTextScale(0.5)  -- Tiny text to fit more
    
    -- Show password as dots
    local dots = ""
    for i = 1, #enteredPassword do
        dots = dots .. "."
    end
    if #dots == 0 then dots = "_" end
    
    monitor.setCursorPos(1, 1)
    monitor.setTextColor(colors.white)
    monitor.write(dots)
    
    -- Status line
    monitor.setCursorPos(1, 2)
    if blocked then
        monitor.setTextColor(colors.red)
        monitor.write("BLOCKED")
    elseif accessGranted then
        monitor.setTextColor(colors.green)
        monitor.write("OPEN")
    elseif attempts > 0 then
        monitor.setTextColor(colors.orange)
        monitor.write("x" .. attempts)
    else
        monitor.setTextColor(colors.gray)
        monitor.write("----")
    end
    
    -- Draw button grid
    monitor.setBackgroundColor(colors.gray)
    for _, btn in ipairs(buttons) do
        monitor.setCursorPos(btn.x, btn.y + 2)
        monitor.setTextColor(colors.white)
        monitor.write(btn.char)
    end
    
    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.white)
end

-- Check if touch hits a button
local function getButton(x, y)
    for _, btn in ipairs(buttons) do
        if x >= btn.x and x < btn.x + 1 and y == btn.y + 2 then
            return btn
        end
    end
    return nil
end

-- Handle button press
local function press(btn)
    if blocked or accessGranted then return end
    
    if btn.char == "E" then
        -- Enter: check password
        if enteredPassword == CORRECT_PASSWORD then
            accessGranted = true
            redstone.setOutput("back", true)
        else
            enteredPassword = ""
            attempts = attempts + 1
            if attempts >= MAX_ATTEMPTS then
                blocked = true
            end
        end
    elseif btn.char == "<" then
        -- Backspace
        if #enteredPassword > 0 then
            enteredPassword = string.sub(enteredPassword, 1, -2)
        end
    else
        -- Digit
        if #enteredPassword < 6 then
            enteredPassword = enteredPassword .. btn.char
        end
    end
end

-- Reset function
local function reset()
    enteredPassword = ""
    attempts = 0
    blocked = false
    accessGranted = false
    redstone.setOutput("back", false)
end

-- Main
draw()
print("Touch the monitor to enter password. Ctrl+T to exit")

while true do
    local event, side, x, y = os.pullEvent("monitor_touch")
    
    local btn = getButton(x, y)
    if btn then
        press(btn)
        draw()
    end
    
    -- Auto-close after 3 seconds
    if accessGranted then
        sleep(3)
        reset()
        draw()
    end
    
    -- Auto-unblock after 10 seconds
    if blocked then
        sleep(10)
        reset()
        draw()
    end
end
