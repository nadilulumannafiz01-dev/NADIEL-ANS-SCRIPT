local RS=game:GetService("RunService")
local GS=game:GetService("GuiService")
local UIS=game:GetService("UserInputService")
local VIM=game:GetService("VirtualInputManager")
local lp=game:GetService("Players").LocalPlayer
local pg=lp:WaitForChild("PlayerGui")
if _G.AWC then pcall(_G.AWC) end

local S={auto=true,latency=0.06,fly=false,vert=0,speed=60,slot=1,max=4}
local cps,conns,bv={}, {}, nil
local function bind(sig,fn) local c=sig:Connect(fn) conns[#conns+1]=c return c end
local function isPress(i) return i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch end
local function isMove(i) return i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch end

local C={bg=Color3.fromRGB(22,22,27),side=Color3.fromRGB(27,27,33),row=Color3.fromRGB(38,38,45),
	acc=Color3.fromRGB(30,144,255),txt=Color3.fromRGB(235,235,240),sub=Color3.fromRGB(150,150,162),off=Color3.fromRGB(70,70,80)}

local function new(cls,props,parent)
	local o=Instance.new(cls)
	for k,v in pairs(props) do o[k]=v end
	o.Parent=parent
	return o
end
local function round(o,r) new("UICorner",{CornerRadius=UDim.new(0,r or 8)},o) end
local function label(parent,text,size,pos,sz,color,font,align)
	return new("TextLabel",{BackgroundTransparency=1,Text=text,TextSize=size,Position=pos,Size=sz,
		TextColor3=color or C.txt,Font=font or Enum.Font.Gotham,
		TextXAlignment=align or Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},parent)
end

----------------------------------------------------------------
-- WINDOW
----------------------------------------------------------------
local gui=new("ScreenGui",{Name="NadielHub",ResetOnSpawn=false})
if not pcall(function() gui.Parent=(gethui and gethui()) or game:GetService("CoreGui") end) or not gui.Parent then gui.Parent=pg end

local W,H=460,270
local main=new("Frame",{Size=UDim2.new(0,W,0,H),Position=UDim2.new(0.5,-W/2,0.5,-H/2),BackgroundColor3=C.bg,Active=true,ClipsDescendants=true},gui)
round(main,12)
new("UIStroke",{Color=Color3.fromRGB(60,60,70),Thickness=1},main)

local head=new("Frame",{Size=UDim2.new(1,0,0,44),BackgroundTransparency=1},main)
label(head,"▲",18,UDim2.new(0,14,0,0),UDim2.new(0,24,1,0),C.acc,Enum.Font.GothamBold)
label(head,"Nadiel x Claude",14,UDim2.new(0,42,0,6),UDim2.new(0,200,0,18),C.txt,Enum.Font.GothamBold)
label(head,"Auto Workout Hub",11,UDim2.new(0,42,0,24),UDim2.new(0,200,0,14),C.sub)

local function headBtn(text,x)
	local b=new("TextButton",{Text=text,TextSize=16,Font=Enum.Font.GothamBold,TextColor3=C.sub,BackgroundTransparency=1,
		Size=UDim2.new(0,30,0,30),Position=UDim2.new(1,x,0,7)},head)
	return b
end
local bMin=headBtn("–",-72)
local bClose=headBtn("✕",-38)

local body=new("Frame",{Position=UDim2.new(0,0,0,44),Size=UDim2.new(1,0,1,-44),BackgroundTransparency=1},main)
local side=new("Frame",{Size=UDim2.new(0,124,1,0),BackgroundColor3=C.side,BorderSizePixel=0},body)
local tabList=new("Frame",{Size=UDim2.new(1,0,1,-56),BackgroundTransparency=1},side)
new("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},tabList)
new("UIPadding",{PaddingTop=UDim.new(0,6),PaddingLeft=UDim.new(0,6),PaddingRight=UDim.new(0,6)},tabList)

label(side,lp.DisplayName,12,UDim2.new(0,10,1,-48),UDim2.new(1,-14,0,16),C.txt,Enum.Font.GothamBold)
local statusLbl=label(side,"Siap",10,UDim2.new(0,10,1,-30),UDim2.new(1,-14,0,14),C.sub)
local function setStatus(t) statusLbl.Text=t end

local content=new("Frame",{Position=UDim2.new(0,124,0,0),Size=UDim2.new(1,-124,1,0),BackgroundTransparency=1},body)

-- drag jendela
do
	local drag,ds,sp
	head.InputBegan:Connect(function(i) if isPress(i) then drag,ds,sp=true,i.Position,main.Position end end)
	bind(UIS.InputChanged,function(i)
		if drag and isMove(i) then
			local d=i.Position-ds
			main.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
		end
	end)
	bind(UIS.InputEnded,function(i) if isPress(i) then drag=false end end)
end

local mini=false
bMin.MouseButton1Click:Connect(function()
	mini=not mini
	body.Visible=not mini
	main.Size=UDim2.new(0,W,0,mini and 44 or H)
end)

----------------------------------------------------------------
-- KOMPONEN UI
----------------------------------------------------------------
local pages,tabBtns={}, {}
local function addTab(name,order)
	local b=new("TextButton",{Text=name,TextSize=12,Font=Enum.Font.GothamMedium,TextColor3=C.sub,BackgroundColor3=C.row,
		BackgroundTransparency=1,Size=UDim2.new(1,0,0,30),LayoutOrder=order,AutoButtonColor=false},tabList)
	round(b,8)
	local p=new("ScrollingFrame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,
		CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=false},content)
	new("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},p)
	new("UIPadding",{PaddingTop=UDim.new(0,8),PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,12),PaddingBottom=UDim.new(0,8)},p)
	label(p,name,15,UDim2.new(),UDim2.new(1,0,0,22),C.txt,Enum.Font.GothamBold).LayoutOrder=0
	pages[name],tabBtns[name]=p,b
	b.MouseButton1Click:Connect(function()
		for n,pp in pairs(pages) do
			pp.Visible=(n==name)
			tabBtns[n].BackgroundTransparency=(n==name) and 0 or 1
			tabBtns[n].TextColor3=(n==name) and C.txt or C.sub
		end
	end)
	return p
end

local ord=0
local function base(page,title,desc)
	ord+=1
	local r=new("Frame",{Size=UDim2.new(1,0,0,46),BackgroundColor3=C.row,LayoutOrder=ord},page)
	round(r,8)
	label(r,title,13,UDim2.new(0,10,0,6),UDim2.new(1,-190,0,18),C.txt,Enum.Font.GothamMedium)
	label(r,desc or "",10,UDim2.new(0,10,0,25),UDim2.new(1,-190,0,14),C.sub)
	return r
end

local function toggle(page,title,desc,def,cb)
	local r=base(page,title,desc)
	local sw=new("Frame",{Size=UDim2.new(0,40,0,20),Position=UDim2.new(1,-50,0.5,-10)},r)
	round(sw,10)
	local kn=new("Frame",{Size=UDim2.new(0,16,0,16),BackgroundColor3=Color3.new(1,1,1)},sw)
	round(kn,8)
	local on=def
	local function paint()
		sw.BackgroundColor3=on and C.acc or C.off
		kn.Position=on and UDim2.new(1,-18,0,2) or UDim2.new(0,2,0,2)
	end
	paint()
	local function set(v,silent) on=v paint() if not silent then cb(on) end end
	new("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=""},r).MouseButton1Click:Connect(function() set(not on) end)
	return set
end

local function slider(page,title,desc,mn,mx,def,cb)
	local r=base(page,title,desc)
	local val=label(r,tostring(def),11,UDim2.new(1,-176,0.5,-8),UDim2.new(0,32,0,16),C.sub,Enum.Font.Gotham,Enum.TextXAlignment.Right)
	local bar=new("Frame",{Size=UDim2.new(0,100,0,4),Position=UDim2.new(1,-134,0.5,-2),BackgroundColor3=C.off},r)
	round(bar,2)
	local fill=new("Frame",{Size=UDim2.new((def-mn)/(mx-mn),0,1,0),BackgroundColor3=C.acc},bar)
	round(fill,2)
	local hit=new("TextButton",{Size=UDim2.new(1,0,0,28),Position=UDim2.new(0,0,0.5,-14),BackgroundTransparency=1,Text=""},bar)
	local drag=false
	local function set(x)
		local a=math.clamp((x-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
		local v=math.floor(mn+(mx-mn)*a+0.5)
		fill.Size=UDim2.new(a,0,1,0)
		val.Text=tostring(v)
		cb(v)
	end
	hit.InputBegan:Connect(function(i) if isPress(i) then drag=true set(i.Position.X) end end)
	bind(UIS.InputChanged,function(i) if drag and isMove(i) then set(i.Position.X) end end)
	bind(UIS.InputEnded,function(i) if isPress(i) then drag=false end end)
end

local function button(page,title,desc,text,cb)
	local r=base(page,title,desc)
	local b=new("TextButton",{Text=text,TextSize=12,Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1),
		BackgroundColor3=C.acc,Size=UDim2.new(0,76,0,26),Position=UDim2.new(1,-86,0.5,-13)},r)
	round(b,6)
	b.MouseButton1Click:Connect(function() cb(b) end)
	return b
end

local function holdRow(page,title,desc,cbUp,cbDown)
	local r=base(page,title,desc)
	local function hb(text,x,v)
		local b=new("TextButton",{Text=text,TextSize=11,Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1),
			BackgroundColor3=C.acc,Size=UDim2.new(0,56,0,26),Position=UDim2.new(1,x,0.5,-13)},r)
		round(b,6)
		b.InputBegan:Connect(function(i) if isPress(i) then S.vert=v end end)
		b.InputEnded:Connect(function(i) if isPress(i) and S.vert==v then S.vert=0 end end)
	end
	hb("NAIK",-126,1)
	hb("TURUN",-66,-1)
end

----------------------------------------------------------------
-- HALAMAN
----------------------------------------------------------------
local pAuto=addTab("Automatic",1)
local pFly=addTab("Fly",2)
local pCP=addTab("Checkpoint",3)
local pSet=addTab("Settings",4)

local function hrp() return lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") end

-- Automatic
toggle(pAuto,"Auto Click","Klik tepat di tengah zona hijau",true,function(v) S.auto=v setStatus(v and "Auto ON" or "Auto OFF") end)
slider(pAuto,"Latency (ms)","Naikkan jika klik telat",0,150,60,function(v) S.latency=v/1000 end)

-- Fly
local function stopFly()
	S.fly=false S.vert=0
	if bv then bv:Destroy() bv=nil end
end
local setFlyUI
setFlyUI=toggle(pFly,"Fly","Joystick untuk gerak, tombol untuk naik/turun",false,function(v)
	if v then
		local r=hrp()
		if not r then setStatus("Karakter belum siap") setFlyUI(false,true) return end
		bv=new("BodyVelocity",{MaxForce=Vector3.one*1e9,Velocity=Vector3.zero},r)
		S.fly=true
		setStatus("Fly ON")
	else
		stopFly() setStatus("Fly OFF")
	end
end)
slider(pFly,"Fly Speed","Kecepatan terbang",10,300,60,function(v) S.speed=v end)
holdRow(pFly,"Naik / Turun","Tahan tombol")

bind(lp.CharacterAdded,function() stopFly() setFlyUI(false,true) end)
bind(RS.Heartbeat,function()
	local r=hrp()
	local h=lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
	if S.fly and bv and bv.Parent and r and h then
		bv.Velocity=h.MoveDirection*S.speed+Vector3.new(0,S.vert*S.speed,0)
	end
end)

-- Checkpoint
local slotBtn
slotBtn=button(pCP,"Slot Aktif","Tekan untuk ganti slot (1-"..S.max..")","Slot 1",function(b)
	S.slot=S.slot%S.max+1
	b.Text="Slot "..S.slot
	setStatus("Slot "..S.slot..(cps[S.slot] and " terisi" or " kosong"))
end)
button(pCP,"Simpan Posisi","Simpan lokasi ke slot aktif","SET CP",function()
	local r=hrp()
	if r then cps[S.slot]=r.CFrame setStatus("CP "..S.slot.." tersimpan") end
end)
button(pCP,"Teleport","Otomatis lanjut ke CP berikutnya","TP CP",function()
	local r=hrp()
	if not r then return end
	if not cps[S.slot] then setStatus("Slot "..S.slot.." kosong") return end
	r.CFrame=cps[S.slot]
	r.AssemblyLinearVelocity=Vector3.zero
	setStatus("TP ke "..S.slot)
	for i=1,S.max-1 do
		local s=(S.slot-1+i)%S.max+1
		if cps[s] then S.slot=s slotBtn.Text="Slot "..s break end
	end
end)

-- Settings
button(pSet,"Tutup Script","Hapus UI dan matikan semua fitur","UNLOAD",function() if _G.AWC then _G.AWC() end end)

bClose.MouseButton1Click:Connect(function() if _G.AWC then _G.AWC() end end)

_G.AWC=function()
	stopFly()
	for _,c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	gui:Destroy()
	_G.AWC=nil
end

-- tab pertama aktif
pages["Automatic"].Visible=true
tabBtns["Automatic"].BackgroundTransparency=0
tabBtns["Automatic"].TextColor3=C.txt

----------------------------------------------------------------
-- AUTO CLICK
----------------------------------------------------------------
local nd,zn,pX,pT,armed,last,t=nil,nil,nil,nil,true,0,0
local function grn(c) return c.G>.6 and c.R<.45 and c.B<.6 end
local function wht(c) return c.R>.93 and c.G>.93 and c.B>.93 end
local function ok(o) return o and o:IsDescendantOf(pg) and o.Visible end

bind(RS.RenderStepped,function(dt)
	if not S.auto then return end
	if not ok(nd) then nd=nil pX=nil end
	if not ok(zn) then zn=nil end
	if not nd or not zn then
		t+=dt
		if t>.3 then
			t=0
			for _,o in ipairs(pg:GetDescendants()) do
				if o:IsA("Frame") and o.Visible and o.BackgroundTransparency<.5 and not o:IsDescendantOf(gui) then
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
	if pX and now>pT then a=x+(x-pX)/(now-pT)*S.latency end
	local lo,hi=math.min(pX or x,a,x),math.max(pX or x,a,x)
	pX,pT=x,now

	local l,w=zn.AbsolutePosition.X,zn.AbsoluteSize.X
	local c=l+w/2
	local inZ=hi>=l and lo<=l+w
	if not inZ then armed=true end

	if armed and inZ and lo<=c and c<=hi and now-last>.15 then
		last=now armed=false
		local p,s=zn.AbsolutePosition,zn.AbsoluteSize
		local cx,cy=p.X+s.X/2,p.Y+s.Y/2+GS:GetGuiInset().Y
		VIM:SendMouseButtonEvent(cx,cy,0,true,game,0)
		VIM:SendMouseButtonEvent(cx,cy,0,false,game,0)
	end
end)
