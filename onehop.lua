local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Hebo Hub",
    SubTitle = "Selectable Server Finder",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true, 
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Server Finder", Icon = "search" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "settings" })
}

local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PlaceId = game.PlaceId
local LocalPlayer = Players.LocalPlayer

local serverMap = {}
local selectedServerId = nil

local CurrentServerLabel = Tabs.Main:AddParagraph({
    Title = "คนในห้องปัจจุบัน (Real-Time)",
    Content = "กำลังโหลด..."
})

local function UpdateCurrentPlayers()
    CurrentServerLabel:SetDesc("จำนวนผู้เล่น: " .. #Players:GetPlayers() .. " / " .. Players.MaxPlayers)
end
UpdateCurrentPlayers()

Players.PlayerAdded:Connect(UpdateCurrentPlayers)
Players.PlayerRemoving:Connect(UpdateCurrentPlayers)

local StatusLabel = Tabs.Main:AddParagraph({
    Title = "สถานะการค้นหา",
    Content = "รอการค้นหา..."
})

local ServerDropdown = Tabs.Main:AddDropdown("ServerDropdown", {
    Title = "เลือกเซิร์ฟเวอร์ (คน 1 คน)",
    Values = {"ยังไม่มีข้อมูล (กด Refresh)"},
    Multi = false,
    Default = 1,
})

ServerDropdown:OnChanged(function(Value)
    if serverMap[Value] then
        selectedServerId = serverMap[Value]
        StatusLabel:SetDesc("เลือกแล้ว: " .. Value)
    end
end)

local function RefreshServers()
    StatusLabel:SetDesc("กำลังสแกนหาเซิร์ฟเวอร์ล่าสุด...")
    serverMap = {}
    selectedServerId = nil
    
    local optionsList = {}
    local foundCount = 0
    local cursor = ""
    local maxPagesToScan = 100
    
    for page = 1, maxPagesToScan do
        StatusLabel:SetDesc("กำลังสแกนหน้า " .. page .. "... (พบ " .. foundCount .. "/10)")
        
        local url = "https://games.roproxy.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        
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
            StatusLabel:SetDesc("เกิดข้อผิดพลาด (อาจเป็นที่ Executor หรือ Proxy)")
            break
        end
        task.wait(0.1)
    end
    
    if foundCount > 0 then
        StatusLabel:SetDesc("พบ " .. foundCount .. " เซิร์ฟเวอร์! กรุณาเลือกจากเมนู")
        ServerDropdown:SetValues(optionsList)
        ServerDropdown:SetValue(optionsList[1])
    else
        StatusLabel:SetDesc("ไม่พบเซิร์ฟเวอร์ที่มีผู้เล่น 1 คน")
        ServerDropdown:SetValues({"ไม่พบข้อมูล"})
        ServerDropdown:SetValue("ไม่พบข้อมูล")
    end
end

Tabs.Main:AddButton({
    Title = "🔄 Refresh ค้นหาเซิร์ฟเวอร์",
    Description = "ดึงข้อมูลเซิร์ฟเวอร์ล่าสุด",
    Callback = function()
        task.spawn(RefreshServers)
    end
})

Tabs.Main:AddButton({
    Title = "🚀 เข้าสู่เซิร์ฟเวอร์ที่เลือก",
    Description = "วาร์ปไปเซิร์ฟเวอร์ที่เลือกไว้ใน Dropdown",
    Callback = function()
        if selectedServerId then
            StatusLabel:SetDesc("กำลังเทเลพอร์ต...")
            task.wait(0.5)
            TeleportService:TeleportToPlaceInstance(PlaceId, selectedServerId, LocalPlayer)
        else
            StatusLabel:SetDesc("❌ กรุณาเลือกเซิร์ฟเวอร์จากเมนูก่อน!")
        end
    end
})

Tabs.Misc:AddKeybind("ToggleUI", {
    Title = "ปุ่มเปิด/ปิด UI",
    Description = "คลิกเพื่อตั้งปุ่มซ่อน/แสดงหน้าต่าง",
    Mode = "Toggle",
    Default = "RightControl",
    ChangedCallback = function(New)
        Window.MinimizeKey = New
    end
})

Tabs.Misc:AddButton({
    Title = "🗑️ Reduce Lag",
    Description = "ลบเทกเจอร์/ลดแสง/ลบเอฟเฟกต์ เพื่อเพิ่ม FPS",
    Callback = function()
        settings().Rendering.QualityLevel = 1
        game.Lighting.GlobalShadows = false
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("Part") or v:IsA("Union") or v:IsA("CornerWedgePart") or v:IsA("TrussPart") or v:IsA("MeshPart") then
                v.Material = "Plastic"
                v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Lifetime = NumberRange.new(0)
            elseif v:IsA("Explosion") or v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") then
                v.Enabled = false
            end
        end
    end
})

Tabs.Misc:AddToggle("DisableRender", {
    Title = "🚫 Disable Render",
    Description = "จอดำเพื่อลดการทำงานของการ์ดจอ (CPU/GPU)",
    Default = false,
    Callback = function(Value)
        pcall(function()
            RunService:Set3dRenderingEnabled(not Value)
        end)
    end
})
