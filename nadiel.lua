local RS=game:GetService("RunService")
local GS=game:GetService("GuiService")
local UIS=game:GetService("UserInputService")
local VIM=game:GetService("VirtualInputManager")
local Stats=game:GetService("Stats")
local Players=game:GetService("Players")
local lp=Players.LocalPlayer
local pg=lp:WaitForChild("PlayerGui")
if _G.AWC then pcall(_G.AWC) end

local VERSION="v1.2.0"
local START=os.clock()
local alive=true

local S={auto=true,latency=0.06,fly=false,vert=0,speed=60,slot=1,max=4,
	aim=false,aimFov=150,aimSmooth=40,aimObjects=true,aimPlayers=false,autoShoot=false,
	finish=false}
local cps,conns,bv={}, {}, nil
local function bind(sig,fn) local c=sig:Connect(fn) conns[#conns+1]=c return c end
local function isPress(i) return i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch end
local function isMove(i) return i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch end

local C={
	bg=Color3.fromRGB(10,14,26), side=Color3.fromRGB(13,19,36), row=Color3.fromRGB(20,28,50),
	acc=Color3.fromRGB(0,140,255), txt=Color3.fromRGB(232,238,250), sub=Color3.fromRGB(128,142,170),
	off=Color3.fromRGB(52,64,92), offTxt=Color3.fromRGB(110,122,150), line=Color3.fromRGB(30,50,95),
}

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

local function hrp() return lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") end

local function nameHas(o,keys)
	local n=o.Name:lower()
	local pn=o.Parent and o.Parent.Name:lower() or ""
	for _,k in ipairs(keys) do
		if n:find(k,1,true) or pn:find(k,1,true) then return true end
	end
	return false
end

----------------------------------------------------------------
-- WINDOW
----------------------------------------------------------------
local gui=new("ScreenGui",{Name="NadielHub",ResetOnSpawn=false,IgnoreGuiInset=true})
if not pcall(function() gui.Parent=(gethui and gethui()) or game:GetService("CoreGui") end) or not gui.Parent then gui.Parent=pg end

local W,H=460,270
local main=new("Frame",{Size=UDim2.new(0,W,0,H),Position=UDim2.new(0.5,-W/2,0.5,-H/2),BackgroundColor3=C.bg,Active=true,ClipsDescendants=true},gui)
round(main,12)
new("UIStroke",{Color=C.line,Thickness=1},main)

local head=new("Frame",{Size=UDim2.new(1,0,0,44),BackgroundTransparency=1},main)
label(head,"▲",18,UDim2.new(0,14,0,0),UDim2.new(0,24,1,0),C.acc,Enum.Font.GothamBold)
label(head,"Nadiel Hub",14,UDim2.new(0,42,0,6),UDim2.new(0,200,0,18),C.txt,Enum.Font.GothamBold)
label(head,"by Nadiel x Claude",11,UDim2.new(0,42,0,24),UDim2.new(0,200,0,14),C.sub)

local function headBtn(text,x)
	return new("TextButton",{Text=text,TextSize=16,Font=Enum.Font.GothamBold,TextColor3=C.sub,BackgroundTransparency=1,
		Size=UDim2.new(0,30,0,30),Position=UDim2.new(1,x,0,7)},head)
end
local bMin=headBtn("–",-72)
local bClose=headBtn("✕",-38)

local body=new("Frame",{Position=UDim2.new(0,0,0,44),Size=UDim2.new(1,0,1,-44),BackgroundTransparency=1},main)
local side=new("Frame",{Size=UDim2.new(0,124,1,0),BackgroundColor3=C.side,BorderSizePixel=0},body)
local tabList=new("ScrollingFrame",{Size=UDim2.new(1,0,1,-56),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=0,
	CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y},side)
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

-- minimize jadi logo (bisa digeser, tap untuk buka)
local logo=new("TextButton",{Size=UDim2.new(0,46,0,46),BackgroundColor3=C.side,Text="▲",TextColor3=C.acc,TextSize=20,
	Font=Enum.Font.GothamBold,AutoButtonColor=false,Visible=false,Active=true},gui)
round(logo,23)
new("UIStroke",{Color=C.acc,Thickness=2},logo)

local function showLogo()
	local p=main.AbsolutePosition
	logo.Position=UDim2.new(0,p.X,0,p.Y)
	main.Visible=false
	logo.Visible=true
end
local function showMain()
	local vs=workspace.CurrentCamera.ViewportSize
	local p=logo.AbsolutePosition
	main.Position=UDim2.new(0,math.clamp(p.X,0,math.max(0,vs.X-W)),0,math.clamp(p.Y,0,math.max(0,vs.Y-H)))
	logo.Visible=false
	main.Visible=true
end
bMin.MouseButton1Click:Connect(showLogo)

do
	local down,moved,ds,sp=false,false,nil,nil
	logo.InputBegan:Connect(function(i)
		if isPress(i) then down,moved,ds,sp=true,false,i.Position,logo.Position end
	end)
	bind(UIS.InputChanged,function(i)
		if down and isMove(i) then
			local d=i.Position-ds
			if d.Magnitude>6 then moved=true end
			if moved then
				logo.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
			end
		end
	end)
	bind(UIS.InputEnded,function(i)
		if down and isPress(i) then
			down=false
			if not moved then showMain() end
		end
	end)
end

----------------------------------------------------------------
-- KOMPONEN UI
----------------------------------------------------------------
local pages,tabBtns={}, {}
local function addTab(name,order)
	local b=new("TextButton",{Text=name,TextSize=12,Font=Enum.Font.GothamMedium,TextColor3=C.sub,BackgroundColor3=C.row,
		BackgroundTransparency=1,Size=UDim2.new(1,0,0,28),LayoutOrder=order,AutoButtonColor=false},tabList)
	round(b,8)
	local p=new("ScrollingFrame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,
		ScrollBarImageColor3=C.acc,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=false},content)
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

