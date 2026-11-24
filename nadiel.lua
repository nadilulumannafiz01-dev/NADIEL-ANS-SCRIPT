local RS=game:GetService("RunService")
local GS=game:GetService("GuiService")
local UIS=game:GetService("UserInputService")
local VIM=game:GetService("VirtualInputManager")
local Stats=game:GetService("Stats")
local Lighting=game:GetService("Lighting")
local Players=game:GetService("Players")
local lp=Players.LocalPlayer
local pg=lp:WaitForChild("PlayerGui")
if _G.AWC then pcall(_G.AWC) end

local VERSION="v1.2.0"
-- Upload gambar logo ke repo GitHub dengan nama logo.jpg, lalu pastikan link ini benar
local LOGO_URL="https://raw.githubusercontent.com/nadilulumannafiz01-dev/NADIEL-ANS-SCRIPT/main/logo.jpg"
local LOGO_FILE="nadiel_logo.jpg"
local THEME_FILE="nadiel_theme2.txt"
local START=os.clock()
local alive=true

local S={
	auto=true,latencyMs=60,clickMode=1,clickPos=50,
	aim=false,aimFov=150,aimSmooth=40,aimObjects=true,aimPlayers=false,autoShoot=false,
	collect=false,collectR=40,collectTP=false,
	fly=false,vert=0,speed=60,flyCam=true,arrows=true,
	noclip=false,infJump=false,walk=16,jump=50,walkSet=false,jumpSet=false,
	esp=false,fullbright=false,afk=false,
	finish=false,useCP=true,gap=5,
	slot=1,max=4,
	veh=false,vMax=120,vAccel=100,vForce=false,vStable=false,vInvert=false,vBtn=true,turbo=false,
	thR=190,thG=194,thB=204,
}
local cps,conns,bv={}, {}, nil
local function bind(sig,fn) local c=sig:Connect(fn) conns[#conns+1]=c return c end
local function isPress(i) return i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch end
local function isMove(i) return i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch end

----------------------------------------------------------------
-- BINDING STATE (satu state, banyak kontrol yang sinkron)
----------------------------------------------------------------
local binds={}
local function repaint(key)
	for _,f in ipairs(binds[key] or {}) do pcall(f) end
end
local function addBind(key,f)
	binds[key]=binds[key] or {}
	table.insert(binds[key],f)
	pcall(f)
end

----------------------------------------------------------------
-- TEMA
----------------------------------------------------------------
local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end
local C={
	bg=rgb(17,17,19), side=rgb(21,21,24), card=rgb(27,27,30), cardLine=rgb(44,44,49),
	box=rgb(40,40,45), txt=rgb(238,238,243), sub=rgb(148,148,158), off=rgb(62,62,69),
	line=rgb(40,40,45), acc=rgb(190,194,204),
}

pcall(function()
	if readfile and isfile and isfile(THEME_FILE) then
		local r,g,b=readfile(THEME_FILE):match("(%d+),(%d+),(%d+)")
		if r then
			S.thR,S.thG,S.thB=math.min(255,tonumber(r)),math.min(255,tonumber(g)),math.min(255,tonumber(b))
		end
	end
end)
C.acc=rgb(S.thR,S.thG,S.thB)

local themeHooks={}
local function onTheme(fn)
	themeHooks[#themeHooks+1]=fn
	pcall(fn)
end
local function accent(obj,prop)
	onTheme(function() if obj.Parent then obj[prop]=C.acc end end)
	return obj
end
local function setTheme(col,save)
	C.acc=col
	S.thR=math.floor(col.R*255+0.5)
	S.thG=math.floor(col.G*255+0.5)
	S.thB=math.floor(col.B*255+0.5)
	repaint("thR") repaint("thG") repaint("thB")
	for _,fn in ipairs(themeHooks) do pcall(fn) end
	if save and writefile then
		pcall(writefile,THEME_FILE,string.format("%d,%d,%d",S.thR,S.thG,S.thB))
	end
end

----------------------------------------------------------------
-- UTIL
----------------------------------------------------------------
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
local function hum() return lp.Character and lp.Character:FindFirstChildOfClass("Humanoid") end

local function has(n,keys)
	for _,k in ipairs(keys) do
		if n:find(k,1,true) then return true end
	end
	return false
end

local function nameHas(o,keys)
	local n=o.Name:lower()
	local pn=o.Parent and o.Parent.Name:lower() or ""
	return has(n,keys) or has(pn,keys)
end

local function posOf(o)
	if o:IsA("Model") then
		local ok,cf=pcall(function() return o:GetPivot() end)
		if ok then return cf.Position end
	elseif o:IsA("BasePart") then
		return o.Position
	elseif o:IsA("Tool") then
		local h=o:FindFirstChild("Handle")
		if h then return h.Position end
	end
	return nil
end

local function tpPos(pos)
	local r=hrp()
	if not r then return false end
	r.CFrame=CFrame.new(pos+Vector3.new(0,3,0))
	r.AssemblyLinearVelocity=Vector3.zero
	return true
end

local function touchAll(o)
	local r=hrp()
	if not (r and firetouchinterest) then return end
	local parts={}
	if o:IsA("BasePart") then
		parts[1]=o
	else
		for _,d in ipairs(o:GetDescendants()) do
			if d:IsA("BasePart") then
				parts[#parts+1]=d
				if #parts>=6 then break end
			end
		end
	end
	for _,p in ipairs(parts) do
		pcall(function()
			firetouchinterest(r,p,0)
			firetouchinterest(r,p,1)
		end)
	end
end

local function interact(o)
	local list={o}
	for _,d in ipairs(o:GetDescendants()) do list[#list+1]=d end
	if o.Parent and o.Parent~=workspace then
		for _,d in ipairs(o.Parent:GetChildren()) do list[#list+1]=d end
	end
	for _,d in ipairs(list) do
		if d:IsA("ProximityPrompt") then
			pcall(function()
				d.HoldDuration=0
				d.RequiresLineOfSight=false
				d.MaxActivationDistance=math.max(d.MaxActivationDistance,15)
			end)
			if fireproximityprompt then pcall(fireproximityprompt,d) end
		elseif d:IsA("ClickDetector") and fireclickdetector then
			pcall(fireclickdetector,d)
		end
	end
	touchAll(o)
end

local function viewport()
	local cam=workspace.CurrentCamera
	return cam and cam.ViewportSize or Vector2.new(800,400)
end
local function clampXY(x,y,w,h)
	local vs=viewport()
	return math.clamp(x,0,math.max(0,vs.X-w)),math.clamp(y,0,math.max(0,vs.Y-h))
end

-- pasang gambar logo (download sekali, simpan ke file executor)
local function applyLogo(img,fallback)
	if not (writefile and getcustomasset) then return end
	task.spawn(function()
		local fresh=false
		if LOGO_URL~="" then
			local ok,res=pcall(function() return game:HttpGet(LOGO_URL) end)
			if ok and type(res)=="string" and #res>200 then
				fresh=pcall(writefile,LOGO_FILE,res)
			end
		end
		local have=fresh or (isfile and isfile(LOGO_FILE))
		if not have then return end
		local ok2,asset=pcall(getcustomasset,LOGO_FILE)
		if ok2 and asset and alive and img.Parent then
			img.Image=asset
			if fallback then fallback.Visible=false end
		end
	end)
end

local function loadAvatar(img)
	task.spawn(function()
		local ok,content=pcall(function()
			return Players:GetUserThumbnailAsync(lp.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100)
		end)
		if ok and content and alive and img.Parent then img.Image=content end
	end)
end

----------------------------------------------------------------
-- GUI ROOT
----------------------------------------------------------------
local gui=new("ScreenGui",{Name="NadielHub",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=999})
if not pcall(function() gui.Parent=(gethui and gethui()) or game:GetService("CoreGui") end) or not gui.Parent then gui.Parent=pg end

local setStatus
local statusLbl

----------------------------------------------------------------
-- LOGIKA: AUTO AIM
----------------------------------------------------------------
local AIMKEYS={"target","sasaran","bullseye","dummy"}
local aimCache,aimT,lastShot={}, 2, 0

local ring=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0.5,0,0.5,0),
	Size=UDim2.new(0,S.aimFov*2,0,S.aimFov*2),BackgroundTransparency=1,Visible=false,Active=false},gui)
round(ring,S.aimFov)
accent(new("UIStroke",{Thickness=1.5,Transparency=0.35},ring),"Color")

local function setFov(v)
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
			local h=p.Parent:FindFirstChildOfClass("Humanoid")
			if not (h and h.Health<=0) then
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

local function onAim(v)
	aimT=2
	ring.Visible=v
	setStatus(v and "Auto Aim ON" or "Auto Aim OFF")
end

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
-- LOGIKA: AUTO COLLECT
----------------------------------------------------------------
local COLK={"coin","koin","collect","pickup","pick_up","orb","gem","cash","uang","loot"}
local colCache,colAcc,colScan,colTp={}, 0, 0, 0
local colHit=setmetatable({}, {__mode="k"})

local function refreshCollect()
	table.clear(colCache)
	local char=lp.Character
	for _,o in ipairs(workspace:GetDescendants()) do
		if (o:IsA("BasePart") or o:IsA("Model") or o:IsA("Tool")) and not (char and o:IsDescendantOf(char)) then
			if has(o.Name:lower(),COLK) then
				local skip=o:IsA("Model") and o:FindFirstChildOfClass("Humanoid")~=nil
				local a=o.Parent
				while not skip and a and a~=workspace do
					if has(a.Name:lower(),COLK) or (a:IsA("Model") and a:FindFirstChildOfClass("Humanoid")) then skip=true end
					a=a.Parent
				end
				if not skip and posOf(o) then
					colCache[#colCache+1]=o
					if #colCache>=300 then break end
				end
			end
		end
	end
end

local function onCollect(v)
	colScan=0
	setStatus(v and "Auto Collect ON" or "Auto Collect OFF")
end

bind(RS.Heartbeat,function(dt)
	if not S.collect then return end
	colAcc+=dt
	if colAcc<0.25 then return end
	colAcc=0

	local now=os.clock()
	if now-colScan>4 then
		colScan=now
		refreshCollect()
	end

	local r=hrp()
	if not r then return end
	local me=r.Position
	local done=0
	local nearest,nd=nil,math.huge

	for i=#colCache,1,-1 do
		local o=colCache[i]
		if not o.Parent then
			table.remove(colCache,i)
		else
			local p=posOf(o)
			if p then
				local d=(p-me).Magnitude
				if d<=S.collectR then
					if now-(colHit[o] or 0)>1.5 then
						colHit[o]=now
						interact(o)
						done+=1
						if done>=5 then break end
					end
				elseif d<nd and d<=300 then
					nearest,nd=o,d
				end
			end
		end
	end

	if done==0 and S.collectTP and nearest and now-colTp>1 then
		colTp=now
		local p=posOf(nearest)
		if p then tpPos(p) end
	end
end)

----------------------------------------------------------------
-- LOGIKA: FLY + PANAH NAIK/TURUN
----------------------------------------------------------------
local updateFc
local fc=new("Frame",{Size=UDim2.new(0,52,0,112),Position=UDim2.new(1,-70,0.5,-56),BackgroundTransparency=1,Visible=false},gui)
local function fcBtn(text,y)
	local b=new("TextButton",{Text=text,TextSize=20,Font=Enum.Font.GothamBold,TextColor3=C.txt,BackgroundColor3=C.side,
		Size=UDim2.new(0,52,0,52),Position=UDim2.new(0,0,0,y),AutoButtonColor=false},fc)
	round(b,26)
	accent(new("UIStroke",{Thickness=2},b),"Color")
	return b
end
local fUp=fcBtn("▲",0)
local fDn=fcBtn("▼",60)
local function holdBtn(b,v)
	b.InputBegan:Connect(function(i) if isPress(i) then S.vert=v end end)
	b.InputEnded:Connect(function(i) if isPress(i) and S.vert==v then S.vert=0 end end)
end
holdBtn(fUp,1)
holdBtn(fDn,-1)
updateFc=function() fc.Visible=S.fly and S.arrows end

local function stopFly()
	S.fly=false S.vert=0
	if bv then bv:Destroy() bv=nil end
	updateFc()
	repaint("fly")
end

local function onFly(v)
	if v then
		local r=hrp()
		if not r then
			S.fly=false
			repaint("fly")
			setStatus("Karakter belum siap")
			return
		end
		bv=new("BodyVelocity",{MaxForce=Vector3.one*1e9,Velocity=Vector3.zero},r)
		setStatus("Fly ON")
	else
		S.vert=0
		if bv then bv:Destroy() bv=nil end
		setStatus("Fly OFF")
	end
	updateFc()
end

bind(lp.CharacterAdded,function() stopFly() end)

bind(RS.Heartbeat,function()
	if not S.fly then return end
	local r=hrp()
	local h=hum()
	local cam=workspace.CurrentCamera
	if not (bv and bv.Parent and r and h and cam) then return end

	local mv=h.MoveDirection
	local vel=Vector3.zero
	if mv.Magnitude>0.01 then
		if S.flyCam then
			local look=cam.CFrame.LookVector
			local flat=Vector3.new(look.X,0,look.Z)
			if flat.Magnitude>0.01 then
				flat=flat.Unit
				local right=Vector3.new(-flat.Z,0,flat.X)
				vel=(look*mv:Dot(flat)+cam.CFrame.RightVector*mv:Dot(right))*S.speed
			else
				vel=mv*S.speed
			end
		else
			vel=mv*S.speed
		end
	end
	bv.Velocity=vel+Vector3.new(0,S.vert*S.speed,0)
end)

----------------------------------------------------------------
-- LOGIKA: PLAYER (noclip, speed, jump, infinite jump)
----------------------------------------------------------------
local ncOrig=setmetatable({}, {__mode="k"})
bind(RS.Stepped,function()
	local char=lp.Character
	if not char then return end
	if S.noclip then
		for _,p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") and p.CanCollide then
				ncOrig[p]=true
				p.CanCollide=false
			end
		end
	elseif next(ncOrig) then
		for p in pairs(ncOrig) do
			if p.Parent then p.CanCollide=true end
			ncOrig[p]=nil
		end
	end
end)

local function applyJump(h,v)
	if h.UseJumpPower then h.JumpPower=v else h.JumpHeight=(v*v)/(2*workspace.Gravity) end
end

local function onWalk(v)
	S.walkSet=(v~=16)
	local h=hum()
	if h and not S.walkSet then h.WalkSpeed=16 end
end
local function onJump(v)
	S.jumpSet=(v~=50)
	local h=hum()
	if h and not S.jumpSet then applyJump(h,50) end
end

bind(RS.Heartbeat,function()
	if not (S.walkSet or S.jumpSet) then return end
	local h=hum()
	if not h then return end
	if S.walkSet then h.WalkSpeed=S.walk end
	if S.jumpSet then applyJump(h,S.jump) end
end)

bind(UIS.JumpRequest,function()
	if not S.infJump then return end
	local h=hum()
	if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

----------------------------------------------------------------
-- LOGIKA: KENDARAAN (motor melebihi kecepatan maksimal)
----------------------------------------------------------------
local vInfo
local vOrig
local vtb=new("TextButton",{Text="TURBO",TextSize=12,Font=Enum.Font.GothamBold,TextColor3=C.txt,BackgroundColor3=C.side,
	Size=UDim2.new(0,60,0,60),Position=UDim2.new(1,-134,0.5,60),AutoButtonColor=false,Visible=false},gui)
round(vtb,30)
accent(new("UIStroke",{Thickness=2},vtb),"Color")

local turboInput
vtb.InputBegan:Connect(function(i)
	if isPress(i) then turboInput=i S.turbo=true end
end)
bind(UIS.InputEnded,function(i)
	if turboInput and (i==turboInput or (i.UserInputType==Enum.UserInputType.MouseButton1
		and turboInput.UserInputType==Enum.UserInputType.MouseButton1)) then
		turboInput=nil
		S.turbo=false
	end
end)

local function restoreSeat()
	if vOrig then
		pcall(function()
			if vOrig.seat.Parent then vOrig.seat.MaxSpeed=vOrig.max end
		end)
		vOrig=nil
	end
end

local function fwdInput(seat,h)
	if seat:IsA("VehicleSeat") and seat.Throttle~=0 then return seat.Throttle end
	if UIS:IsKeyDown(Enum.KeyCode.W) or UIS:IsKeyDown(Enum.KeyCode.Up) then return 1 end
	if h.MoveDirection.Magnitude>0.2 then return 1 end
	return 0
end

local vInfoT=0
bind(RS.Heartbeat,function(dt)
	local h=hum()
	local seat=h and h.SeatPart
	vtb.Visible=(seat~=nil) and S.vBtn
	if not seat then
		restoreSeat()
		S.turbo=false
		vInfoT+=dt
		if vInfoT>0.4 then
			vInfoT=0
			if vInfo then vInfo.Text="Tidak naik kendaraan" end
		end
		return
	end

	-- batas kecepatan bawaan VehicleSeat dinaikkan
	if seat:IsA("VehicleSeat") then
		if S.veh then
			if not vOrig or vOrig.seat~=seat then
				restoreSeat()
				vOrig={seat=seat,max=seat.MaxSpeed}
			end
			seat.MaxSpeed=S.vMax
		else
			restoreSeat()
		end
	end

	local root=seat.AssemblyRootPart or seat
	local look=seat.CFrame.LookVector*(S.vInvert and -1 or 1)
	local vel=root.AssemblyLinearVelocity
	local fs=vel:Dot(look)

	local active=S.turbo or (S.veh and fwdInput(seat,h)>0)
	if active and fs<S.vMax then
		local nfs=math.min(S.vMax,fs+S.vAccel*dt)
		if S.vForce then
			root.AssemblyLinearVelocity=Vector3.new(look.X*nfs,vel.Y,look.Z*nfs)
		else
			root.AssemblyLinearVelocity=vel+look*(nfs-fs)
		end
	end

	-- tegakkan kendaraan kalau terbalik
	if S.vStable and seat.CFrame.UpVector.Y<0.4 then
		local f=Vector3.new(look.X,0,look.Z)
		if f.Magnitude>0.01 then
			local sp=seat.Position+Vector3.new(0,2,0)
			local rel=seat.CFrame:ToObjectSpace(root.CFrame)
			root.CFrame=CFrame.lookAt(sp,sp+f)*rel
			root.AssemblyAngularVelocity=Vector3.zero
		end
	end

	vInfoT+=dt
	if vInfoT>0.4 then
		vInfoT=0
		if vInfo then vInfo.Text=string.format("%s • %d stud/s",seat.ClassName,math.floor(math.abs(fs)+0.5)) end
	end
end)

----------------------------------------------------------------
-- LOGIKA: VISUAL (ESP, fullbright) & ANTI AFK
----------------------------------------------------------------
local espObjs={}
local function clearEsp()
	for pl,h in pairs(espObjs) do
		pcall(function() h:Destroy() end)
		espObjs[pl]=nil
	end
end

local function updateEsp()
	if not S.esp then
		if next(espObjs) then clearEsp() end
		return
	end
	for pl,h in pairs(espObjs) do
		if not pl.Parent then
			pcall(function() h:Destroy() end)
			espObjs[pl]=nil
		end
	end
	for _,pl in ipairs(Players:GetPlayers()) do
		if pl~=lp and pl.Character then
			local h=espObjs[pl]
			if not (h and h.Parent==pl.Character) then
				if h then pcall(function() h:Destroy() end) end
				h=new("Highlight",{FillTransparency=0.7,OutlineTransparency=0,OutlineColor=Color3.new(1,1,1)},pl.Character)
				espObjs[pl]=h
			end
			h.FillColor=C.acc
		end
	end
end

local lightOrig
local function applyFB(v)
	if v then
		if not lightOrig then
			lightOrig={Brightness=Lighting.Brightness,ClockTime=Lighting.ClockTime,FogEnd=Lighting.FogEnd,
				GlobalShadows=Lighting.GlobalShadows,Ambient=Lighting.Ambient,OutdoorAmbient=Lighting.OutdoorAmbient}
		end
		Lighting.Brightness=2
		Lighting.ClockTime=14
		Lighting.FogEnd=1e6
		Lighting.GlobalShadows=false
		Lighting.Ambient=rgb(178,178,178)
		Lighting.OutdoorAmbient=rgb(178,178,178)
	elseif lightOrig then
		for k,val in pairs(lightOrig) do Lighting[k]=val end
		lightOrig=nil
	end
end

local tick1=0
bind(RS.Heartbeat,function(dt)
	tick1+=dt
	if tick1<1 then return end
	tick1=0
	updateEsp()
	if S.fullbright then applyFB(true) end
end)

bind(lp.Idled,function()
	if not S.afk then return end
	pcall(function()
		local vu=game:GetService("VirtualUser")
		vu:CaptureController()
		vu:ClickButton2(Vector2.new())
	end)
end)

----------------------------------------------------------------
-- LOGIKA: CHECKPOINT & TELEPORT
----------------------------------------------------------------
local function nextSlot()
	S.slot=S.slot%S.max+1
	repaint("slot")
	setStatus("Slot "..S.slot..(cps[S.slot] and " terisi" or " kosong"))
end

local function setCP()
	local r=hrp()
	if r then
		cps[S.slot]=r.CFrame
		setStatus("CP "..S.slot.." tersimpan")
	end
end

local function tpCP()
	local r=hrp()
	if not r then return end
	if not cps[S.slot] then setStatus("Slot "..S.slot.." kosong") return end
	r.CFrame=cps[S.slot]
	r.AssemblyLinearVelocity=Vector3.zero
	setStatus("TP ke "..S.slot)
	for i=1,S.max-1 do
		local s=(S.slot-1+i)%S.max+1
		if cps[s] then
			S.slot=s
			repaint("slot")
			break
		end
	end
end

local function tpSpawn()
	for _,o in ipairs(workspace:GetDescendants()) do
		if o:IsA("SpawnLocation") then
			tpPos(o.Position)
			setStatus("TP ke spawn")
			return
		end
	end
	setStatus("Spawn tidak ketemu")
end

----------------------------------------------------------------
-- LOGIKA: OBBY AUTO FINISH
----------------------------------------------------------------
local running,stepWait=false,0.4
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

	if S.useCP then
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

task.spawn(function()
	while alive do
		if S.finish and not running then
			runObby(false)
			local t0=os.clock()
			while alive and S.finish and os.clock()-t0<S.gap do task.wait(0.2) end
		else
			task.wait(0.3)
		end
	end
end)

----------------------------------------------------------------
-- WINDOW
----------------------------------------------------------------
local vs0=viewport()
local W=math.min(660,vs0.X-20)
local H=math.min(350,vs0.Y-20)
local SW=math.clamp(math.floor(W*0.23),118,150)
local RW=W-SW

local main=new("Frame",{Size=UDim2.new(0,W,0,H),Position=UDim2.new(0.5,-W/2,0.5,-H/2),BackgroundColor3=C.bg,Active=true,ClipsDescendants=true},gui)
round(main,14)
local mainStroke=new("UIStroke",{Thickness=1},main)
onTheme(function() mainStroke.Color=C.acc:Lerp(C.bg,0.82) end)

-- sidebar
local side=new("Frame",{Size=UDim2.new(0,SW,1,0),BackgroundColor3=C.side,BorderSizePixel=0},main)
label(side,"NADIEL",22,UDim2.new(0,0,0,10),UDim2.new(1,0,0,26),C.txt,Enum.Font.GothamBold,Enum.TextXAlignment.Center)
label(side,"—  THE STAR  —",9,UDim2.new(0,0,0,36),UDim2.new(1,0,0,12),C.sub,Enum.Font.GothamMedium,Enum.TextXAlignment.Center)

local tabList=new("ScrollingFrame",{Position=UDim2.new(0,8,0,58),Size=UDim2.new(1,-16,1,-158),BackgroundTransparency=1,BorderSizePixel=0,
	ScrollBarThickness=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y},side)
new("UIListLayout",{Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder},tabList)

new("Frame",{Position=UDim2.new(0,12,1,-96),Size=UDim2.new(1,-24,0,1),BackgroundColor3=C.cardLine,BorderSizePixel=0},side)
local pAv=new("ImageLabel",{Position=UDim2.new(0,12,1,-86),Size=UDim2.new(0,32,0,32),BackgroundColor3=C.box,Image=""},side)
round(pAv,16)
loadAvatar(pAv)
label(side,lp.DisplayName,12,UDim2.new(0,50,1,-86),UDim2.new(1,-56,0,16),C.txt,Enum.Font.GothamBold)
label(side,"@"..lp.Name,10,UDim2.new(0,50,1,-70),UDim2.new(1,-56,0,14),C.sub)
label(side,VERSION.." • by Nadiel",9,UDim2.new(0,0,1,-30),UDim2.new(1,0,0,14),C.sub,Enum.Font.Gotham,Enum.TextXAlignment.Center)

-- area kanan
local right=new("Frame",{Position=UDim2.new(0,SW,0,0),Size=UDim2.new(0,RW,1,0),BackgroundTransparency=1},main)

local banner=new("Frame",{Position=UDim2.new(0,8,0,8),Size=UDim2.new(1,-16,0,62),BackgroundColor3=C.card},right)
round(banner,12)
new("UIStroke",{Color=C.cardLine,Thickness=1},banner)
local bAv=new("ImageLabel",{Position=UDim2.new(0,10,0,10),Size=UDim2.new(0,42,0,42),BackgroundColor3=C.box,Image="",ScaleType=Enum.ScaleType.Crop},banner)
round(bAv,10)
loadAvatar(bAv)
label(banner,"Welcome back, "..lp.DisplayName.."!",15,UDim2.new(0,62,0,10),UDim2.new(1,-150,0,20),C.txt,Enum.Font.GothamBold)
label(banner,"Creator: Nadiel[Drewyhall9]",10,UDim2.new(0,62,0,31),UDim2.new(1,-150,0,13),C.txt,Enum.Font.GothamMedium)
label(banner,"Enjoy your script and have fun!",10,UDim2.new(0,62,0,44),UDim2.new(1,-150,0,13),C.sub)

local function headBtn(text,x)
	local b=new("TextButton",{Text=text,TextSize=15,Font=Enum.Font.GothamBold,TextColor3=C.txt,BackgroundColor3=C.box,
		Size=UDim2.new(0,28,0,28),Position=UDim2.new(1,x,0,8),AutoButtonColor=true},banner)
	round(b,8)
	return b
end
local bMin=headBtn("–",-70)
local bClose=headBtn("X",-38)

local pageArea=new("Frame",{Position=UDim2.new(0,8,0,78),Size=UDim2.new(1,-16,1,-112),BackgroundTransparency=1},right)

local footer=new("Frame",{Position=UDim2.new(0,8,1,-28),Size=UDim2.new(1,-16,0,22),BackgroundTransparency=1},right)
statusLbl=label(footer,"THE STAR  —  Trustworthy and Reliable",10,UDim2.new(0,2,0,0),UDim2.new(0.5,0,1,0),C.sub,Enum.Font.GothamMedium)
local statsLbl=label(footer,"",10,UDim2.new(0.4,0,0,0),UDim2.new(0.6,-2,1,0),C.sub,Enum.Font.Gotham,Enum.TextXAlignment.Right)
setStatus=function(t) statusLbl.Text=t end

-- drag jendela (tahan banner)
do
	local drag,ds,sp
	banner.InputBegan:Connect(function(i) if isPress(i) then drag,ds,sp=true,i.Position,main.Position end end)
	bind(UIS.InputChanged,function(i)
		if drag and isMove(i) then
			local d=i.Position-ds
			main.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
		end
	end)
	bind(UIS.InputEnded,function(i) if isPress(i) then drag=false end end)
end

-- minimize jadi logo bulat (geser, tap untuk buka)
local LS=52
local logo=new("ImageButton",{Size=UDim2.new(0,LS,0,LS),Position=UDim2.new(0,20,0,60),BackgroundColor3=C.side,Image="",
	ScaleType=Enum.ScaleType.Crop,AutoButtonColor=false,Visible=false,Active=true},gui)
round(logo,14)
accent(new("UIStroke",{Thickness=2},logo),"Color")
local logoFall=label(logo,"N",22,UDim2.new(),UDim2.new(1,0,1,0),C.acc,Enum.Font.GothamBold,Enum.TextXAlignment.Center)
accent(logoFall,"TextColor3")
applyLogo(logo,logoFall)

local function showLogo()
	local p=main.AbsolutePosition
	local x,y=clampXY(p.X,p.Y,LS,LS)
	logo.Position=UDim2.new(0,x,0,y)
	logo.Visible=true
	main.Visible=false
end
local function showMain()
	local p=logo.AbsolutePosition
	local x,y=clampXY(p.X,p.Y,W,H)
	main.Position=UDim2.new(0,x,0,y)
	main.Visible=true
	logo.Visible=false
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
			if d.Magnitude>8 then moved=true end
			if moved then
				local x,y=clampXY(sp.X.Offset+d.X,sp.Y.Offset+d.Y,LS,LS)
				logo.Position=UDim2.new(0,x,0,y)
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
local ord=0
local function nextOrd() ord+=1 return ord end

local pages,tabBtns,curTab={}, {}, nil

local function paintTabs()
	for n,b in pairs(tabBtns) do
		local on=(n==curTab)
		b.BackgroundTransparency=on and 0 or 1
		b.BackgroundColor3=C.acc:Lerp(C.bg,0.6)
		b.TextColor3=on and C.txt or C.sub
	end
end
onTheme(paintTabs)

local function selectTab(name)
	curTab=name
	for n,p in pairs(pages) do p.Visible=(n==name) end
	paintTabs()
end

local function newPage(name,order)
	local b=new("TextButton",{Text="   "..name,TextSize=13,Font=Enum.Font.GothamMedium,TextColor3=C.sub,BackgroundColor3=C.card,
		BackgroundTransparency=1,Size=UDim2.new(1,0,0,28),LayoutOrder=order,AutoButtonColor=false,
		TextXAlignment=Enum.TextXAlignment.Left},tabList)
	round(b,9)
	local p=new("ScrollingFrame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,
		CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=false},pageArea)
	accent(p,"ScrollBarImageColor3")
	new("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},p)
	new("UIPadding",{PaddingTop=UDim.new(0,2),PaddingLeft=UDim.new(0,1),PaddingRight=UDim.new(0,6),PaddingBottom=UDim.new(0,6)},p)
	pages[name],tabBtns[name]=p,b
	b.MouseButton1Click:Connect(function() selectTab(name) end)
	return p
end

local function hrow(parent)
	local f=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=nextOrd()},parent)
	new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder,
		VerticalAlignment=Enum.VerticalAlignment.Top},f)
	return f
