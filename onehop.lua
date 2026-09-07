local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Server Hopper Hub",
   LoadingTitle = "Loading Hopper...",
   LoadingSubtitle = "Selectable Server Finder",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false,
})

local MainTab = Window:CreateTab("Server Finder")
local MiscTab = Window:CreateTab("Misc")

local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local PlaceId = game.PlaceId
local LocalPlayer = Players.LocalPlayer

local serverMap = {} 
local selectedServerId = nil 

local CurrentServerLabel = MainTab:CreateLabel("คนในห้องปัจจุบัน (Real-Time): กำลังโหลด...")

local function UpdateCurrentPlayers()
    CurrentServerLabel:Set("คนในห้องปัจจุบัน (Real-Time): " .. #Players:GetPlayers() .. " / " .. Players.MaxPlayers)
end
UpdateCurrentPlayers()

Players.PlayerAdded:Connect(UpdateCurrentPlayers)
Players.PlayerRemoving:Connect(UpdateCurrentPlayers)

local StatusLabel = MainTab:CreateLabel("Status: รอการค้นหา...")

local ServerDropdown = MainTab:CreateDropdown({
   Name = "เลือกเซิร์ฟเวอร์ (คน 1 คน)",
   Options = {"ยังไม่มีข้อมูล (กด Refresh)"},
   CurrentOption = {"ยังไม่มีข้อมูล (กด Refresh)"},
   MultipleOptions = false,
   Flag = "ServerDropdown",
   Callback = function(Option)
       local selectedString = Option[1]
       if serverMap[selectedString] then
           selectedServerId = serverMap[selectedString]
           StatusLabel:Set("เลือกแล้ว: " .. selectedString)
       end
   end,
})

local function RefreshServers()
    StatusLabel:Set("Status: กำลังสแกนหาเซิร์ฟเวอร์ล่าสุด...")
    serverMap = {}
    selectedServerId = nil
    
    local optionsList = {}
    local foundCount = 0
    local cursor = ""
    local maxPagesToScan = 100
    
    for page = 1, maxPagesToScan do
        StatusLabel:Set("Status: กำลังสแกนหน้า " .. page .. "... (พบ " .. foundCount .. "/10)")
        local url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        
        if cursor ~= "" then url = url .. "&cursor=" .. cursor end
        
        local success, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)
        
        if success and result and result.data then
            for _, server in ipairs(result.data) do
                if server.playing == 1 and server.id ~= game.JobId then
                    local ping = server.ping and tostring(server.ping) or "??"
                    local fps = server.fps and tostring(math.floor(server.fps)) or "??"
                    
                    local displayName = "Server " .. (foundCount + 1) .. " [ผู้เล่น: " .. server.playing .. " คน | Ping: " .. ping .. "ms]"
                    
                    serverMap[displayName] = server.id
                    table.insert(optionsList, displayName)
                    foundCount = foundCount + 1
                    
                    if foundCount >= 10 then break end
                end
            end
            
            if foundCount >= 10 then break end
            if result.nextPageCursor then cursor = result.nextPageCursor else break end
        else
            break
        end
        task.wait(0.1)
    end
    
    if foundCount > 0 then
        StatusLabel:Set("Status: พบ " .. foundCount .. " เซิร์ฟเวอร์! กรุณาเลือกจากเมนู")
        ServerDropdown:Refresh(optionsList, true)
    else
        StatusLabel:Set("Status: ไม่พบเซิร์ฟเวอร์ที่มีผู้เล่น 1 คน")
        ServerDropdown:Refresh({"ไม่พบข้อมูล"}, true)
    end
end

MainTab:CreateButton({
   Name = "🔄 Refresh ค้นหาเซิร์ฟเวอร์ (ดึงข้อมูลล่าสุด)",
   Callback = function()
       task.spawn(RefreshServers)
   end,
})

MainTab:CreateButton({
   Name = "🚀 เข้าสู่เซิร์ฟเวอร์ที่เลือก",
   Callback = function()
       if selectedServerId then
           StatusLabel:Set("Status: กำลังเทเลพอร์ต...")
           task.wait(0.5)
           TeleportService:TeleportToPlaceInstance(PlaceId, selectedServerId, LocalPlayer)
       else
           StatusLabel:Set("Status: ❌ กรุณาเลือกเซิร์ฟเวอร์จากเมนูก่อน!")
       end
   end,
})

MiscTab:CreateLabel("ตั้งค่าปุ่มลัดสำหรับโปรแกรม")

MiscTab:CreateKeybind({
   Name = "ปุ่มเปิด/ปิด UI (คลิกเพื่อเปลี่ยนปุ่ม)",
   CurrentKeybind = "RightControl",
   HoldToInteract = false,
   Flag = "ToggleUIKey",
   Callback = function()
       local parent = (gethui and gethui()) or game:GetService("CoreGui")
       local rayfieldGui = parent:FindFirstChild("Rayfield") or game:GetService("CoreGui"):FindFirstChild("Rayfield")
       
       if rayfieldGui then
           local mainFrame = rayfieldGui:FindFirstChild("Main")
           if mainFrame then
               mainFrame.Visible = not mainFrame.Visible
           else
               rayfieldGui.Enabled = not rayfieldGui.Enabled
           end
       end
   end,
})