local function holdRow(page,title,desc)
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
local pDash=addTab("Dashboard",1)
local pAuto=addTab("Automatic",2)
local pAim=addTab("Auto Aim",3)
local pFly=addTab("Fly",4)
local pCP=addTab("Checkpoint",5)
local pObby=addTab("Obby",6)
local pSet=addTab("Settings",7)

----------------------------------------------------------------
-- DASHBOARD
----------------------------------------------------------------
do
	local hd=new("Frame",{Size=UDim2.new(1,0,0,52),BackgroundColor3=C.row,LayoutOrder=1},pDash)
	round(hd,8)
	local bar=new("Frame",{Size=UDim2.new(0,3,1,-16),Position=UDim2.new(0,8,0,8),BackgroundColor3=C.acc,BorderSizePixel=0},hd)
	round(bar,2)
	label(hd,"NADIEL HUB",16,UDim2.new(0,20,0,7),UDim2.new(1,-30,0,22),C.acc,Enum.Font.GothamBold)
	label(hd,"Auto Workout • by Nadiel x Claude",10,UDim2.new(0,20,0,29),UDim2.new(1,-30,0,14),C.sub)

	local grid=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=2},pDash)
	new("UIGridLayout",{CellSize=UDim2.new(0.5,-3,0,46),CellPadding=UDim2.new(0,6,0,6),SortOrder=Enum.SortOrder.LayoutOrder},grid)

	local function card(title,order)
		local c=new("Frame",{BackgroundColor3=C.row,LayoutOrder=order},grid)
		round(c,8)
		label(c,title,10,UDim2.new(0,10,0,5),UDim2.new(1,-14,0,12),C.sub)
		return label(c,"N/A",15,UDim2.new(0,10,0,20),UDim2.new(1,-14,0,20),C.txt,Enum.Font.GothamBold)
	end

	local vAuto=card("AUTO CLICK",1)
	local vAim=card("AUTO AIM",2)
	local vFly=card("FLY",3)
	local vFin=card("AUTO FINISH",4)
	local vFps=card("FPS",5)
	local vPing=card("PING",6)
	local vUp=card("UPTIME",7)
	local vVer=card("VERSION",8)
	vVer.Text=VERSION

	local function setState(lbl,on)
		lbl.Text=on and "ON" or "OFF"
		lbl.TextColor3=on and C.acc or C.offTxt
	end

	local function getPing()
		local ok,v=pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
		if ok and type(v)=="number" then return math.floor(v+0.5).." ms" end
		return "N/A"
	end

	-- 1 koneksi, update tiap 0.5 dtk, hanya saat tab Dashboard terlihat
	local frames,acc=0,0
	bind(RS.Heartbeat,function(dt)
		frames+=1
		acc+=dt
		if acc<0.5 then return end
		local fps=frames/acc
		frames,acc=0,0
		if not (pDash.Visible and main.Visible) then return end

		vFps.Text=fps>0 and tostring(math.floor(fps+0.5)) or "N/A"
		vPing.Text=getPing()
		local up=math.floor(os.clock()-START)
		vUp.Text=string.format("%02d:%02d:%02d",up//3600,(up%3600)//60,up%60)
		setState(vAuto,S.auto)
		setState(vAim,S.aim)
		setState(vFly,S.fly)
		setState(vFin,S.finish)
	end)
end

----------------------------------------------------------------
-- AUTOMATIC
----------------------------------------------------------------
toggle(pAuto,"Auto Click","Klik tepat di tengah zona hijau",true,function(v) S.auto=v setStatus(v and "Auto ON" or "Auto OFF") end)
slider(pAuto,"Latency (ms)","Naikkan jika klik telat",0,150,60,function(v) S.latency=v/1000 end)

----------------------------------------------------------------
-- AUTO AIM
----------------------------------------------------------------
local AIMKEYS={"target","sasaran","bullseye","dummy"}
local aimCache,aimT,lastShot={}, 2, 0

local ring=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0.5,0,0.5,0),
	Size=UDim2.new(0,S.aimFov*2,0,S.aimFov*2),BackgroundTransparency=1,Visible=false,Active=false},gui)