end

local function card(parent,title,tag,width)
	local f=new("Frame",{Size=width or UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=C.card,LayoutOrder=nextOrd()},parent)
	round(f,12)
	new("UIStroke",{Color=C.cardLine,Thickness=1},f)
	new("UIPadding",{PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,4),PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)},f)
	new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder},f)
	local hd=new("Frame",{Size=UDim2.new(1,0,0,26),BackgroundTransparency=1,LayoutOrder=nextOrd()},f)
	label(hd,title,14,UDim2.new(0,0,0,0),UDim2.new(1,-70,1,0),C.txt,Enum.Font.GothamBold)
	if tag then
		local pill=new("TextLabel",{Text=tag,TextSize=10,Font=Enum.Font.GothamMedium,TextColor3=C.sub,BackgroundColor3=C.box,
			Size=UDim2.new(0,0,0,18),AutomaticSize=Enum.AutomaticSize.X,Position=UDim2.new(1,0,0.5,0),AnchorPoint=Vector2.new(1,0.5)},hd)
		round(pill,9)
		new("UIPadding",{PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)},pill)
	end
	return f
end

local function rowBase(parent,title,desc,reserve,h)
	local r=new("Frame",{Size=UDim2.new(1,0,0,h or 38),BackgroundTransparency=1,LayoutOrder=nextOrd()},parent)
	new("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.line,BorderSizePixel=0},r)
	label(r,title,13,UDim2.new(0,2,0,4),UDim2.new(1,-(reserve+4),0,16),C.txt,Enum.Font.GothamMedium)
	label(r,desc or "",10,UDim2.new(0,2,0,21),UDim2.new(1,-(reserve+4),0,13),C.sub)
	return r
end

local function tgl(parent,title,desc,key,cb)
	local r=rowBase(parent,title,desc,50)
	local sw=new("TextButton",{Size=UDim2.new(0,38,0,20),Position=UDim2.new(1,-40,0.5,-10),Text="",AutoButtonColor=false},r)
	round(sw,10)
	local kn=new("Frame",{Size=UDim2.new(0,16,0,16),BackgroundColor3=Color3.new(1,1,1)},sw)
	round(kn,8)
	local function paint()
		local on=S[key]
		sw.BackgroundColor3=on and C.acc or C.off
		kn.Position=on and UDim2.new(1,-18,0,2) or UDim2.new(0,2,0,2)
	end
	addBind(key,paint)
	onTheme(paint)
	sw.MouseButton1Click:Connect(function()
		S[key]=not S[key]
		repaint(key)
		if cb then cb(S[key]) end
	end)
end

local function sld(parent,title,desc,mn,mx,key,cb)
	local r=rowBase(parent,title,desc,122)
	local box=new("TextLabel",{Size=UDim2.new(0,34,0,20),Position=UDim2.new(1,-120,0.5,-10),BackgroundColor3=C.box,
		TextColor3=C.txt,Font=Enum.Font.GothamMedium,TextSize=11,Text=""},r)
	round(box,6)
	local bar=new("Frame",{Size=UDim2.new(0,70,0,4),Position=UDim2.new(1,-78,0.5,-2),BackgroundColor3=C.off,BorderSizePixel=0},r)
	round(bar,2)
	local fill=new("Frame",{Size=UDim2.new(0,0,1,0),BorderSizePixel=0},bar)
	accent(fill,"BackgroundColor3")
	round(fill,2)
	local knob=new("Frame",{Size=UDim2.new(0,10,0,10),AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0,0,0.5,0),
		BackgroundColor3=Color3.new(1,1,1)},bar)
	round(knob,5)
	local function paint()
		local v=S[key]
		local a=math.clamp((v-mn)/(mx-mn),0,1)
		fill.Size=UDim2.new(a,0,1,0)
		knob.Position=UDim2.new(a,0,0.5,0)
		box.Text=tostring(v)
	end
	addBind(key,paint)
	local hit=new("TextButton",{Size=UDim2.new(1,14,0,28),Position=UDim2.new(0,-7,0.5,-14),BackgroundTransparency=1,Text=""},bar)
	local drag=false
	local function set(x)
		local a=math.clamp((x-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
		local v=math.floor(mn+(mx-mn)*a+0.5)
		S[key]=v
		repaint(key)
		if cb then cb(v) end
	end
	hit.InputBegan:Connect(function(i) if isPress(i) then drag=true set(i.Position.X) end end)
	bind(UIS.InputChanged,function(i) if drag and isMove(i) then set(i.Position.X) end end)
	bind(UIS.InputEnded,function(i) if isPress(i) then drag=false end end)
end

local function btn(parent,title,desc,text,cb)
	local r=rowBase(parent,title,desc,72)
	local b=new("TextButton",{Text=text,TextSize=11,Font=Enum.Font.GothamBold,TextColor3=C.txt,BackgroundColor3=C.box,
		Size=UDim2.new(0,64,0,24),Position=UDim2.new(1,-66,0.5,-12),AutoButtonColor=true},r)
	round(b,7)
	b.MouseButton1Click:Connect(function() cb(b) end)
	return b
end

local function txt(parent,title,desc,cb)
	local r=rowBase(parent,title,desc,96)
	local tb=new("TextBox",{Text="",PlaceholderText="kata kunci",TextSize=11,Font=Enum.Font.Gotham,TextColor3=C.txt,
		PlaceholderColor3=C.sub,BackgroundColor3=C.box,ClearTextOnFocus=false,Size=UDim2.new(0,90,0,24),
		Position=UDim2.new(1,-92,0.5,-12)},r)
	round(tb,7)
	tb.FocusLost:Connect(function()
		local t=tb.Text:lower():gsub("^%s+",""):gsub("%s+$","")
		if #t>0 then cb(t) tb.Text="" setStatus("Ditambah: "..t) end
	end)
end

local function holdRow(parent,title,desc)
	local r=rowBase(parent,title,desc,128)
	local function hb(text,x,v)
		local b=new("TextButton",{Text=text,TextSize=11,Font=Enum.Font.GothamBold,TextColor3=C.txt,BackgroundColor3=C.box,
			Size=UDim2.new(0,58,0,24),Position=UDim2.new(1,x,0.5,-12),AutoButtonColor=true},r)
		round(b,7)
		b.InputBegan:Connect(function(i) if isPress(i) then S.vert=v end end)
		b.InputEnded:Connect(function(i) if isPress(i) and S.vert==v then S.vert=0 end end)
	end
	hb("NAIK",-126,1)
	hb("TURUN",-66,-1)
end

local function infoRow(parent,title,value)
	local r=new("Frame",{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,LayoutOrder=nextOrd()},parent)
	new("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.line,BorderSizePixel=0},r)
	label(r,title,12,UDim2.new(0,2,0,0),UDim2.new(0.4,0,1,0),C.txt,Enum.Font.GothamMedium)
	return label(r,value,11,UDim2.new(0.4,0,0,0),UDim2.new(0.6,-2,1,0),C.sub,Enum.Font.Gotham,Enum.TextXAlignment.Right)
end

----------------------------------------------------------------
-- HALAMAN
----------------------------------------------------------------
local pHome=newPage("Home",1)
local pMain=newPage("Main",2)
local pPlayer=newPage("Player",3)
local pVis=newPage("Visual",4)
local pMisc=newPage("Misc",5)

local HALF=UDim2.new(0.5,-4,0,0)
local THIRD=UDim2.new(1/3,-6,0,0)

local function slotBtn(parent)
	local b=btn(parent,"Slot Aktif","Pilih slot checkpoint","Slot 1",function() nextSlot() end)
	addBind("slot",function() b.Text="Slot "..S.slot end)
end

-- ===== HOME =====
do
	local r1=hrow(pHome)
	local cm=card(r1,"Main Features","Essential",HALF)
	tgl(cm,"Auto Click","Klik zona hijau otomatis","auto",function(v) setStatus(v and "Auto Click ON" or "Auto Click OFF") end)
	tgl(cm,"Auto Collect","Ambil item otomatis","collect",onCollect)
	tgl(cm,"Auto Aim","Kunci kamera ke target","aim",onAim)

	local cp=card(r1,"Player Settings","Player",HALF)
	sld(cp,"Walk Speed","Atur kecepatan berjalan",16,200,"walk",onWalk)
	sld(cp,"Jump Power","Atur tinggi lompatan",50,300,"jump",onJump)
	tgl(cp,"Noclip","Lewati tembok & objek","noclip",function(v) setStatus(v and "Noclip ON" or "Noclip OFF") end)

	local r2=hrow(pHome)
	local ct=card(r2,"Teleport","Location",THIRD)
	slotBtn(ct)
	btn(ct,"Simpan CP","Simpan posisi","SET",function() setCP() end)
	btn(ct,"Teleport CP","Pindah ke slot","TP",function() tpCP() end)

	local cv=card(r2,"Visual","ESP",THIRD)
	tgl(cv,"ESP Player","Lihat pemain lain","esp",function(v) updateEsp() setStatus(v and "ESP ON" or "ESP OFF") end)
	tgl(cv,"Fullbright","Mode terang total","fullbright",function(v) applyFB(v) end)

	local cx=card(r2,"Misc","Other",THIRD)
	tgl(cx,"Anti AFK","Cegah keluar saat AFK","afk")
	tgl(cx,"Infinite Jump","Lompat tanpa batas","infJump",function(v) setStatus(v and "Infinite Jump ON" or "Infinite Jump OFF") end)
	tgl(cx,"Fly","Terbang + panah naik/turun","fly",onFly)
end

-- ===== MAIN =====
do
	local ca=card(pMain,"Auto Clicker","Minigame")
	tgl(ca,"Auto Click","Klik tepat di zona hijau","auto",function(v) setStatus(v and "Auto Click ON" or "Auto Click OFF") end)
	sld(ca,"Latency (ms)","Naikkan jika klik telat",0,150,"latencyMs")
	sld(ca,"Titik Klik (%)","50 = tengah zona",10,90,"clickPos")
	btn(ca,"Mode Klik","Ganti jika klik meleset","+Inset",function(b)
		S.clickMode=S.clickMode%5+1
		b.Text=({"+Inset","Auto","Tanpa","Panel","Layar"})[S.clickMode]
		setStatus("Mode klik: "..b.Text)
	end)
	_G.NADIEL_DBG=infoRow(ca,"Status Deteksi","-")

	local cq=card(pMain,"Auto Aim","Target")
	tgl(cq,"Auto Aim","Kamera mengunci ke target","aim",onAim)
	tgl(cq,"Auto Tembak","Aktifkan tool saat terkunci","autoShoot")
	tgl(cq,"Target Objek","Part target/sasaran/bullseye","aimObjects",function() aimT=2 end)
	tgl(cq,"Target Pemain","Kunci ke kepala pemain","aimPlayers",function() aimT=2 end)
	sld(cq,"Radius FOV","Area bidik dari tengah",50,400,"aimFov",setFov)
	sld(cq,"Kehalusan","Makin besar makin cepat",5,100,"aimSmooth")

	local cc=card(pMain,"Auto Collect","Item")
	tgl(cc,"Auto Collect","Ambil item di sekitar","collect",onCollect)
	sld(cc,"Jangkauan (stud)","Jarak maksimal ambil",10,200,"collectR")
	tgl(cc,"Teleport ke Item","Pindah ke item terdekat","collectTP")
	txt(cc,"Kata Kunci Item","Contoh: bintang",function(t) table.insert(COLK,t) colScan=0 end)
	btn(cc,"Scan Ulang","Cari ulang item","SCAN",function()
		task.spawn(function()
			refreshCollect()
			setStatus("Item: "..#colCache)
		end)
	end)

	local cvh=card(pMain,"Vehicle Control","Speed")
	tgl(cvh,"Auto Boost","Tambah kecepatan saat gas","veh",function(v) setStatus(v and "Auto Boost ON" or "Auto Boost OFF") end)
	sld(cvh,"Kecepatan Maks","Batas kecepatan baru (stud/s)",50,500,"vMax")
	sld(cvh,"Akselerasi","Seberapa cepat kecepatan naik",20,400,"vAccel")
	tgl(cvh,"Mode Kuat","Paksa kecepatan jika boost tak terasa","vForce")
	tgl(cvh,"Anti Terbalik","Tegakkan kendaraan saat jatuh","vStable")
	tgl(cvh,"Balik Arah","Aktifkan jika boost malah mundur","vInvert")
	tgl(cvh,"Tombol Turbo","Tombol di layar saat naik kendaraan","vBtn")
	vInfo=infoRow(cvh,"Status","Tidak naik kendaraan")

	local ccp=card(pMain,"Checkpoint","Location")
	slotBtn(ccp)
	btn(ccp,"Simpan Posisi","Simpan lokasi ke slot aktif","SET CP",function() setCP() end)
	btn(ccp,"Teleport","Otomatis lanjut ke CP berikutnya","TP CP",function() tpCP() end)

	local co=card(pMain,"Obby","Auto Finish")
	tgl(co,"Auto Finish","Selesaikan obby berulang","finish",function(v) setStatus(v and "Auto Finish ON" or "Auto Finish OFF") end)
	tgl(co,"Lewati Checkpoint","Kunjungi CP berurutan","useCP")
	sld(co,"Jeda Ulang (dtk)","Jarak antar putaran",2,20,"gap")
	btn(co,"Selesai Sekarang","Jalankan satu putaran","GO",function() task.spawn(runObby,true) end)
	btn(co,"Set Finish Manual","Simpan posisimu","SET",function()
		local r=hrp()
		if r then finishCF=r.CFrame setStatus("Finish tersimpan") end
	end)
	btn(co,"Reset Finish","Kembali ke deteksi otomatis","RESET",function()
		finishCF=nil
		setStatus("Finish direset")
	end)
end

-- ===== PLAYER =====
do
	local cp=card(pPlayer,"Player Settings","Player")
	sld(cp,"Walk Speed","Atur kecepatan berjalan",16,200,"walk",onWalk)
	sld(cp,"Jump Power","Atur tinggi lompatan",50,300,"jump",onJump)
	tgl(cp,"Noclip","Lewati tembok & objek","noclip",function(v) setStatus(v and "Noclip ON" or "Noclip OFF") end)
	tgl(cp,"Infinite Jump","Lompat tanpa batas","infJump",function(v) setStatus(v and "Infinite Jump ON" or "Infinite Jump OFF") end)
	tgl(cp,"Anti AFK","Cegah keluar saat AFK","afk",function(v) setStatus(v and "Anti AFK ON" or "Anti AFK OFF") end)

	local cf=card(pPlayer,"Fly","Movement")
	tgl(cf,"Fly","Panah naik/turun muncul otomatis","fly",onFly)
	sld(cf,"Fly Speed","Kecepatan terbang",10,300,"speed")
	tgl(cf,"Arah Kamera","Terbang ke arah pandangan","flyCam")
	tgl(cf,"Panah Naik/Turun","Tampil saat Fly ON","arrows",function() updateFc() end)
	holdRow(cf,"Naik / Turun","Tahan tombol")

	local cpl=card(pPlayer,"Teleport to Player","Players")
	local rebuildPlayers
	btn(cpl,"Refresh Daftar","Muat ulang daftar pemain","SCAN",function() rebuildPlayers() end)
	btn(cpl,"Spawn","Teleport ke spawn","TP",function() tpSpawn() end)
	local plHolder=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=nextOrd()},cpl)
	new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder},plHolder)

	rebuildPlayers=function()
		for _,c in ipairs(plHolder:GetChildren()) do
			if not c:IsA("UIListLayout") then c:Destroy() end
		end
		local n=0
		for _,pl in ipairs(Players:GetPlayers()) do
			if pl~=lp then
				n+=1
				btn(plHolder,pl.DisplayName,"@"..pl.Name,"TP",function()
					local root=pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
					local me=hrp()
					if root and me then
						me.CFrame=root.CFrame*CFrame.new(0,2,4)
						me.AssemblyLinearVelocity=Vector3.zero
						setStatus("TP ke "..pl.DisplayName)
					else
						setStatus("Pemain tidak ditemukan")
					end
				end)
			end
		end
		if n==0 then
			local l=label(plHolder,"Tidak ada pemain lain di server.",11,UDim2.new(),UDim2.new(1,0,0,30),C.sub)
			l.LayoutOrder=nextOrd()
		end
	end
	rebuildPlayers()
	bind(Players.PlayerAdded,function() task.wait(0.5) rebuildPlayers() end)
	bind(Players.PlayerRemoving,function() task.defer(rebuildPlayers) end)
