-- Compact Touchscreen Password Lock (2x size, square buttons)
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

-- Button layout: each button is 2x2 on screen
-- Grid is 3 columns × 4 rows, starting from bottom of screen
local buttons = {
    {char = "1", x = 1, y = 3},   -- row 1: 1 2 3
    {char = "2", x = 4, y = 3},
    {char = "3", x = 7, y = 3},
    {char = "4", x = 1, y = 5},   -- row 2: 4 5 6
    {char = "5", x = 4, y = 5},
    {char = "6", x = 7, y = 5},
    {char = "7", x = 1, y = 7},   -- row 3: 7 8 9
    {char = "8", x = 4, y = 7},
    {char = "9", x = 7, y = 7},
    {char = "<", x = 1, y = 9},   -- row 4: < 0 E
    {char = "0", x = 4, y = 9},
    {char = "E", x = 7, y = 9},
}

-- Button size (square, 2x2 characters)
local BTN_W = 2
local BTN_H = 2

-- Draw a square button with character centered inside
local function drawButton(btn)
    local x, y = btn.x, btn.y
    
    -- Draw background square
    monitor.setBackgroundColor(colors.gray)
    for dy = 0, BTN_H - 1 do
        monitor.setCursorPos(x, y + dy)
        for dx = 0, BTN_W - 1 do
            monitor.write(" ")
        end
    end
    
    -- Draw character in center
    local charX = x + math.floor(BTN_W / 2)
    local charY = y + math.floor(BTN_H / 2)
    monitor.setCursorPos(charX, charY)
    monitor.setBackgroundColor(colors.gray)
    monitor.setTextColor(colors.white)
    monitor.write(btn.char)
end

-- Draw the full interface
local function draw()
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    monitor.setTextScale(1)
    
    -- Password display (dots)
    local dots = ""
    for i = 1, #enteredPassword do
        dots = dots .. "*"
    end
    if #dots == 0 then dots = "_" end
    
    monitor.setCursorPos(2, 1)
    monitor.setTextColor(colors.white)
    monitor.write("PW: " .. dots)
    
    -- Draw all buttons
    for _, btn in ipairs(buttons) do
        drawButton(btn)
    end
    
    -- Status line at bottom
    monitor.setCursorPos(1, 12)
    monitor.setBackgroundColor(colors.black)
    if blocked then
        monitor.setTextColor(colors.red)
        monitor.write("  BLOCKED  ")
    elseif accessGranted then
        monitor.setTextColor(colors.green)
        monitor.write("  GRANTED  ")
    elseif attempts > 0 then
        monitor.setTextColor(colors.orange)
        monitor.write(" Try:" .. attempts .. "/" .. MAX_ATTEMPTS)
    else
        monitor.setTextColor(colors.gray)
        monitor.write("  ENTER PW ")
    end
    
    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.white)
end

-- Check if touch hits a button (square area detection)
local function getButton(x, y)
    for _, btn in ipairs(buttons) do
        if x >= btn.x and x < btn.x + BTN_W and 
           y >= btn.y and y < btn.y + BTN_H then
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
        -- Backspace: remove last character
        if #enteredPassword > 0 then
            enteredPassword = string.sub(enteredPassword, 1, -2)
        end
    else
        -- Digit button
        if #enteredPassword < 8 then
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
print("Lock system ready. Touch the monitor. Ctrl+T to exit.")

while true do
    local event, side, x, y = os.pullEvent("monitor_touch")
    
    local btn = getButton(x, y)
    if btn then
        press(btn)
        draw()
    end
    
    -- Auto-close door after 3 seconds
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