round(ring,S.aimFov)
local ringStroke=new("UIStroke",{Color=C.acc,Thickness=1.5,Transparency=0.35},ring)

local function setFov(v)
	S.aimFov=v
	ring.Size=UDim2.new(0,v*2,0,v*2)
	ring:FindFirstChildOfClass("UICorner").CornerRadius=UDim.new(0,v)
end

local function refreshAim()
	table.clear(aimCache)
	if S.aimObjects then
		for _,o in ipairs(workspace:GetDescendants()) do
			if o:IsA("BasePart") and nameHas(o,AIMKEYS) then
				local m=o:FindFirstAncestorOfClass("Model")
				if not (m and m:FindFirstChildOfClass("Humanoid")) then
					aimCache[#aimCache+1]=o
				end
			end
		end
	end
	if S.aimPlayers then
		for _,pl in ipairs(Players:GetPlayers()) do
			if pl~=lp and pl.Character then
				local h=pl.Character:FindFirstChild("Head")
				if h then aimCache[#aimCache+1]=h end
			end
		end
	end
end

local function pickTarget(cam)
	local vs=cam.ViewportSize
	local center=Vector2.new(vs.X/2,vs.Y/2)
	local best,bd=nil,S.aimFov
	for i=#aimCache,1,-1 do
		local p=aimCache[i]
		if not p.Parent then
			table.remove(aimCache,i)
		else
			local hum=p.Parent:FindFirstChildOfClass("Humanoid")
			if not (hum and hum.Health<=0) then
				local v,on=cam:WorldToViewportPoint(p.Position)
				if on then
					local d=(Vector2.new(v.X,v.Y)-center).Magnitude
					if d<bd then best,bd=p,d end
				end
			end
		end
	end
	return best,bd
end

toggle(pAim,"Auto Aim","Kamera mengunci ke target terdekat",false,function(v)
	S.aim=v
	aimT=2
	ring.Visible=v
	setStatus(v and "Aim ON" or "Aim OFF")
end)
toggle(pAim,"Auto Tembak","Aktifkan tool saat target terkunci",false,function(v) S.autoShoot=v end)
toggle(pAim,"Target Objek","Part bernama target/sasaran/bullseye",true,function(v) S.aimObjects=v aimT=2 end)
toggle(pAim,"Target Pemain","Kunci ke kepala pemain lain",false,function(v) S.aimPlayers=v aimT=2 end)
slider(pAim,"Radius FOV","Area bidik dari tengah layar",50,400,150,setFov)
slider(pAim,"Kehalusan","Makin besar makin cepat mengunci",5,100,40,function(v) S.aimSmooth=v end)

bind(RS.RenderStepped,function(dt)
	if not S.aim then return end
	aimT+=dt
	if aimT>2 then aimT=0 refreshAim() end

	local cam=workspace.CurrentCamera
	if not cam then return end
	local p,d=pickTarget(cam)
	if not p then return end

	local goal=CFrame.lookAt(cam.CFrame.Position,p.Position)
	cam.CFrame=cam.CFrame:Lerp(goal,math.clamp(S.aimSmooth/100,0.05,1))

	if S.autoShoot and d<30 and os.clock()-lastShot>0.3 then
		local tool=lp.Character and lp.Character:FindFirstChildOfClass("Tool")
		if tool then
			lastShot=os.clock()
			pcall(function() tool:Activate() end)
		end
	end
end)

----------------------------------------------------------------
-- FLY
----------------------------------------------------------------
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

----------------------------------------------------------------
-- CHECKPOINT (manual)
----------------------------------------------------------------
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

----------------------------------------------------------------
-- OBBY: AUTO FINISH
----------------------------------------------------------------
local useCP,gap,stepWait,running=true,5,0.4,false
local finishCF
local FKEYS={"finish","selesai","goal","garis"}
local CKEYS={"checkpoint","stage"}

local function numOf(o)
	return tonumber(o.Name:match("%d+")) or tonumber((o.Parent and o.Parent.Name or ""):match("%d+")) or math.huge
end

local function scanObby()
	local list,fin={},nil
	local char=lp.Character
	for _,o in ipairs(workspace:GetDescendants()) do
		if o:IsA("BasePart") and not (char and o:IsDescendantOf(char)) then
			if nameHas(o,FKEYS) then
				if not fin or o:FindFirstChildOfClass("TouchTransmitter") then fin=o end
			elseif nameHas(o,CKEYS) then
				list[#list+1]=o
			end
		end
	end
	table.sort(list,function(a,b) return numOf(a)<numOf(b) end)
	return list,fin
end

local function tpTo(part)
	local r=hrp()
	if not (r and part and part.Parent) then return false end
	r.CFrame=part.CFrame+Vector3.new(0,3,0)
	r.AssemblyLinearVelocity=Vector3.zero
	if firetouchinterest then
		pcall(function()
			firetouchinterest(r,part,0)
			firetouchinterest(r,part,1)
		end)
	end
	return true
end

local function runObby(manual)
	if running then return end
	running=true
	local list,fin=scanObby()
	local function go() return alive and (manual or S.finish) end

	if useCP then
		for i,p in ipairs(list) do
			if not go() then running=false return end
			setStatus("CP "..i.."/"..#list)
			tpTo(p)
			task.wait(stepWait)
		end
	end

	if go() then
		if finishCF then
			local r=hrp()
			if r then
				r.CFrame=finishCF
				r.AssemblyLinearVelocity=Vector3.zero
				setStatus("Ke finish (manual)")
			end
		elseif fin then
			tpTo(fin)
			setStatus("Ke finish")
		else
			setStatus("Finish tidak ketemu")
		end
	end
	running=false
end

toggle(pObby,"Auto Finish","Selesaikan obby berulang otomatis",false,function(v)
	S.finish=v
	setStatus(v and "Auto Finish ON" or "Auto Finish OFF")
end)
toggle(pObby,"Lewati Checkpoint","Kunjungi CP berurutan sebelum finish",true,function(v) useCP=v end)
slider(pObby,"Jeda Ulang (dtk)","Jarak antar putaran",2,20,5,function(v) gap=v end)
button(pObby,"Selesai Sekarang","Jalankan satu putaran","GO",function() task.spawn(runObby,true) end)
button(pObby,"Set Finish Manual","Simpan posisimu sebagai finish","SET",function()
	local r=hrp()
	if r then finishCF=r.CFrame setStatus("Finish tersimpan") end
end)
button(pObby,"Reset Finish","Kembali ke deteksi otomatis","RESET",function()
	finishCF=nil
	setStatus("Finish direset")
end)

task.spawn(function()
	while alive do
		if S.finish and not running then
			runObby(false)
			local t0=os.clock()
			while alive and S.finish and os.clock()-t0<gap do task.wait(0.2) end
		else
			task.wait(0.3)
		end
	end
end)

----------------------------------------------------------------
-- SETTINGS & UNLOAD
----------------------------------------------------------------
button(pSet,"Tutup Script","Hapus UI dan matikan semua fitur","UNLOAD",function() if _G.AWC then _G.AWC() end end)
bClose.MouseButton1Click:Connect(function() if _G.AWC then _G.AWC() end end)

_G.AWC=function()
	alive=false
	S.finish=false
	S.aim=false
	stopFly()
	for _,c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	table.clear(conns)
	table.clear(aimCache)
	gui:Destroy()
	_G.AWC=nil
end

pDash.Visible=true
tabBtns["Dashboard"].BackgroundTransparency=0
tabBtns["Dashboard"].TextColor3=C.txt

----------------------------------------------------------------
-- AUTO CLICK (minigame)
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