end

-- ===== VISUAL =====
do
	local cv=card(pVis,"Visual","ESP")
	tgl(cv,"ESP Player","Sorot pemain lain","esp",function(v) updateEsp() setStatus(v and "ESP ON" or "ESP OFF") end)
	tgl(cv,"Fullbright","Mode terang total","fullbright",function(v) applyFB(v) end)
end

-- ===== MISC =====
do
	local ct=card(pMisc,"Tema","Warna")
	local presets={
		{"Perak",190,194,204},{"Biru",0,140,255},{"Ungu",150,90,255},{"Merah",255,70,80},
		{"Hijau",40,200,120},{"Oranye",255,150,40},{"Pink",255,90,170},
	}
	local sr=new("Frame",{Size=UDim2.new(1,0,0,46),BackgroundTransparency=1,LayoutOrder=nextOrd()},ct)
	new("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.line,BorderSizePixel=0},sr)
	for i,pr in ipairs(presets) do
		local col=rgb(pr[2],pr[3],pr[4])
		local b=new("TextButton",{Text="",BackgroundColor3=col,Size=UDim2.new(0,30,0,30),
			Position=UDim2.new(0,2+(i-1)*38,0,9),AutoButtonColor=false},sr)
		round(b,15)
		b.MouseButton1Click:Connect(function()
			setTheme(col,true)
			setStatus("Tema: "..pr[1])
		end)
	end
	local function fromSliders() setTheme(rgb(S.thR,S.thG,S.thB),true) end
	sld(ct,"Merah (R)","Atur warna sendiri",0,255,"thR",fromSliders)
	sld(ct,"Hijau (G)","",0,255,"thG",fromSliders)
	sld(ct,"Biru (B)","",0,255,"thB",fromSliders)
	btn(ct,"Reset Warna","Kembali ke perak","RESET",function()
		setTheme(rgb(190,194,204),true)
		setStatus("Tema direset")
	end)

	local ci=card(pMisc,"Info","About")
	infoRow(ci,"Creator","Nadiel[Drewyhall9]")
	infoRow(ci,"Pengguna",lp.DisplayName.." (@"..lp.Name..")")
	infoRow(ci,"Versi",VERSION)
	btn(ci,"Tutup Script","Hapus UI & matikan semua fitur","UNLOAD",function() if _G.AWC then _G.AWC() end end)
end

----------------------------------------------------------------
-- FOOTER STATS, CLOSE, UNLOAD
----------------------------------------------------------------
do
	local frames,acc=0,0
	bind(RS.Heartbeat,function(dt)
		frames+=1
		acc+=dt
		if acc<0.5 then return end
		local fps=frames/acc
		frames,acc=0,0
		if not main.Visible then return end
		local ping="N/A"
		local ok,v=pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
		if ok and type(v)=="number" then ping=math.floor(v+0.5).." ms" end
		local up=math.floor(os.clock()-START)
		statsLbl.Text=string.format("FPS %d  •  Ping %s  •  %02d:%02d:%02d",
			math.floor(fps+0.5),ping,up//3600,(up%3600)//60,up%60)
	end)
end

do
	local armedClose=false
	bClose.MouseButton1Click:Connect(function()
		if armedClose then
			if _G.AWC then _G.AWC() end
			return
		end
		armedClose=true
		bClose.TextColor3=rgb(255,90,90)
		setStatus("Tekan X lagi untuk tutup")
		task.delay(2,function()
			if alive and bClose.Parent then
				armedClose=false
				bClose.TextColor3=C.txt
				setStatus("THE STAR  —  Trustworthy and Reliable")
			end
		end)
	end)
end

_G.AWC=function()
	alive=false
	S.finish=false S.aim=false S.collect=false S.noclip=false S.esp=false S.fullbright=false S.infJump=false S.veh=false S.turbo=false
	stopFly()
	clearEsp()
	applyFB(false)
	restoreSeat()
	local h=hum()
	if h then
		if S.walkSet then h.WalkSpeed=16 end
		if S.jumpSet then applyJump(h,50) end
	end
	S.walkSet=false S.jumpSet=false
	for p in pairs(ncOrig) do
		if p.Parent then p.CanCollide=true end
		ncOrig[p]=nil
	end
	for _,c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	table.clear(conns)
	table.clear(aimCache)
	table.clear(colCache)
	table.clear(themeHooks)
	table.clear(binds)
	gui:Destroy()
	_G.NADIEL_DBG=nil
	_G.AWC=nil
end

selectTab("Home")

----------------------------------------------------------------
-- LOGIKA: AUTO CLICK (minigame)
----------------------------------------------------------------
local dbg=_G.NADIEL_DBG
local nd,zn,pX,pT,armed,last,t=nil,nil,nil,nil,true,0,0
local vt,dbgT,strict=0,0,true
local clicks,lastDbg=0,""
local function grn(c) return c.G>.6 and c.R<.5 and c.B<.65 and c.G>c.R+.25 end
local function wht(c) return c.R>.9 and c.G>.9 and c.B>.9 end
local function live(o) return o and o.Parent and o:IsDescendantOf(pg) and o.Visible end

-- cek benar-benar terlihat (induk tidak disembunyikan)
local function shown(o)
	if not (o and o.Parent) then return false end
	local a=o
	while a and a~=pg do
		if a:IsA("GuiObject") and not a.Visible then return false end
		if a:IsA("ScreenGui") and not a.Enabled then return false end
		a=a.Parent
	end
	return a==pg and o.AbsoluteSize.X>0 and o.AbsoluteSize.Y>0
end

-- cara utama: pasangkan jarum dan zona yang sejajar secara vertikal
local function findPair()
	local zs,ns={}, {}
	for _,o in ipairs(pg:GetDescendants()) do
		if o:IsA("Frame") and o.BackgroundTransparency<.5 and not o:IsDescendantOf(gui) then
			local sz=o.AbsoluteSize
			if sz.X>12 and sz.X<450 and sz.Y>10 and grn(o.BackgroundColor3) then
				if shown(o) then zs[#zs+1]=o end
			elseif sz.X<14 and sz.Y>14 and wht(o.BackgroundColor3) then
				if shown(o) then ns[#ns+1]=o end
			end
		end
	end
	local bn,bz,bd=nil,nil,math.huge
	for _,z in ipairs(zs) do
		local zc=z.AbsolutePosition.Y+z.AbsoluteSize.Y/2
		for _,n in ipairs(ns) do
			local nc=n.AbsolutePosition.Y+n.AbsoluteSize.Y/2
			local d=math.abs(zc-nc)
			if d<bd and d<z.AbsoluteSize.Y then bn,bz,bd=n,z,d end
		end
	end
	return bn,bz,#zs,#ns
end

-- cadangan: cara lama (frame hijau dan putih pertama yang terlihat)
local function findLegacy()
	local z,n
	for _,o in ipairs(pg:GetDescendants()) do
		if o:IsA("Frame") and o.Visible and o.BackgroundTransparency<.5 and not o:IsDescendantOf(gui) then
			local sz=o.AbsoluteSize
			if not z and grn(o.BackgroundColor3) and sz.X>20 and sz.X<450 and sz.Y>10 then z=o
			elseif not n and wht(o.BackgroundColor3) and sz.X<18 and sz.Y>14 then n=o end
		end
	end
	return n,z
end

local function setDbg(txt)
	if txt~=lastDbg then
		lastDbg=txt
		if dbg then dbg.Text=txt end
	end
end

-- mode: 1 +Inset (cara lama), 2 Auto, 3 Tanpa inset, 4 Panel, 5 Layar
local function doClick()
	local zp,zs=zn.AbsolutePosition,zn.AbsoluteSize
	local cx,cy=zp.X+zs.X/2,zp.Y+zs.Y/2
	local m=S.clickMode
	if m==4 and zn.Parent and zn.Parent:IsA("GuiObject") then
		local pa=zn.Parent
		cx=pa.AbsolutePosition.X+pa.AbsoluteSize.X/2
		cy=pa.AbsolutePosition.Y+pa.AbsoluteSize.Y/2
	end
	local inset=GS:GetGuiInset().Y
	if m==5 then
		local v=viewport()
		cx,cy=v.X*0.3,v.Y*0.55
	elseif m==1 or m==4 then
		cy+=inset
	elseif m==2 then
		local sg=zn:FindFirstAncestorOfClass("ScreenGui")
		if not (sg and sg.IgnoreGuiInset) then cy+=inset end
	end
	VIM:SendMouseButtonEvent(cx,cy,0,true,game,0)
	task.delay(0.03,function()
		pcall(function() VIM:SendMouseButtonEvent(cx,cy,0,false,game,0) end)
	end)
	clicks+=1
end

bind(RS.RenderStepped,function(dt)
	if not S.auto then return end
	if nd and not live(nd) then nd=nil pX=nil end
	if zn and not live(zn) then zn=nil end

	if not nd or not zn then
		t+=dt
		if t>.25 then
			t=0
			local n,z,zc,nc=findPair()
			strict=true
			if not (n and z) then
				n,z=findLegacy()
				strict=false
			end
			nd,zn,pX=n,z,nil
			if not (nd and zn) then setDbg("Cari Z:"..zc.." N:"..nc) end
		end
		return
	end

	-- pasangan hasil cara utama dicek ulang tiap 1 detik
	vt+=dt
	if strict and vt>1 then
		vt=0
		if not (shown(nd) and shown(zn)) then nd,zn,pX=nil,nil,nil return end
	end

	local now=os.clock()
	local x=nd.AbsolutePosition.X+nd.AbsoluteSize.X/2
	local a=x
	if pX and now>pT then a=x+(x-pX)/(now-pT)*(S.latencyMs/1000) end
	local lo,hi=math.min(pX or x,a,x),math.max(pX or x,a,x)
	pX,pT=x,now

	local l,w=zn.AbsolutePosition.X,zn.AbsoluteSize.X
	local c=l+w*S.clickPos/100
	local inZ=hi>=l and lo<=l+w
	if not inZ then armed=true end

	local crossed=lo<=c and c<=hi
	local near=math.abs(x-c)<=math.max(2,w*0.08)
	if armed and inZ and (crossed or near) and now-last>.15 then
		last=now
		armed=false
		doClick()
	end

	dbgT+=dt
	if dbgT>.2 then
		dbgT=0
		setDbg(string.format("J%d Z%d-%d k%d",math.floor(x),math.floor(l),math.floor(l+w),clicks))
	end
end)
