local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Hebo hub",
    SubTitle = "Ultra Fast Server Finder",
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
    Title = "เลือกเซิร์ฟเวอร์",
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
    StatusLabel:SetDesc("กำลังตรวจสอบระบบ API (โหมดความเร็วสูง)...")
    serverMap = {}
    selectedServerId = nil
    
    local baseUrl = "https://games.roblox.com/v1/games/"
    local testSuccess = pcall(function()
        return game:HttpGet(baseUrl .. PlaceId .. "/servers/Public?limit=10")
    end)
    
    if not testSuccess then
        baseUrl = "https://games.roproxy.com/v1/games/"
    end
    
    local foundServers = {}
    local cursor = ""
    local maxPagesToScan = 100
    
    for page = 1, maxPagesToScan do
        StatusLabel:SetDesc("กำลังสแกนหาแบบเร็ว... (หน้า " .. page .. ")")
        
        local url = baseUrl .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        if cursor ~= "" then url = url .. "&cursor=" .. cursor end
        
        local success, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)
        
        if success and result and result.data then
            for _, server in ipairs(result.data) do
                if server.playing and server.playing > 0 and server.playing < Players.MaxPlayers and server.id ~= game.JobId then
                    table.insert(foundServers, server)
                    if #foundServers >= 10 then break end
                end
            end
            
            if #foundServers >= 10 then break end
            
            if result.nextPageCursor then 
                cursor = result.nextPageCursor 
            else 
                break 
            end
        else
            if page == 1 then
                StatusLabel:SetDesc("เกิดข้อผิดพลาด: API ถูกบล็อกหรือไม่ตอบสนอง")
                return
            else
                break
            end
        end
        
        if page % 5 == 0 then
            task.wait(0.1)
        end
    end
    
    if #foundServers > 0 then
        table.sort(foundServers, function(a, b)
            return a.playing < b.playing
        end)
        
        local optionsList = {}
        for i, s in ipairs(foundServers) do
            local ping = s.ping and tostring(s.ping) or "??"
            
            local displayName = "ผู้เล่น: " .. s.playing .. " คน | Ping: " .. ping .. "ms" .. string.rep(" ", i)
            
            serverMap[displayName] = s.id
            table.insert(optionsList, displayName)
        end
        
        StatusLabel:SetDesc("✅ ค้นหาเสร็จสิ้นอย่างรวดเร็ว!")
        ServerDropdown:SetValues(optionsList)
        ServerDropdown:SetValue(optionsList[1])
    else
        StatusLabel:SetDesc("ไม่พบข้อมูลเซิร์ฟเวอร์ที่ว่างเลย")
        ServerDropdown:SetValues({"ไม่พบข้อมูล"})
        ServerDropdown:SetValue("ไม่พบข้อมูล")
    end
end

Tabs.Main:AddButton({
    Title = "🔄 Refresh ค้นหาเซิร์ฟเวอร์",
    Description = "ค้นหาเซิร์ฟเวอร์ที่คนน้อยที่สุด (โหมดสปีดรวดเร็ว)",
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

Tabs.Misc:AddDropdown("InterfaceTheme", {
    Title = "🎨 เปลี่ยนสีธีม (Theme)",
    Description = "ปรับเปลี่ยนสีของหน้าต่าง UI",
    Values = Fluent.Themes,
    Default = Fluent.Theme,
    Callback = function(Value)
        Fluent:SetTheme(Value)
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
