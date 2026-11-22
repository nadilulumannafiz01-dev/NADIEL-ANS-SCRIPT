local RS=game:GetService("RunService")
local GS=game:GetService("GuiService")
local VIM=game:GetService("VirtualInputManager")
local lp=game:GetService("Players").LocalPlayer
local pg=lp:WaitForChild("PlayerGui")
if _G.AWC then pcall(_G.AWC) end

local LATENCY=0.06
local MAX_SLOT=4
local auto,fly,vert,spd,slot,cps=true,false,0,60,1,{}
local bv,nd,zn,pX,pT,armed,last,t=nil,nil,nil,nil,nil,true,0,0

local gui=Instance.new("ScreenGui")
gui.ResetOnSpawn=false
if not pcall(function() gui.Parent=(gethui and gethui()) or game:GetService("CoreGui") end) or not gui.Parent then
	gui.Parent=pg
end
_G.AWC=function() gui:Destroy() if bv then bv:Destroy() end end

local f=Instance.new("Frame",gui)
f.Size=UDim2.new(0,140,0,194)
f.Position=UDim2.new(0,15,0.15,0)
f.BackgroundColor3=Color3.fromRGB(20,24,33)
f.Active=true f.Draggable=true
Instance.new("UICorner",f)

local title=Instance.new("TextLabel",f)
title.Size=UDim2.new(1,0,0,22)
title.BackgroundTransparency=1
title.Text="Nadiel x Claude"
title.TextColor3=Color3.fromRGB(120,200,255)
title.Font=Enum.Font.GothamBold
title.TextSize=13

local grid=Instance.new("Frame",f)
grid.Position=UDim2.new(0,0,0,24)
grid.Size=UDim2.new(1,0,1,-24)
grid.BackgroundTransparency=1
local g=Instance.new("UIGridLayout",grid)
g.CellSize=UDim2.new(0,62,0,28) g.CellPadding=UDim2.new(0,4,0,4)
g.SortOrder=Enum.SortOrder.LayoutOrder
local pd=Instance.new("UIPadding",grid)
pd.PaddingLeft=UDim.new(0,4)

local n=0
local function B(txt,fn)
	n+=1
	local b=Instance.new("TextButton",grid)
	b.LayoutOrder=n b.Text=txt b.TextSize=11 b.Font=Enum.Font.GothamBold
	b.TextColor3=Color3.new(1,1,1) b.BackgroundColor3=Color3.fromRGB(60,68,85)
	Instance.new("UICorner",b)
	if fn then b.MouseButton1Click:Connect(function() fn(b) end) end
	return b
end

local function hrp() return lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") end
local info,sb

local function setSlot(s)
	slot=s
	if sb then sb.Text="SLOT:"..s end
end

B("AUTO:ON",function(b) auto=not auto b.Text="AUTO:"..(auto and "ON" or "OFF") end)
B("FLY:OFF",function(b)
	fly=not fly b.Text="FLY:"..(fly and "ON" or "OFF")
	if bv then bv:Destroy() bv=nil end
	local r=hrp()
	if fly and r then
		bv=Instance.new("BodyVelocity",r)
		bv.MaxForce=Vector3.one*1e9
		bv.Velocity=Vector3.zero
	end
end)
for _,v in ipairs({{"NAIK",1},{"TURUN",-1}}) do
	local b=B(v[1])
	b.InputBegan:Connect(function(i) if i.UserInputType.Name~="MouseMovement" then vert=v[2] end end)
	b.InputEnded:Connect(function() vert=0 end)
end

sb=B("SLOT:1",function()
	setSlot(slot%MAX_SLOT+1)
	info.Text=cps[slot] and "terisi" or "kosong"
end)
B("SET CP",function()
	local r=hrp()
	if r then cps[slot]=r.CFrame info.Text="CP "..slot.." OK" end
end)
B("TP CP",function()
	local r=hrp()
	if not r then return end
	if not cps[slot] then info.Text="slot "..slot.." kosong" return end
	r.CFrame=cps[slot]
	r.AssemblyLinearVelocity=Vector3.zero
	info.Text="TP "..slot
	-- otomatis lanjut ke CP terisi berikutnya
	for i=1,MAX_SLOT-1 do
		local s=(slot-1+i)%MAX_SLOT+1
		if cps[s] then setSlot(s) break end
	end
end)
info=B("Spd 60")
B("-",function() spd=math.max(10,spd-10) info.Text="Spd "..spd end)
B("+",function() spd=math.min(300,spd+10) info.Text="Spd "..spd end)

RS.Heartbeat:Connect(function()
	local r=hrp()
	local h=lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
	if fly and bv and r and h then
		bv.Velocity=h.MoveDirection*spd+Vector3.new(0,vert*spd,0)
	end
end)

local function grn(c) return c.G>.6 and c.R<.45 and c.B<.6 end
local function wht(c) return c.R>.93 and c.G>.93 and c.B>.93 end
local function ok(o) return o and o:IsDescendantOf(pg) and o.Visible end

RS.RenderStepped:Connect(function(dt)
	if not auto then return end
	if not ok(nd) then nd=nil pX=nil end
	if not ok(zn) then zn=nil end
	if not nd or not zn then
		t+=dt
		if t>.3 then
			t=0
			for _,o in ipairs(pg:GetDescendants()) do
				if o:IsA("Frame") and o.Visible and o.BackgroundTransparency<.5 then
					local s=o.AbsoluteSize
					if not zn and grn(o.BackgroundColor3) and s.X>30 and s.X<400 and s.Y>15 then zn=o
					elseif not nd and wht(o.BackgroundColor3) and s.X<15 and s.Y>20 then nd=o end
				end
			end
		end
		return
	end

	local now=os.clock()
	local x=nd.AbsolutePosition.X+nd.AbsoluteSize.X/2
	local a=x
	if pX and now>pT then a=x+(x-pX)/(now-pT)*LATENCY end
	local lo,hi=math.min(pX or x,a,x),math.max(pX or x,a,x)
	pX,pT=x,now

	local l=zn.AbsolutePosition.X
	local w=zn.AbsoluteSize.X
	local c=l+w/2
	local inZone=hi>=l and lo<=l+w

	if not inZone then armed=true end

	-- klik saat jarum melewati TENGAH zona hijau
	if armed and inZone and lo<=c and c<=hi and now-last>.15 then
		last=now
		armed=false
		local p,s=zn.AbsolutePosition,zn.AbsoluteSize
		local cx,cy=p.X+s.X/2,p.Y+s.Y/2+GS:GetGuiInset().Y
		VIM:SendMouseButtonEvent(cx,cy,0,true,game,0)
		VIM:SendMouseButtonEvent(cx,cy,0,false,game,0)
	end
end)
