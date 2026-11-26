local RS=game:GetService("RunService")
local GS=game:GetService("GuiService")
local UIS=game:GetService("UserInputService")
local VIM=game:GetService("VirtualInputManager")
local Stats=game:GetService("Stats")
local Lighting=game:GetService("Lighting")
local Players=game:GetService("Players")
local TS=game:GetService("TweenService")
local lp=Players.LocalPlayer
local pg=lp:WaitForChild("PlayerGui")
if _G.AWC then pcall(_G.AWC) end

local VERSION="v1.3.5"
-- Upload gambar logo ke repo GitHub dengan nama logo.jpg, lalu pastikan link ini benar
local LOGO_URL="https://raw.githubusercontent.com/nadilulumannafiz01-dev/NADIEL-ANS-SCRIPT/main/logo.jpg"
local LOGO_FILE="nadiel_logo.jpg"
local THEME_FILE="nadiel_theme2.txt"
local START=os.clock()
local alive=true

local S={
	auto=true,latencyMs=60,autoLat=false,latOffset=20,clickGap=10,clickMode=1,clickPos=50,
	aim=false,aimSmooth=40,aimSwitch=0,aimObjects=true,aimPlayers=false,aimNpc=false,aimWall=false,autoShoot=false,
	collect=false,collectR=40,collectTP=false,
	fly=false,vert=0,speed=60,flyCam=true,arrows=true,
	noclip=false,infJump=false,walk=16,jump=50,walkSet=false,jumpSet=false,
	esp=false,espNpc=false,espName=true,espDist=true,espHp=true,espLine=false,espMax=1000,fullbright=false,afk=false,
	finish=false,useCP=true,gap=5,
	slot=1,max=4,
	veh=false,vMax=120,vAccel=100,vForce=false,vStable=false,vInvert=false,vBtn=true,turbo=false,
	thR=190,thG=194,thB=204,
	bright=false,autoSave=true,restoreOn=true,
	autoRejoin=false,autoExec=false,scriptUrl="",
	glassLvl=40,glassBlur=false,lowGfx=false,autoCP=false,cpDelay=5,cpLoop=true,
	autoSwitch=false,dumbX=-1,dumbY=-1,
}
local cps,conns,bv={}, {}, nil
local function bind(sig,fn) local c=sig:Connect(fn) conns[#conns+1]=c return c end
local function isPress(i) return i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch end
local function isMove(i) return i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch end

----------------------------------------------------------------
-- BINDING STATE (satu state, banyak kontrol yang sinkron)
----------------------------------------------------------------
local FX,CFG={ready=false,busy=false},{keys={},set={},def={}}
local binds={}
local onStateChange
local function repaint(key)
	for _,f in ipairs(binds[key] or {}) do pcall(f) end
	if onStateChange then pcall(onStateChange) end
	if CFG.set[key] then CFG.dirtyAt=os.clock() end
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

-- palet gelap & terang (semua warna dasar UI ikut berubah saat mode diganti)
FX.PAL={
	dark={bg=rgb(17,17,19),side=rgb(21,21,24),card=rgb(27,27,30),cardLine=rgb(88,88,100),
		box=rgb(40,40,45),txt=rgb(238,238,243),sub=rgb(148,148,158),off=rgb(62,62,69),line=rgb(41,41,46)},
	bright={bg=rgb(243,244,248),side=rgb(233,235,241),card=rgb(252,252,254),cardLine=rgb(254,254,255),
		box=rgb(229,231,238),txt=rgb(24,26,34),sub=rgb(102,108,122),off=rgb(196,201,212),line=rgb(226,229,236)},
}
FX.PKEYS={"bg","side","card","cardLine","box","txt","sub","off","line"}
local C={acc=rgb(190,194,204)}

-- durasi & gaya animasi
FX.EASE=TweenInfo.new(0.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
FX.HOVER=TweenInfo.new(0.12,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
FX.SLOW=TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
FX.SLIDE=TweenInfo.new(0.09,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
FX.KNOB=TweenInfo.new(0.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
FX.OPEN=TweenInfo.new(0.34,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
FX.CLOSE=TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
FX.FADEIN=TweenInfo.new(0.26,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
FX.FADEOUT=TweenInfo.new(0.18,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
FX.PAGE=TweenInfo.new(0.3,Enum.EasingStyle.Quint,Enum.EasingDirection.Out)
FX.VEIL=TweenInfo.new(0.26,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)

-- set properti: pakai tween kalau UI sudah siap, langsung kalau masih dibangun
local function setp(o,props,info)
	if FX.ready and o.Parent then
		TS:Create(o,info or FX.EASE,props):Play()
	else
		for k,v in pairs(props) do o[k]=v end
	end
end

-- efek hover / tekan untuk tombol
local function fx(b,rest)
	rest=rest or function() return C.box end
	local function to(c) setp(b,{BackgroundColor3=c},FX.HOVER) end
	b.MouseEnter:Connect(function() to(rest():Lerp(C.acc,0.16)) end)
	b.MouseLeave:Connect(function() to(rest()) end)
	b.MouseButton1Down:Connect(function() to(rest():Lerp(C.acc,0.34)) end)
	b.MouseButton1Up:Connect(function() to(rest():Lerp(C.acc,0.16)) end)
	b.InputEnded:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.Touch then
			task.delay(0.06,function() to(rest()) end)
		end
	end)
end

----------------------------------------------------------------
-- CONFIG (disimpan per game, pakai PlaceId)
----------------------------------------------------------------
CFG.dir="NADIEL"
CFG.file=CFG.dir.."/config_"..tostring(game.PlaceId)..".json"
CFG.keys={"cpDelay","cpLoop","max","lowGfx","glassLvl","glassBlur","auto","latencyMs","autoLat","latOffset","clickGap","autoRejoin","autoExec","scriptUrl","clickMode","clickPos","aim","aimSmooth","aimSwitch","aimObjects","aimPlayers","aimNpc","aimWall","autoShoot",
	"collect","collectR","collectTP","fly","speed","flyCam","arrows","noclip","infJump","walk","jump",
	"esp","espNpc","espName","espDist","espHp","espLine","espMax","fullbright","afk","finish","useCP","gap","veh","vMax","vAccel","vForce","vStable","vInvert","vBtn",
	"thR","thG","thB","bright","autoSave","restoreOn","autoSwitch","dumbX","dumbY"}
CFG.features={"lowGfx","auto","autoLat","autoRejoin","autoExec","aim","aimNpc","aimWall","autoShoot","collect","collectTP","fly","noclip","infJump","esp","espNpc","espLine","fullbright","afk","finish","veh","autoSwitch"}
CFG.status="Belum ada config"
for _,k in ipairs(CFG.keys) do
	CFG.set[k]=true
	CFG.def[k]=S[k]
end

function CFG.read()
	if not (readfile and isfile) then return nil end
	local ok,data=pcall(function()
		if not isfile(CFG.file) then return nil end
		return game:GetService("HttpService"):JSONDecode(readfile(CFG.file))
	end)
	if ok and type(data)=="table" then return data end
	return nil
end

function CFG.merge(data)
	for _,k in ipairs(CFG.keys) do
		local v=data[k]
		if v~=nil and type(v)==type(CFG.def[k]) then S[k]=v end
	end
	S.thR=math.clamp(math.floor(S.thR),0,255)
	S.thG=math.clamp(math.floor(S.thG),0,255)
	S.thB=math.clamp(math.floor(S.thB),0,255)
	S.clickMode=math.clamp(math.floor(S.clickMode),1,5)
	if not S.restoreOn then
		for _,k in ipairs(CFG.features) do S[k]=CFG.def[k] end
	end
end

function CFG.save()
	if not writefile then
		CFG.status="Executor tanpa writefile"
		if CFG.lbl then CFG.lbl.Text=CFG.status end
		return false
	end
	local t={_v=VERSION}
	for _,k in ipairs(CFG.keys) do t[k]=S[k] end
	local ok=pcall(function()
		if makefolder and isfolder and not isfolder(CFG.dir) then makefolder(CFG.dir) end
		writefile(CFG.file,game:GetService("HttpService"):JSONEncode(t))
	end)
	CFG.dirtyAt=nil
	CFG.status=ok and ("Tersimpan "..os.date("%H:%M:%S")) or "Gagal menyimpan"
	if CFG.lbl then CFG.lbl.Text=CFG.status end
	return ok
end

do
	local data=CFG.read()
	if data then
		CFG.merge(data)
		CFG.status="Config dimuat"
	else
		-- kompatibilitas: file tema lama
		pcall(function()
			if readfile and isfile and isfile(THEME_FILE) then
				local r,g,b=readfile(THEME_FILE):match("(%d+),(%d+),(%d+)")
				if r then
					S.thR,S.thG,S.thB=math.min(255,tonumber(r)),math.min(255,tonumber(g)),math.min(255,tonumber(b))
				end
			end
		end)
	end
end

----------------------------------------------------------------
-- TEMA (gelap / terang + warna aksen)
----------------------------------------------------------------
-- aksen yang terlalu pucat dipekatkan di mode terang supaya tetap terbaca
function FX.accFor(col)
	if S.bright then
		local _,s,v=col:ToHSV()
		if s<0.25 and v>0.6 then return col:Lerp(Color3.new(0,0,0),0.5) end
	end
	return col
end
function FX.cat(col)
	return S.bright and col:Lerp(Color3.new(0,0,0),0.4) or col
end
function FX.applyPalette()
	local p=S.bright and FX.PAL.bright or FX.PAL.dark
	for _,k in ipairs(FX.PKEYS) do C[k]=p[k] end
	C.acc=FX.accFor(rgb(S.thR,S.thG,S.thB))
end
FX.applyPalette()

-- daftar objek yang warnanya mengikuti palet (didaftarkan otomatis oleh new())
FX.SKIN={BackgroundColor3=true,TextColor3=true,PlaceholderColor3=true,Color=true,ImageColor3=true}
FX.skinned=setmetatable({}, {__mode="k"})
function FX.skinKey(col)
	for _,k in ipairs(FX.PKEYS) do
		if C[k]==col then return k end
	end
end
function FX.unskin(o,prop)
	local t=FX.skinned[o]
	if t then t[prop]=nil end
end

local themeHooks={}
local function onTheme(fn)
	themeHooks[#themeHooks+1]=fn
	pcall(fn)
end
local function accent(obj,prop)
	onTheme(function() if obj.Parent then setp(obj,{[prop]=C.acc},FX.SLOW) end end)
	return obj
end

-- transisi warna mulus untuk semua objek berpalet sekaligus
function FX.skinTween()
	local items={}
	for o,props in pairs(FX.skinned) do
		if o.Parent then
			for prop,key in pairs(props) do items[#items+1]={o,prop,o[prop],key} end
		end
	end
	FX.run=(FX.run or 0)+1
	local id=FX.run
	local t0=os.clock()
	task.spawn(function()
		while alive and FX.run==id do
			local a=math.min(1,(os.clock()-t0)/0.32)
			local e=1-(1-a)^3
			for _,it in ipairs(items) do
				local o=it[1]
				if o.Parent then o[it[2]]=it[3]:Lerp(C[it[4]],e) end
			end
			if a>=1 then break end
			RS.RenderStepped:Wait()
		end
	end)
end

local function setTheme(col,save)
	C.acc=FX.accFor(col)
	S.thR=math.floor(col.R*255+0.5)
	S.thG=math.floor(col.G*255+0.5)
	S.thB=math.floor(col.B*255+0.5)
	repaint("thR") repaint("thG") repaint("thB")
	for _,fn in ipairs(themeHooks) do pcall(fn) end
end

function FX.setMode(bright)
	S.bright=bright and true or false
	FX.applyPalette()
	repaint("bright")
	FX.skinTween()
	for _,fn in ipairs(themeHooks) do pcall(fn) end
end

----------------------------------------------------------------
-- UTIL
----------------------------------------------------------------
-- ===== GLASS =====
-- transparansi dasar tiap warna palet (makin kecil makin pekat)
FX.glassObjs=setmetatable({}, {__mode="k"})
FX.GLASSOFF={bg=-0.1,side=0,card=0.1,box=0.05}
function FX.glassT(key)
	local off=FX.GLASSOFF[key]
	if not off then return nil end
	local x=math.clamp(S.glassLvl,0,100)/100*0.7+0.15
	return math.clamp(x+off,0,0.95)
end
function FX.applyGlass()
	for o,key in pairs(FX.glassObjs) do
		if o.Parent then
			local t=FX.glassT(key)
			if t then o.BackgroundTransparency=t end
		end
	end
end

local function new(cls,props,parent)
	local o=Instance.new(cls)
	for k,v in pairs(props) do
		o[k]=v
		if FX.SKIN[k] and typeof(v)=="Color3" then
			local key=FX.skinKey(v)
			if key then
				local t=FX.skinned[o]
				if not t then t={} FX.skinned[o]=t end
				t[k]=key
				if k=="BackgroundColor3" and props.BackgroundTransparency==nil then
					local gt=FX.glassT(key)
					if gt then
						o.BackgroundTransparency=gt
						FX.glassObjs[o]=key
					end
				end
			end
		end
	end
	if cls=="UIStroke" and props.Transparency==nil and FX.skinned[o] and FX.skinned[o].Color=="cardLine" then
		o.Transparency=0.45
	end
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

-- state & helper tambahan disimpan di FX.aim (hindari batas 200 local)
FX.aim={npcs={},scanned=false,cur=nil,free=0,lockT=0,skip=setmetatable({}, {__mode="k"}),
	params=RaycastParams.new(),body={"Head","HumanoidRootPart","UpperTorso","Torso"}}
FX.aim.params.FilterType=Enum.RaycastFilterType.Exclude
FX.aim.params.RespectCanCollide=true

-- bagian tubuh yang dibidik (kepala, cadangan: badan)
function FX.aim.bodyPart(m)
	for _,n in ipairs(FX.aim.body) do
		local p=m:FindFirstChild(n)
		if p and p:IsA("BasePart") then return p end
	end
end

-- daftar NPC = semua Humanoid di workspace (dilacak lewat event, bukan scan ulang)
function FX.aim.scan()
	FX.aim.scanned=true
	for _,o in ipairs(workspace:GetDescendants()) do
		if o:IsA("Humanoid") then FX.aim.npcs[o]=true end
	end
end
bind(workspace.DescendantAdded,function(o)
	if o:IsA("Humanoid") then FX.aim.npcs[o]=true end
end)
bind(workspace.DescendantRemoving,function(o)
	FX.aim.npcs[o]=nil
end)

-- target masih hidup?
function FX.aim.okTarget(p)
	if not (p and p.Parent) then return false end
	local sk=FX.aim.skip[p]
	if sk then
		if sk>os.clock() then return false end
		FX.aim.skip[p]=nil
	end
	local h=p.Parent:FindFirstChildOfClass("Humanoid")
	if h and (h.Health<=0 or h:GetState()==Enum.HumanoidStateType.Dead) then return false end
	return true
end

-- jarak ke tengah layar (nil kalau di luar layar)
function FX.aim.screenDist(cam,center,p,lim)
	local v,on=cam:WorldToViewportPoint(p.Position)
	if not on then return nil end
	local d=(Vector2.new(v.X,v.Y)-center).Magnitude
	if d>lim then return nil end
	return d
end

-- cek tembok: tidak ada part solid di antara kamera dan target
function FX.aim.visible(cam,p)
	local ign={}
	if lp.Character then ign[#ign+1]=lp.Character end
	local m=p.Parent
	ign[#ign+1]=(m and m:IsA("Model")) and m or p
	FX.aim.params.FilterDescendantsInstances=ign
	local o=cam.CFrame.Position
	return workspace:Raycast(o,p.Position-o,FX.aim.params)==nil
end

local function refreshAim()
	table.clear(aimCache)
	if not S.aimObjects then return end
	for _,o in ipairs(workspace:GetDescendants()) do
		if o:IsA("BasePart") and nameHas(o,AIMKEYS) then
			local m=o:FindFirstAncestorOfClass("Model")
			if not (m and m:FindFirstChildOfClass("Humanoid")) then
				aimCache[#aimCache+1]=o
			end
		end
	end
end

local function pickTarget(cam)
	local A=FX.aim
	local vs=cam.ViewportSize
	local center=Vector2.new(vs.X/2,vs.Y/2)
	local lim=math.huge -- tanpa batas radius: pilih yang paling dekat ke tengah layar

	-- pertahankan target yang sama selama masih terlihat di layar (anti loncat-loncat)
	local cur=A.cur
	if cur and A.okTarget(cur) then
		if S.aimSwitch>0 and os.clock()-A.lockT>S.aimSwitch then
			A.skip[cur]=os.clock()+2.5 -- kelamaan di target yang sama: pindah ke yang lain
		else
			local d=A.screenDist(cam,center,cur,lim*1.25)
			if d and (not S.aimWall or A.visible(cam,cur)) then return cur,d end
		end
	end
	A.cur=nil

	local best,bd=nil,lim
	local function try(p)
		if not A.okTarget(p) then return end
		local d=A.screenDist(cam,center,p,bd)
		if d and d<bd and (not S.aimWall or A.visible(cam,p)) then best,bd=p,d end
	end

	-- 1) objek sasaran (target / bullseye / dummy)
	for i=#aimCache,1,-1 do
		local p=aimCache[i]
		if p.Parent then try(p) else table.remove(aimCache,i) end
	end
	-- 2) pemain lain
	if S.aimPlayers then
		for _,pl in ipairs(Players:GetPlayers()) do
			if pl~=lp and pl.Character then
				local p=A.bodyPart(pl.Character)
				if p then try(p) end
			end
		end
	end
	-- 3) NPC (Humanoid yang bukan pemain)
	if S.aimNpc then
		local mine=lp.Character
		for h in pairs(A.npcs) do
			local m=h.Parent
			if m and m:IsA("Model") and m~=mine and not Players:GetPlayerFromCharacter(m) then
				local p=A.bodyPart(m)
				if p then try(p) end
			end
		end
	end

	if best then A.lockT=os.clock() end
	A.cur=best
	return best,bd
end

-- lewati target sekarang, kunci ke target lain
function FX.aim.skipCur()
	local A=FX.aim
	if A.cur then A.skip[A.cur]=os.clock()+2.5 end
	A.cur=nil
	A.free=0
	setStatus("Ganti target")
end

-- kamera digeser manual = lepas kunci sebentar, lalu kunci ke target terdekat ke tengah layar
bind(UIS.InputChanged,function(i,gp)
	if gp or not S.aim then return end
	local t=i.UserInputType
	if (t==Enum.UserInputType.MouseMovement or t==Enum.UserInputType.Touch) and i.Delta.Magnitude>=4 then
		FX.aim.free=os.clock()+0.4
		FX.aim.cur=nil
	end
end)

local function onAim(v)
	aimT=2
	FX.aim.cur=nil
	setStatus(v and "Auto Aim ON" or "Auto Aim OFF")
end

-- jalan SETELAH script kamera bawaan game, supaya tidak ditimpa lagi
function FX.aim.step(dt)
	if not (S.aim and alive) then FX.aim.cur=nil return end
	if S.aimNpc and not FX.aim.scanned then FX.aim.scan() end
	if os.clock()<FX.aim.free then return end
	aimT+=dt
	if aimT>2 then aimT=0 refreshAim() end

	local cam=workspace.CurrentCamera
	if not cam then return end
	local p,d=pickTarget(cam)
	if not p then return end

	local goal=CFrame.lookAt(cam.CFrame.Position,p.Position)
	-- kehalusan dibuat independen dari FPS
	local base=math.clamp(S.aimSmooth/100,0.05,1)
	local a=base>=1 and 1 or 1-(1-base)^(dt*60)
	cam.CFrame=cam.CFrame:Lerp(goal,a)

	if S.autoShoot and d<30 and os.clock()-lastShot>0.3 then
		local tool=lp.Character and lp.Character:FindFirstChildOfClass("Tool")
		if tool then
			lastShot=os.clock()
			pcall(function() tool:Activate() end)
		end
	end
end
pcall(function() RS:UnbindFromRenderStep("NadielAim") end)
RS:BindToRenderStep("NadielAim",Enum.RenderPriority.Camera.Value+1,function(dt)
	local ok,err=pcall(FX.aim.step,dt)
	if not ok and FX.aim.lastErr~=err then FX.aim.lastErr=err warn("[NADIEL] aim: "..tostring(err)) end
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
-- state ESP disimpan di FX.esp (hindari batas 200 local)
FX.esp={items={},acc=0,npcCol=Color3.fromRGB(255,170,60)}
-- layer garis (tracer) sendiri, di belakang menu
FX.esp.gui=new("ScreenGui",{Name="NadielEsp",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=998},gui.Parent)

function FX.esp.drop(m)
	local it=FX.esp.items[m]
	if not it then return end
	for _,k in ipairs({"hl","bb","box","line"}) do
		if it[k] then pcall(function() it[k]:Destroy() end) end
	end
	FX.esp.items[m]=nil
end

local function clearEsp()
	for m in pairs(FX.esp.items) do FX.esp.drop(m) end
end

-- buat elemen ESP untuk satu target (pemain = Highlight, NPC = kotak)
function FX.esp.make(m,hum,part,kind,name)
	local E=FX.esp
	local isPl=(kind=="player")
	local col=isPl and C.acc or E.npcCol
	local it={hum=hum,part=part,kind=kind,name=name}
	if isPl then
		-- Highlight dibatasi 31 oleh Roblox, jadi hanya untuk pemain
		it.hl=new("Highlight",{FillTransparency=0.7,OutlineTransparency=0,OutlineColor=Color3.new(1,1,1),FillColor=col},m)
	else
		local ok,sz=pcall(function() return m:GetExtentsSize() end)
		it.box=new("BoxHandleAdornment",{Adornee=part,AlwaysOnTop=true,ZIndex=1,Transparency=0.72,Color3=col,
			Size=ok and sz or Vector3.new(4,5,2)},part)
	end
	it.bb=new("BillboardGui",{Adornee=part,AlwaysOnTop=true,Size=UDim2.new(0,120,0,30),
		StudsOffset=Vector3.new(0,3.6,0),MaxDistance=S.espMax,LightInfluence=0,ResetOnSpawn=false},part)
	it.lbl=new("TextLabel",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,16),Font=Enum.Font.GothamBold,TextSize=12,
		TextColor3=isPl and Color3.new(1,1,1) or E.npcCol,TextStrokeTransparency=0.35},it.bb)
	it.bar=new("Frame",{Position=UDim2.new(0.5,-30,0,20),Size=UDim2.new(0,60,0,5),BackgroundColor3=Color3.new(0,0,0),
		BackgroundTransparency=0.35,BorderSizePixel=0},it.bb)
	it.fill=new("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(80,220,110),BorderSizePixel=0},it.bar)
	it.line=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=col,BackgroundTransparency=0.25,
		BorderSizePixel=0,Visible=false},E.gui)
	E.items[m]=it
	return it
end

-- sinkronkan daftar target (dipanggil tiap 1 detik & saat toggle diubah)
local function updateEsp()
	local E=FX.esp
	if not (S.esp or S.espNpc) then
		if next(E.items) then clearEsp() end
		return
	end
	local keep={}
	local cam=workspace.CurrentCamera
	local camPos=cam and cam.CFrame.Position
	local mine=lp.Character

	if S.esp then
		for _,pl in ipairs(Players:GetPlayers()) do
			local m=pl.Character
			if pl~=lp and m then
				local hum=m:FindFirstChildOfClass("Humanoid")
				local part=m:FindFirstChild("HumanoidRootPart") or FX.aim.bodyPart(m)
				if hum and part and hum.Health>0 then
					keep[m]=true
					local it=E.items[m]
					if not (it and it.part==part and part.Parent) then
						if it then E.drop(m) end
						it=E.make(m,hum,part,"player",pl.DisplayName)
					end
					if it.hl then it.hl.FillColor=C.acc end
				end
			end
		end
	end

	if S.espNpc then
		if not FX.aim.scanned then FX.aim.scan() end
		local list={}
		for hum in pairs(FX.aim.npcs) do
			local m=hum.Parent
			if m and m:IsA("Model") and m~=mine and hum.Health>0 and not Players:GetPlayerFromCharacter(m) then
				local part=m:FindFirstChild("HumanoidRootPart") or FX.aim.bodyPart(m)
				if part then
					local d=camPos and (part.Position-camPos).Magnitude or 0
					if d<=S.espMax then list[#list+1]={m,hum,part,d} end
				end
			end
		end
		table.sort(list,function(a,b) return a[4]<b[4] end)
		for i=1,math.min(#list,60) do -- maksimal 60 NPC terdekat
			local m,hum,part=list[i][1],list[i][2],list[i][3]
			keep[m]=true
			local it=E.items[m]
			if not (it and it.part==part and part.Parent) then
				if it then E.drop(m) end
				E.make(m,hum,part,"npc",m.Name)
			end
		end
	end

	for m in pairs(E.items) do
		if not keep[m] then E.drop(m) end
	end
end

-- update tiap frame: teks jarak, health bar, garis ke target
function FX.esp.step(dt)
	local E=FX.esp
	if not (S.esp or S.espNpc) or next(E.items)==nil then return end
	local cam=workspace.CurrentCamera
	if not cam then return end
	local vs=cam.ViewportSize
	local origin=Vector2.new(vs.X/2,vs.Y)
	local camPos=cam.CFrame.Position
	E.acc+=dt
	local slow=E.acc>=0.1
	if slow then E.acc=0 end
	local mx=S.espMax
	local showLbl=S.espName or S.espDist
	for _,it in pairs(E.items) do
		local part,hum=it.part,it.hum
		if part.Parent and hum.Parent then
			local dist=(part.Position-camPos).Magnitude
			local far=dist>mx
			it.bb.Enabled=(not far) and (showLbl or S.espHp)
			it.lbl.Visible=showLbl
			it.bar.Visible=S.espHp
			if slow then
				it.bb.MaxDistance=mx
				if showLbl then
					local t=S.espName and it.name or ""
					if S.espDist then t=(t~="" and t.." " or "").."["..math.floor(dist).."m]" end
					it.lbl.Text=t
				end
			end
			if S.espHp then
				local r=math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1)
				it.fill.Size=UDim2.new(r,0,1,0)
				it.fill.BackgroundColor3=Color3.fromHSV(r*0.33,0.8,0.95)
			end
			local on=false
			if S.espLine and not far then
				local v,vis=cam:WorldToViewportPoint(part.Position)
				if vis then
					local b=Vector2.new(v.X,v.Y)
					local d=b-origin
					it.line.Size=UDim2.new(0,d.Magnitude,0,1.5)
					it.line.Position=UDim2.new(0,(origin.X+b.X)/2,0,(origin.Y+b.Y)/2)
					it.line.Rotation=math.deg(math.atan2(d.Y,d.X))
					on=true
				end
			end
			it.line.Visible=on
		end
	end
end
bind(RS.RenderStepped,function(dt)
	local ok,err=pcall(FX.esp.step,dt)
	if not ok and FX.esp.err~=err then FX.esp.err=err warn("[NADIEL] esp: "..tostring(err)) end
end)

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
		if FX.acp and FX.acp.refresh then FX.acp.refresh() end
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
-- LOGIKA: AUTO CHECKPOINT BERURUTAN (CP 1, CP 2, ... dengan jeda)
----------------------------------------------------------------
FX.acp={token=0,running=false}

-- daftar slot yang sudah terisi, mis. "1, 2, 4"
function FX.acp.refresh()
	if not FX.acp.info then return end
	local t={}
	for i=1,S.max do if cps[i] then t[#t+1]=tostring(i) end end
	FX.acp.info.Text=#t>0 and table.concat(t,", ") or "-"
end

function FX.acp.stop()
	FX.acp.token+=1
	FX.acp.running=false
end

function FX.acp.run()
	local A=FX.acp
	if A.running then return end
	A.running=true
	A.token+=1
	local tk=A.token
	local function go() return alive and S.autoCP and A.token==tk end
	task.spawn(function()
		while go() do
			local n=0
			for i=1,S.max do if cps[i] then n+=1 end end
			if n==0 then setStatus("Belum ada CP tersimpan") break end
			local idx=0
			for i=1,S.max do
				if not go() then break end
				local cf=cps[i]
				if cf then
					idx+=1
					local r=hrp()
					if r then
						r.CFrame=cf
						r.AssemblyLinearVelocity=Vector3.zero
						setStatus("Auto CP "..i.." ("..idx.."/"..n..")")
					end
					if idx==n and not S.cpLoop then break end -- CP terakhir, tidak perlu jeda
					local t0=os.clock()
					while go() and os.clock()-t0<S.cpDelay do task.wait(0.1) end
				end
			end
			if not S.cpLoop then break end
		end
		if A.token==tk then -- selesai sendiri (bukan dimatikan manual)
			A.running=false
			if S.autoCP then
				S.autoCP=false
				repaint("autoCP")
				setStatus("Auto CP selesai")
			end
		end
	end)
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
-- CONFIG: terapkan / muat / reset saat script berjalan
----------------------------------------------------------------
function CFG.apply()
	aimT=2
	colScan=0
	onWalk(S.walk)
	onJump(S.jump)
	if S.fly then
		if not bv then onFly(true) end
	elseif bv then
		onFly(false)
	end
	updateFc()
	updateEsp()
	applyFB(S.fullbright)
	if FX.applyGlass then FX.applyGlass() end
	if FX.applyBlur then FX.applyBlur() end
	if FX.lg then FX.lg.sync() end
end

function CFG.load()
	local data=CFG.read()
	if not data then
		CFG.status="Belum ada config"
		if CFG.lbl then CFG.lbl.Text=CFG.status end
		return false
	end
	CFG.merge(data)
	for _,k in ipairs(CFG.keys) do repaint(k) end
	FX.setMode(S.bright)
	setTheme(rgb(S.thR,S.thG,S.thB),false)
	CFG.apply()
	CFG.dirtyAt=nil
	CFG.status="Dimuat "..os.date("%H:%M:%S")
	if CFG.lbl then CFG.lbl.Text=CFG.status end
	return true
end

function CFG.reset()
	for _,k in ipairs(CFG.keys) do S[k]=CFG.def[k] end
	for _,k in ipairs(CFG.keys) do repaint(k) end
	FX.setMode(S.bright)
	setTheme(rgb(S.thR,S.thG,S.thB),false)
	CFG.apply()
	CFG.save()
end

-- auto simpan: tunggu perubahan berhenti sebentar, lalu tulis file
task.spawn(function()
	while alive do
		task.wait(1)
		if alive and S.autoSave and CFG.dirtyAt and os.clock()-CFG.dirtyAt>1.5 then CFG.save() end
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

FX.hasCG=pcall(function() Instance.new("CanvasGroup"):Destroy() end)
local main=new(FX.hasCG and "CanvasGroup" or "Frame",{Size=UDim2.new(0,W,0,H),AnchorPoint=Vector2.new(0.5,0.5),
	Position=UDim2.new(0.5,0,0.5,0),BackgroundColor3=C.bg,Active=true,ClipsDescendants=true},gui)
round(main,14)
FX.mainScale=new("UIScale",{Scale=0.88},main)
if FX.hasCG then main.GroupTransparency=1 end
local mainStroke=new("UIStroke",{Thickness=1},main)
onTheme(function() setp(mainStroke,{Color=C.acc:Lerp(C.bg,0.82)},FX.SLOW) end)

-- kilau kaca: pantulan diagonal lembut + garis terang di tepi atas
do
	local sheen=new("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=40},main)
	round(sheen,14)
	new("UIGradient",{Rotation=35,Transparency=NumberSequence.new({
		NumberSequenceKeypoint.new(0,0.86),NumberSequenceKeypoint.new(0.35,0.96),
		NumberSequenceKeypoint.new(0.5,0.985),NumberSequenceKeypoint.new(1,0.93)})},sheen)
	local hl=new("Frame",{Position=UDim2.new(0,16,0,0),Size=UDim2.new(1,-32,0,1),BackgroundColor3=Color3.new(1,1,1),
		BorderSizePixel=0,ZIndex=41},main)
	new("UIGradient",{Transparency=NumberSequence.new({
		NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.25,0.5),
		NumberSequenceKeypoint.new(0.75,0.5),NumberSequenceKeypoint.new(1,1)})},hl)
	mainStroke.Transparency=0.35
end

-- blur latar (opsional): kaburkan game di belakang menu saat menu terbuka
do
	local ok,bl=pcall(function()
		local b=Instance.new("BlurEffect")
		b.Name="NADIEL_Blur"
		b.Size=0
		b.Parent=Lighting
		return b
	end)
	if ok then
		FX.blur=bl
		function FX.applyBlur()
			if not FX.blur or not FX.blur.Parent then return end
			local on=alive and S.glassBlur and main.Visible
			TS:Create(FX.blur,FX.EASE,{Size=on and 16 or 0}):Play()
		end
		bind(main:GetPropertyChangedSignal("Visible"),FX.applyBlur)
	end
end

-- animasi buka/tutup jendela (fade + skala)
function FX.mainTo(tr,sc,opening)
	if FX.hasCG then
		TS:Create(main,opening and FX.FADEIN or FX.FADEOUT,{GroupTransparency=tr}):Play()
	end
	TS:Create(FX.mainScale,opening and FX.OPEN or FX.CLOSE,{Scale=sc}):Play()
end

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
		Size=UDim2.new(0,28,0,28),Position=UDim2.new(1,x,0,8),AutoButtonColor=false},banner)
	round(b,8)
	fx(b)
	return b
end
local bMin=headBtn("–",-70)
local bClose=headBtn("X",-38)

local pageArea=new("Frame",{Position=UDim2.new(0,8,0,78),Size=UDim2.new(1,-16,1,-112),BackgroundTransparency=1,ClipsDescendants=true},right)

-- tirai pemudaran + geser halus saat pindah halaman / kategori
FX.veil=new("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=C.bg,BorderSizePixel=0,ZIndex=50,Visible=false},pageArea)
FX.veilId=0
function FX.pageFade(page)
	if not FX.ready then return end
	FX.veilId+=1
	local id=FX.veilId
	FX.veil.BackgroundTransparency=FX.glassT("bg") or 0
	FX.veil.Visible=true
	local t=TS:Create(FX.veil,FX.VEIL,{BackgroundTransparency=1})
	t.Completed:Connect(function() if FX.veilId==id then FX.veil.Visible=false end end)
	t:Play()
	if page then
		page.Position=UDim2.new(0,0,0,10)
		TS:Create(page,FX.PAGE,{Position=UDim2.new(0,0,0,0)}):Play()
	end
end

local footer=new("Frame",{Position=UDim2.new(0,8,1,-28),Size=UDim2.new(1,-16,0,22),BackgroundTransparency=1},right)
statusLbl=label(footer,"THE STAR  —  Trustworthy and Reliable",10,UDim2.new(0,2,0,0),UDim2.new(0.5,0,1,0),C.sub,Enum.Font.GothamMedium)
local statsLbl=label(footer,"",10,UDim2.new(0.4,0,0,0),UDim2.new(0.6,-2,1,0),C.sub,Enum.Font.Gotham,Enum.TextXAlignment.Right)
setStatus=function(t)
	statusLbl.Text=t
	if FX.ready then
		statusLbl.TextTransparency=0.7
		TS:Create(statusLbl,FX.EASE,{TextTransparency=0}):Play()
	end
end

-- drag jendela (tahan banner) dengan gerakan halus
do
	local drag,ds,sp,cx,cy,tx,ty
	banner.InputBegan:Connect(function(i)
		if isPress(i) then
			drag,ds,sp=true,i.Position,main.Position
			cx,cy=sp.X.Offset,sp.Y.Offset
			tx,ty=cx,cy
		end
	end)
	bind(UIS.InputChanged,function(i)
		if drag and isMove(i) then
			local d=i.Position-ds
			tx,ty=sp.X.Offset+d.X,sp.Y.Offset+d.Y
		end
	end)
	bind(UIS.InputEnded,function(i) if isPress(i) then drag=false end end)
	bind(RS.RenderStepped,function(dt)
		if not cx then return end
		local a=1-math.exp(-dt*26)
		cx+=(tx-cx)*a
		cy+=(ty-cy)*a
		main.Position=UDim2.new(sp.X.Scale,cx,sp.Y.Scale,cy)
		if not drag and math.abs(tx-cx)<0.4 and math.abs(ty-cy)<0.4 then
			main.Position=UDim2.new(sp.X.Scale,tx,sp.Y.Scale,ty)
			cx=nil
		end
	end)
end

-- minimize jadi logo bulat (geser, tap untuk buka) + animasi
local LS=52
local logo=new("ImageButton",{Size=UDim2.new(0,LS,0,LS),AnchorPoint=Vector2.new(0.5,0.5),
	Position=UDim2.new(0,20+LS/2,0,60+LS/2),BackgroundColor3=C.side,Image="",
	ScaleType=Enum.ScaleType.Crop,AutoButtonColor=false,Visible=false,Active=true},gui)
round(logo,14)
FX.logoScale=new("UIScale",{Scale=0},logo)
accent(new("UIStroke",{Thickness=2},logo),"Color")
local logoFall=label(logo,"N",22,UDim2.new(),UDim2.new(1,0,1,0),C.acc,Enum.Font.GothamBold,Enum.TextXAlignment.Center)
accent(logoFall,"TextColor3")
applyLogo(logo,logoFall)

local function showLogo()
	if FX.busy then return end
	FX.busy=true
	local p=main.AbsolutePosition
	local x,y=clampXY(p.X,p.Y,LS,LS)
	logo.Position=UDim2.new(0,x+LS/2,0,y+LS/2)
	FX.mainTo(1,0.86,false)
	task.delay(0.2,function()
		if not alive then return end
		main.Visible=false
		FX.logoScale.Scale=0
		logo.Visible=true
		TS:Create(FX.logoScale,FX.OPEN,{Scale=1}):Play()
		FX.busy=false
	end)
end
local function showMain()
	if FX.busy then return end
	FX.busy=true
	local p=logo.AbsolutePosition
	local x,y=clampXY(p.X,p.Y,W,H)
	TS:Create(FX.logoScale,FX.CLOSE,{Scale=0}):Play()
	task.delay(0.12,function()
		if not alive then return end
		logo.Visible=false
		main.Position=UDim2.new(0,x+W/2,0,y+H/2)
		FX.mainScale.Scale=0.86
		if FX.hasCG then main.GroupTransparency=1 end
		main.Visible=true
		FX.mainTo(0,1,true)
		FX.busy=false
	end)
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
				local x,y=clampXY(sp.X.Offset+d.X-LS/2,sp.Y.Offset+d.Y-LS/2,LS,LS)
				logo.Position=UDim2.new(0,x+LS/2,0,y+LS/2)
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

-- tombol ON/OFF Auto Click yang menempel di logo mini
do
	local tog=new("TextButton",{Size=UDim2.new(0,24,0,24),AnchorPoint=Vector2.new(0.5,0.5),Text="AC",TextSize=10,
		Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1),AutoButtonColor=false,Visible=false,ZIndex=5,Active=true},gui)
	round(tog,12)
	local function paintTog()
		tog.BackgroundColor3=S.auto and Color3.fromRGB(60,160,80) or Color3.fromRGB(170,60,60)
	end
	addBind("auto",paintTog)
	tog.MouseButton1Click:Connect(function()
		S.auto=not S.auto
		repaint("auto")
		setStatus(S.auto and "Auto Click ON" or "Auto Click OFF")
	end)
	local nx=new("TextButton",{Size=UDim2.new(0,24,0,24),AnchorPoint=Vector2.new(0.5,0.5),Text="NX",TextSize=10,
		Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(60,100,180),
		AutoButtonColor=false,Visible=false,ZIndex=5,Active=true},gui)
	round(nx,12)
	nx.MouseButton1Click:Connect(function() FX.aim.skipCur() end)
	bind(RS.RenderStepped,function()
		local show=logo.Visible and FX.logoScale.Scale>0.6
		tog.Visible=show
		nx.Visible=show and S.aim
		if show then
			local lp0=logo.Position
			tog.Position=UDim2.new(lp0.X.Scale,lp0.X.Offset+LS/2+20,lp0.Y.Scale,lp0.Y.Offset)
			nx.Position=UDim2.new(lp0.X.Scale,lp0.X.Offset+LS/2+50,lp0.Y.Scale,lp0.Y.Offset)
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
		setp(b,{BackgroundTransparency=on and 0 or 1,BackgroundColor3=C.acc:Lerp(C.bg,0.6),
			TextColor3=on and C.txt or C.sub},FX.EASE)
	end
end
onTheme(paintTabs)

----------------------------------------------------------------
-- FEATURE CATEGORIES
----------------------------------------------------------------
local CATS={
	{id="auto",name="Automation",color=rgb(125,190,255),keys={"auto","collect","finish"}},
	{id="combat",name="Combat",color=rgb(255,125,125),keys={"aim","autoShoot"}},
	{id="move",name="Movement",color=rgb(130,220,150),keys={"fly","noclip","infJump","veh"}},
	{id="teleport",name="Teleport",color=rgb(200,160,255),keys={},note="Checkpoint • Pemain"},
	{id="visual",name="Visual",color=rgb(255,200,110),keys={"esp","espNpc","fullbright","lowGfx"}},
	{id="utility",name="Utility",color=rgb(170,176,192),keys={"afk","autoRejoin"}},
}
local CATBY={}
for _,c in ipairs(CATS) do CATBY[c.id]=c end

local catCards={}            -- kartu fitur yang terdaftar ke sebuah kategori
local curCat="all"           -- filter kategori yang sedang aktif
local chipBtns,chipName={}, {}

local chipBar=new("ScrollingFrame",{Position=UDim2.new(0,8,0,76),Size=UDim2.new(1,-16,0,26),BackgroundTransparency=1,
	BorderSizePixel=0,ScrollBarThickness=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.X,
	ScrollingDirection=Enum.ScrollingDirection.X,Visible=false},right)
new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder,
	VerticalAlignment=Enum.VerticalAlignment.Center},chipBar)

local emptyLbl=label(pageArea,"Tidak ada fitur kategori ini di menu ini.",11,UDim2.new(0,0,0,24),UDim2.new(1,0,0,20),
	C.sub,Enum.Font.Gotham,Enum.TextXAlignment.Center)
emptyLbl.Visible=false

local function refreshCats()
	if not curTab then return end
	local filterable=(curTab~="Home")
	chipBar.Visible=filterable
	pageArea.Position=UDim2.new(0,8,0,filterable and 106 or 78)
	pageArea.Size=UDim2.new(1,-16,1,filterable and -140 or -112)
	if not filterable then
		emptyLbl.Visible=false
		return
	end

	local page=pages[curTab]
	local counts={all=0}
	for _,c in ipairs(CATS) do counts[c.id]=0 end
	for _,e in ipairs(catCards) do
		if e.page==page then
			counts.all+=1
			counts[e.cat]+=1
		end
	end
	if curCat~="all" and counts[curCat]==0 then curCat="all" end

	local shown=0
	for _,e in ipairs(catCards) do
		if e.page==page then
			local vis=(curCat=="all") or (e.cat==curCat)
			e.frame.Visible=vis
			if vis then shown+=1 end
		end
	end
	emptyLbl.Visible=(shown==0)

	for id,b in pairs(chipBtns) do
		local n=counts[id] or 0
		local on=(id==curCat)
		b.Text=chipName[id].."  "..n
		setp(b,{BackgroundColor3=on and C.acc:Lerp(C.bg,0.6) or C.box,TextColor3=on and C.txt or C.sub},FX.HOVER)
		b.Visible=(id=="all") or n>0
	end
end

local function makeChip(id,name,order)
	local b=new("TextButton",{Text=name,TextSize=11,Font=Enum.Font.GothamMedium,TextColor3=C.sub,BackgroundColor3=C.box,
		Size=UDim2.new(0,0,0,24),AutomaticSize=Enum.AutomaticSize.X,LayoutOrder=order,AutoButtonColor=false},chipBar)
	round(b,12)
	FX.unskin(b,"BackgroundColor3")
	FX.unskin(b,"TextColor3")
	new("UIPadding",{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)},b)
	b.MouseEnter:Connect(function()
		if id~=curCat then setp(b,{BackgroundColor3=C.box:Lerp(C.acc,0.18)},FX.HOVER) end
	end)
	b.MouseLeave:Connect(function()
		if id~=curCat then setp(b,{BackgroundColor3=C.box},FX.HOVER) end
	end)
	b.MouseButton1Click:Connect(function()
		curCat=id
		FX.pageFade(pages[curTab])
		refreshCats()
	end)
	chipBtns[id]=b
	chipName[id]=name
end
makeChip("all","Semua",0)
for i,c in ipairs(CATS) do makeChip(c.id,c.name,i) end
onTheme(function() refreshCats() end)

local function selectTab(name,force)
	local changed=(curTab~=name)
	curTab=name
	for n,p in pairs(pages) do p.Visible=(n==name) end
	if changed or force then FX.pageFade(pages[name]) end
	paintTabs()
	refreshCats()
end

-- ringkasan kategori di Home (jumlah fitur aktif) + navigasi ke kategori
local tileSubs={}
local function updateTiles()
	for _,c in ipairs(CATS) do
		local sub=tileSubs[c.id]
		if sub then
			if #c.keys>0 then
				local a=0
				for _,k in ipairs(c.keys) do
					if S[k] then a+=1 end
				end
				sub.Text=a.."/"..#c.keys.." aktif"
				setp(sub,{TextColor3=(a>0) and C.acc or C.sub},FX.EASE)
			else
				sub.Text=c.note or "Aksi"
				setp(sub,{TextColor3=C.sub},FX.EASE)
			end
		end
	end
end
onStateChange=updateTiles
onTheme(updateTiles)

local function openCategory(id)
	for _,name in ipairs({"Main","Player","Visual","Misc"}) do
		local page=pages[name]
		for _,e in ipairs(catCards) do
			if e.page==page and e.cat==id then
				curCat=id
				selectTab(name,true)
				return
			end
		end
	end
end

local function newPage(name,order)
	local b=new("TextButton",{Text="   "..name,TextSize=13,Font=Enum.Font.GothamMedium,TextColor3=C.sub,BackgroundColor3=C.card,
		BackgroundTransparency=1,Size=UDim2.new(1,0,0,28),LayoutOrder=order,AutoButtonColor=false,
		TextXAlignment=Enum.TextXAlignment.Left},tabList)
	round(b,9)
	FX.unskin(b,"BackgroundColor3")
	FX.unskin(b,"TextColor3")
	b.MouseEnter:Connect(function()
		if curTab~=name then setp(b,{BackgroundTransparency=0.7},FX.HOVER) end
	end)
	b.MouseLeave:Connect(function()
		if curTab~=name then setp(b,{BackgroundTransparency=1},FX.HOVER) end
	end)
	local p=new("ScrollingFrame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,
		CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=false},pageArea)
	accent(p,"ScrollBarImageColor3")
	new("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},p)
	new("UIPadding",{PaddingTop=UDim.new(0,2),PaddingLeft=UDim.new(0,1),PaddingRight=UDim.new(0,6),PaddingBottom=UDim.new(0,6)},p)
	pages[name],tabBtns[name]=p,b
	b.MouseButton1Click:Connect(function()
		local reset=(curCat~="all")
		curCat="all"
		selectTab(name,reset)
	end)
	return p
end

local function hrow(parent)
	local f=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=nextOrd()},parent)
	new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder,
		VerticalAlignment=Enum.VerticalAlignment.Top},f)
	return f
end

local function card(parent,title,tag,width,cat)
	local f=new("Frame",{Size=width or UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=C.card,LayoutOrder=nextOrd()},parent)
	round(f,12)
	new("UIStroke",{Color=C.cardLine,Thickness=1},f)
	new("UIPadding",{PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,4),PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)},f)
	new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder},f)
	local info=cat and CATBY[cat]
	if info and not tag then tag=info.name end
	local hd=new("Frame",{Size=UDim2.new(1,0,0,26),BackgroundTransparency=1,LayoutOrder=nextOrd()},f)
	label(hd,title,14,UDim2.new(0,0,0,0),UDim2.new(1,-84,1,0),C.txt,Enum.Font.GothamBold)
	if tag then
		local pill=new("TextLabel",{Text=tag,TextSize=10,Font=Enum.Font.GothamMedium,TextColor3=info and FX.cat(info.color) or C.sub,
			BackgroundColor3=C.box,Size=UDim2.new(0,0,0,18),AutomaticSize=Enum.AutomaticSize.X,Position=UDim2.new(1,0,0.5,0),
			AnchorPoint=Vector2.new(1,0.5)},hd)
		round(pill,9)
		new("UIPadding",{PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)},pill)
		if info then onTheme(function() setp(pill,{TextColor3=FX.cat(info.color)},FX.SLOW) end) end
	end
	if info then catCards[#catCards+1]={frame=f,cat=cat,page=parent} end
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
		setp(sw,{BackgroundColor3=on and C.acc or C.off},FX.EASE)
		setp(kn,{Position=on and UDim2.new(1,-18,0,2) or UDim2.new(0,2,0,2)},FX.KNOB)
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
		setp(fill,{Size=UDim2.new(a,0,1,0)},FX.SLIDE)
		setp(knob,{Position=UDim2.new(a,0,0.5,0)},FX.SLIDE)
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
		Size=UDim2.new(0,64,0,24),Position=UDim2.new(1,-66,0.5,-12),AutoButtonColor=false},r)
	round(b,7)
	fx(b)
	b.MouseButton1Click:Connect(function() cb(b) end)
	return b
end

local function txt(parent,title,desc,cb)
	local r=rowBase(parent,title,desc,96)
	local tb=new("TextBox",{Text="",PlaceholderText="kata kunci",TextSize=11,Font=Enum.Font.Gotham,TextColor3=C.txt,
		PlaceholderColor3=C.sub,BackgroundColor3=C.box,ClearTextOnFocus=false,Size=UDim2.new(0,90,0,24),
		Position=UDim2.new(1,-92,0.5,-12)},r)
	round(tb,7)
	tb.Focused:Connect(function() setp(tb,{BackgroundColor3=C.box:Lerp(C.acc,0.2)},FX.HOVER) end)
	tb.FocusLost:Connect(function() setp(tb,{BackgroundColor3=C.box},FX.HOVER) end)
	tb.FocusLost:Connect(function()
		local t=tb.Text:lower():gsub("^%s+",""):gsub("%s+$","")
		if #t>0 then cb(t) tb.Text="" setStatus("Ditambah: "..t) end
	end)
end

function FX.urlRow(parent,title,desc,key)
	local r=rowBase(parent,title,desc,150)
	local tb=new("TextBox",{Text=S[key],PlaceholderText="link raw script",TextSize=11,Font=Enum.Font.Gotham,TextColor3=C.txt,
		PlaceholderColor3=C.sub,BackgroundColor3=C.box,ClearTextOnFocus=false,ClipsDescendants=true,
		TextXAlignment=Enum.TextXAlignment.Left,Size=UDim2.new(0,140,0,24),Position=UDim2.new(1,-142,0.5,-12)},r)
	round(tb,7)
	addBind(key,function() tb.Text=S[key] end)
	tb.FocusLost:Connect(function()
		local t=tb.Text:gsub("^%s+",""):gsub("%s+$","")
		S[key]=t
		tb.Text=t
		repaint(key)
		setStatus(t=="" and "Link dikosongkan" or "Link script tersimpan")
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
	local cfc=card(pHome,"Feature Categories","Navigasi")
	local tiles=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=nextOrd()},cfc)
	new("UIGridLayout",{CellSize=UDim2.new(1/3,-6,0,40),CellPadding=UDim2.new(0,6,0,6),SortOrder=Enum.SortOrder.LayoutOrder},tiles)
	new("UIPadding",{PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,6)},tiles)
	for i,c in ipairs(CATS) do
		local t=new("TextButton",{Text="",BackgroundColor3=C.box,AutoButtonColor=false,LayoutOrder=i},tiles)
		round(t,9)
		fx(t)
		local tl=label(t,c.name,12,UDim2.new(0,8,0,4),UDim2.new(1,-12,0,16),FX.cat(c.color),Enum.Font.GothamBold)
		onTheme(function() setp(tl,{TextColor3=FX.cat(c.color)},FX.SLOW) end)
		tileSubs[c.id]=label(t,"",10,UDim2.new(0,8,0,21),UDim2.new(1,-12,0,14),C.sub)
		FX.unskin(tileSubs[c.id],"TextColor3")
		t.MouseButton1Click:Connect(function() openCategory(c.id) end)
	end
	updateTiles()

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
	tgl(ct,"Auto CP","CP 1, 2, 3 otomatis + jeda","autoCP",function(v)
		if v then FX.acp.run() else FX.acp.stop() end
		setStatus(v and "Auto CP ON" or "Auto CP OFF")
	end)

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
	local ca=card(pMain,"Auto Clicker",nil,nil,"auto")
	tgl(ca,"Auto Click","Klik tepat di zona hijau","auto",function(v) setStatus(v and "Auto Click ON" or "Auto Click OFF") end)
	_G.NADIEL_SW=infoRow(ca,"Status Pindah","-")
	tgl(ca,"Auto Pindah Latihan","Pindah saat target penuh: PUSHUP > SITUP > PULLUP > JJS","autoSwitch",function(v) setStatus(v and "Auto Pindah ON" or "Auto Pindah OFF") end)
	btn(ca,"Set Tombol Dumbbell","Tekan, lalu tap logo dumbbell di game (untuk buka menu latihan)","Set",function(b)
		if FX.captureDumb then FX.captureDumb() end
	end)
	sld(ca,"Latency (ms)","Naikkan jika klik telat",0,150,"latencyMs")
	tgl(ca,"Auto Latency","Latency otomatis dari ping server","autoLat",function(v) setStatus(v and "Auto Latency ON" or "Auto Latency OFF") end)
	sld(ca,"Offset Latency (ms)","Tambahan di atas ping/2",0,100,"latOffset")
	sld(ca,"Jeda Klik Ulang (x0.1 dtk)","10 = 1 detik, siap klik lagi setelah jeda ini",3,30,"clickGap")
	sld(ca,"Titik Klik (%)","50 = tengah zona",10,90,"clickPos")
	btn(ca,"Mode Klik","Ganti jika klik meleset","+Inset",function(b)
		S.clickMode=S.clickMode%5+1
		b.Text=({"+Inset","Auto","Tanpa","Panel","Layar"})[S.clickMode]
		setStatus("Mode klik: "..b.Text)
	end)
	_G.NADIEL_DBG=infoRow(ca,"Status Deteksi","-")

	local cq=card(pMain,"Auto Aim",nil,nil,"combat")
	tgl(cq,"Auto Aim","Kamera mengunci ke target","aim",onAim)
	tgl(cq,"Auto Tembak","Aktifkan tool saat terkunci","autoShoot")
	tgl(cq,"Target Objek","Part target/sasaran/bullseye","aimObjects",function() aimT=2 end)
	tgl(cq,"Target Pemain","Kunci ke kepala pemain","aimPlayers",function() aimT=2 end)
	tgl(cq,"Target NPC","Kunci ke NPC / bot (bukan pemain)","aimNpc",function() FX.aim.cur=nil end)
	tgl(cq,"Cek Tembok","Abaikan target di balik tembok","aimWall",function() FX.aim.cur=nil end)
	sld(cq,"Kehalusan","Makin besar makin cepat",5,100,"aimSmooth")
	sld(cq,"Ganti Target Otomatis","Detik sebelum pindah target (0 = mati)",0,10,"aimSwitch")
	btn(cq,"Ganti Target","Lewati target sekarang, kunci yang lain","NEXT",function() FX.aim.skipCur() end)

	local cc=card(pMain,"Auto Collect",nil,nil,"auto")
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

	local cvh=card(pMain,"Vehicle Control",nil,nil,"move")
	tgl(cvh,"Auto Boost","Tambah kecepatan saat gas","veh",function(v) setStatus(v and "Auto Boost ON" or "Auto Boost OFF") end)
	sld(cvh,"Kecepatan Maks","Batas kecepatan baru (stud/s)",50,500,"vMax")
	sld(cvh,"Akselerasi","Seberapa cepat kecepatan naik",20,400,"vAccel")
	tgl(cvh,"Mode Kuat","Paksa kecepatan jika boost tak terasa","vForce")
	tgl(cvh,"Anti Terbalik","Tegakkan kendaraan saat jatuh","vStable")
	tgl(cvh,"Balik Arah","Aktifkan jika boost malah mundur","vInvert")
	tgl(cvh,"Tombol Turbo","Tombol di layar saat naik kendaraan","vBtn")
	vInfo=infoRow(cvh,"Status","Tidak naik kendaraan")

	local ccp=card(pMain,"Checkpoint",nil,nil,"teleport")
	slotBtn(ccp)
	btn(ccp,"Simpan Posisi","Simpan lokasi ke slot aktif","SET CP",function() setCP() end)
	btn(ccp,"Teleport","Otomatis lanjut ke CP berikutnya","TP CP",function() tpCP() end)
	btn(ccp,"Hapus Slot","Kosongkan slot aktif","DEL",function()
		cps[S.slot]=nil
		FX.acp.refresh()
		setStatus("Slot "..S.slot.." dikosongkan")
	end)
	FX.acp.info=infoRow(ccp,"Slot Terisi","-")
	FX.acp.refresh()
	sld(ccp,"Jumlah Slot","Banyak slot checkpoint",2,12,"max",function()
		if S.slot>S.max then S.slot=1 repaint("slot") end
		FX.acp.refresh()
	end)
	tgl(ccp,"Auto CP Berurutan","Teleport otomatis CP 1, 2, 3, ... dengan jeda","autoCP",function(v)
		if v then FX.acp.run() else FX.acp.stop() end
		setStatus(v and "Auto CP ON" or "Auto CP OFF")
	end)
	sld(ccp,"Jeda Antar CP (dtk)","Tunggu sebelum pindah ke CP berikutnya",1,60,"cpDelay")
	tgl(ccp,"Ulangi dari CP 1","Setelah CP terakhir, mulai lagi dari CP 1","cpLoop")

	local co=card(pMain,"Obby",nil,nil,"auto")
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
	local cp=card(pPlayer,"Player Settings",nil,nil,"move")
	sld(cp,"Walk Speed","Atur kecepatan berjalan",16,200,"walk",onWalk)
	sld(cp,"Jump Power","Atur tinggi lompatan",50,300,"jump",onJump)
	tgl(cp,"Noclip","Lewati tembok & objek","noclip",function(v) setStatus(v and "Noclip ON" or "Noclip OFF") end)
	tgl(cp,"Infinite Jump","Lompat tanpa batas","infJump",function(v) setStatus(v and "Infinite Jump ON" or "Infinite Jump OFF") end)

	local cf=card(pPlayer,"Fly",nil,nil,"move")
	tgl(cf,"Fly","Panah naik/turun muncul otomatis","fly",onFly)
	sld(cf,"Fly Speed","Kecepatan terbang",10,300,"speed")
	tgl(cf,"Arah Kamera","Terbang ke arah pandangan","flyCam")
	tgl(cf,"Panah Naik/Turun","Tampil saat Fly ON","arrows",function() updateFc() end)
	holdRow(cf,"Naik / Turun","Tahan tombol")

	local cpl=card(pPlayer,"Teleport to Player",nil,nil,"teleport")
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

	local cu=card(pPlayer,"Utility",nil,nil,"utility")
	tgl(cu,"Anti AFK","Cegah keluar saat AFK","afk",function(v) setStatus(v and "Anti AFK ON" or "Anti AFK OFF") end)
	tgl(cu,"Auto Rejoin","Masuk lagi otomatis saat disconnect","autoRejoin",function(v) setStatus(v and "Auto Rejoin ON" or "Auto Rejoin OFF") end)
	tgl(cu,"Auto Execute","Jalankan script lagi setelah pindah server","autoExec",function(v)
		if v and S.scriptUrl=="" then setStatus("Isi link script dulu") else setStatus(v and "Auto Execute ON" or "Auto Execute OFF") end
		if _G.NADIEL_QUEUE then pcall(_G.NADIEL_QUEUE) end
	end)
	FX.urlRow(cu,"Link Script","Link raw script (GitHub) untuk Auto Execute","scriptUrl")
end

-- ===== VISUAL =====
do
	local cv=card(pVis,"Visual",nil,nil,"visual")
	tgl(cv,"ESP Player","Sorot pemain lain","esp",function(v) updateEsp() setStatus(v and "ESP ON" or "ESP OFF") end)
	tgl(cv,"Fullbright","Mode terang total","fullbright",function(v) applyFB(v) end)

	local ce=card(pVis,"ESP Detail",nil,nil,"visual")
	tgl(ce,"ESP NPC","Tandai NPC (Humanoid non-pemain)","espNpc",function(v) updateEsp() setStatus(v and "ESP NPC ON" or "ESP NPC OFF") end)
	tgl(ce,"Nama","Tampilkan nama di atas target","espName")
	tgl(ce,"Jarak","Tampilkan jarak (m)","espDist")
	tgl(ce,"Health Bar","Bar darah target","espHp")
	tgl(ce,"Garis ke Target","Garis dari bawah layar ke target","espLine")
	sld(ce,"Jarak Maks ESP","Target lebih jauh disembunyikan",100,3000,"espMax",function() updateEsp() end)
end

-- ===== MISC =====
do
	local ct=card(pMisc,"Tema",nil,nil,"utility")
	tgl(ct,"Mode Terang","Ganti tampilan gelap / terang","bright",function(v)
		FX.setMode(v)
		setStatus(v and "Mode terang" or "Mode gelap")
	end)
	sld(ct,"Transparansi Kaca","Makin besar makin bening",0,100,"glassLvl",function() FX.applyGlass() end)
	tgl(ct,"Blur Latar","Kaburkan game di belakang menu","glassBlur",function() if FX.applyBlur then FX.applyBlur() end end)
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

	local cl=card(pMisc,"Performa",nil,nil,"visual")
	tgl(cl,"Low Graphics","Matikan efek, bayangan & tekstur biar FPS naik","lowGfx",function(v)
		if FX.lg then FX.lg.sync() end
		setStatus(v and "Low Graphics ON" or "Low Graphics OFF")
	end)

	local cs=card(pMisc,"Config Server","Simpan",nil,"utility")
	tgl(cs,"Auto Simpan","Simpan otomatis tiap ada perubahan","autoSave",function(v)
		CFG.save()
		setStatus(v and "Auto simpan ON" or "Auto simpan OFF")
	end)
	tgl(cs,"Pulihkan Fitur ON","Aktifkan lagi fitur yang ON saat dimuat","restoreOn")
	btn(cs,"Simpan Config","Tulis pengaturan ke file","SAVE",function()
		setStatus(CFG.save() and "Config disimpan" or "Gagal menyimpan config")
	end)
	btn(cs,"Muat Config","Ambil pengaturan tersimpan","LOAD",function()
		setStatus(CFG.load() and "Config dimuat" or "Belum ada config tersimpan")
	end)
	btn(cs,"Reset Default","Kembalikan semua pengaturan","RESET",function()
		CFG.reset()
		setStatus("Pengaturan direset")
	end)
	CFG.lbl=infoRow(cs,"Status",CFG.status)
	infoRow(cs,"File",CFG.file)

	local ci=card(pMisc,"Info",nil,nil,"utility")
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

----------------------------------------------------------------
-- LOGIKA: LOW GRAPHICS (semua perubahan disimpan, bisa dikembalikan)
----------------------------------------------------------------
FX.lg={on=false,token=0,orig=setmetatable({}, {__mode="k"}),
	eff={ParticleEmitter=true,Trail=true,Beam=true,Fire=true,Smoke=true,Sparkles=true},
	terr={WaterWaveSize=0,WaterWaveSpeed=0,WaterReflectance=0}}

-- ubah properti sambil menyimpan nilai aslinya (sekali saja)
function FX.lg.set(o,prop,val)
	local t=FX.lg.orig[o]
	if not t then t={} FX.lg.orig[o]=t end
	if t[prop]==nil then t[prop]=o[prop] end
	o[prop]=val
end

function FX.lg.apply(o)
	local L=FX.lg
	if o:IsA("Terrain") then return end
	if o:IsA("BasePart") then
		L.set(o,"CastShadow",false)
		L.set(o,"Reflectance",0)
		if o.Material~=Enum.Material.SmoothPlastic then L.set(o,"Material",Enum.Material.SmoothPlastic) end
		if o:IsA("MeshPart") then pcall(L.set,o,"RenderFidelity",Enum.RenderFidelity.Performance) end
	elseif L.eff[o.ClassName] then
		L.set(o,"Enabled",false)
	elseif o:IsA("Decal") then -- Texture juga turunan Decal
		L.set(o,"Transparency",1)
	elseif o:IsA("PostEffect") then
		if o.Name~="NADIEL_Blur" then L.set(o,"Enabled",false) end
	elseif o:IsA("Atmosphere") then
		L.set(o,"Density",0) L.set(o,"Haze",0) L.set(o,"Glare",0)
	end
end

-- proses bertahap (300 objek per frame) supaya game tidak freeze
function FX.lg.run(list)
	local L=FX.lg
	local tk=L.token
	task.spawn(function()
		for i,o in ipairs(list) do
			if L.token~=tk or not alive then return end
			pcall(L.apply,o)
			if i%300==0 then task.wait() end
		end
	end)
end

function FX.lg.enable()
	local L=FX.lg
	if L.on then return end
	L.on=true
	L.token+=1
	local t=workspace:FindFirstChildOfClass("Terrain")
	if t then
		for k,v in pairs(L.terr) do pcall(L.set,t,k,v) end
		if sethiddenproperty and gethiddenproperty then
			pcall(function()
				if L.deco==nil then L.deco=gethiddenproperty(t,"Decoration") end
				sethiddenproperty(t,"Decoration",false)
			end)
		end
	end
	pcall(function()
		local r=settings().Rendering
		if L.q==nil then L.q=r.QualityLevel end
		r.QualityLevel=Enum.QualityLevel.Level01
	end)
	L.run(workspace:GetDescendants())
	L.run(Lighting:GetDescendants())
end

function FX.lg.disable()
	local L=FX.lg
	if not L.on then return end
	L.on=false
	L.token+=1
	local list={}
	for o in pairs(L.orig) do list[#list+1]=o end
	task.spawn(function()
		for i,o in ipairs(list) do
			if L.on then return end -- dinyalakan lagi di tengah proses
			local t=L.orig[o]
			if t then
				for prop,val in pairs(t) do pcall(function() o[prop]=val end) end
				L.orig[o]=nil
			end
			if i%300==0 then task.wait() end
		end
	end)
	pcall(function()
		if L.q~=nil then settings().Rendering.QualityLevel=L.q L.q=nil end
	end)
	if L.deco~=nil and sethiddenproperty then
		local t=workspace:FindFirstChildOfClass("Terrain")
		if t then pcall(sethiddenproperty,t,"Decoration",L.deco) end
		L.deco=nil
	end
end

function FX.lg.sync()
	if S.lowGfx and alive then FX.lg.enable() else FX.lg.disable() end
end

-- objek baru (karakter, efek) ikut diturunkan kualitasnya selama aktif
bind(workspace.DescendantAdded,function(o) if FX.lg.on then pcall(FX.lg.apply,o) end end)
bind(Lighting.DescendantAdded,function(o) if FX.lg.on then pcall(FX.lg.apply,o) end end)

_G.AWC=function()
	if S.autoSave and CFG.dirtyAt then pcall(CFG.save) end
	alive=false
	if FX.lg and FX.lg.on then pcall(FX.lg.disable) end
	if FX.acp then FX.acp.stop() end
	S.finish=false S.aim=false S.collect=false S.noclip=false S.esp=false S.fullbright=false S.infJump=false S.veh=false S.turbo=false
	stopFly()
	clearEsp()
	if FX.esp and FX.esp.gui then pcall(function() FX.esp.gui:Destroy() end) end
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
	pcall(function() RS:UnbindFromRenderStep("NadielAim") end)
	table.clear(FX.aim.npcs)
	table.clear(aimCache)
	table.clear(colCache)
	table.clear(themeHooks)
	table.clear(binds)
	table.clear(catCards)
	onStateChange=nil
	if FX.blur then pcall(function() FX.blur:Destroy() end) end
	gui:Destroy()
	_G.NADIEL_DBG=nil
	_G.NADIEL_SW=nil
	_G.NADIEL_QUEUE=nil
	_G.AWC=nil
end

pcall(CFG.apply)
selectTab("Home")
FX.ready=true
FX.busy=true
FX.mainTo(0,1,true)
task.delay(0.4,function() FX.busy=false end)

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

-- ping server (dihaluskan) untuk Auto Latency
FX.ping=0
task.spawn(function()
	while alive do
		local ok,v=pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
		if ok and type(v)=="number" then
			FX.ping=(FX.ping==0) and v or (FX.ping*0.7+v*0.3)
		end
		task.wait(0.5)
	end
end)
function FX.curLat()
	if S.autoLat then return math.clamp(math.floor(FX.ping*0.5+S.latOffset+0.5),0,300) end
	return S.latencyMs
end

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
			if sz.X>4 and sz.X<450 and sz.Y>10 and grn(o.BackgroundColor3) then
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
			if not z and grn(o.BackgroundColor3) and sz.X>8 and sz.X<450 and sz.Y>10 then z=o
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

FX.ac={fresh=false}
FX.clickStep=function(dt)
	if not S.auto then setDbg("Auto Click OFF") return end
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
			if nd and zn then armed=true FX.ac.fresh=true FX.ac.zl=nil end
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
	local nw=nd.AbsoluteSize.X
	local x=nd.AbsolutePosition.X+nw/2
	local l,w=zn.AbsolutePosition.X,zn.AbsoluteSize.X
	local A=FX.ac

	-- batas gerak jarum (dari bar induk zona), supaya prediksi tidak keluar dari bar
	local bl,br
	local bar=zn.Parent
	if bar and bar:IsA("GuiObject") and bar.AbsoluteSize.X>w*1.2 then
		local b0=bar.AbsolutePosition.X
		local b1=b0+bar.AbsoluteSize.X
		if x>=b0-6 and x<=b1+6 and b1-b0>nw*2 then bl,br=b0+nw/2,b1-nw/2 end
	end

	-- REP baru: zona pindah / jarum melompat -> siap klik lagi
	if A.zl and (math.abs(l-A.zl)>3 or math.abs(w-A.zw)>3) then armed=true end
	A.zl,A.zw=l,w
	if pX and math.abs(x-pX)>(bl and (br-bl)*0.4 or 150) then armed=true pX=nil end
	-- lama tidak klik (mis. jarum selalu mulai di dalam zona di ujung) -> siap lagi
	if not armed and now-last>S.clickGap/10 then armed=true end

	local a=x
	local wl,wr
	if pX and now>pT then
		a=x+(x-pX)/(now-pT)*(FX.curLat()/1000)
		if bl then -- pantul di ujung bar
			if a<bl then a=bl+(bl-a) wl=bl
			elseif a>br then a=br-(a-br) wr=br end
			a=math.clamp(a,bl,br)
		end
	end
	local lo,hi=math.min(pX or x,a,x),math.max(pX or x,a,x)
	if wl then lo=math.min(lo,wl) end
	if wr then hi=math.max(hi,wr) end
	pX,pT=x,now

	-- zona efektif dipotong batas gerak jarum (zona yang menempel di ujung kiri/kanan)
	local zl,zr=l,l+w
	if bl then
		local el,er=math.max(zl,bl),math.min(zr,br)
		if el<=er then zl,zr=el,er end
	end
	local c=zl+(zr-zl)*S.clickPos/100
	local inZ=hi>=zl and lo<=zr
	if not inZ then armed=true end
	local inside=(x>=zl and x<=zr)

	local fired=false
	if A.fresh then
		A.fresh=false
		if armed and inside and now-last>.15 then -- jarum sudah di dalam zona saat pertama terlihat
			last=now
			armed=false
			fired=true
			doClick()
		end
	end

	local crossed=lo<=c and c<=hi
	local near=math.abs(x-c)<=math.max(2,(zr-zl)*0.08)
	if not fired and armed and inZ and (crossed or near) and now-last>.15 then
		last=now
		armed=false
		doClick()
	end

	dbgT+=dt
	if dbgT>.2 then
		dbgT=0
		setDbg(string.format("J%d Z%d-%d k%d L%d",math.floor(x),math.floor(l),math.floor(l+w),clicks,FX.curLat()))
	end
end
bind(RS.RenderStepped,function(dt)
	local ok,e=pcall(FX.clickStep,dt)
	if not ok then setDbg("Err: "..tostring(e):sub(1,70)) end
end)


----------------------------------------------------------------
-- LOGIKA: AUTO PINDAH LATIHAN (PUSHUP > SITUP > PULLUP > JJS)
-- alur: latihan penuh > SELESAI > logo dumbbell > pilih latihan berikutnya
----------------------------------------------------------------
;(function()
	local ORDER={"PUSHUP","SITUP","PULLUP","JJS"}
	local ALIAS={PUSHUP="PUSHUP",PUSHUPS="PUSHUP",SITUP="SITUP",SITUPS="SITUP",PULLUP="PULLUP",PULLUPS="PULLUP",
		JJS="JJS",JJ="JJS",JUMPINGJACK="JJS",JUMPINGJACKS="JJS",SELESAI="SELESAI"}
	local lastSw,lastDumb=0,0
	local activeEx,prev=nil,{}
	local sw=_G.NADIEL_SW

	local function norm(t)
		t=tostring(t or ""):gsub("<[^>]->",""):upper():gsub("[%s%p]","")
		return ALIAS[t]
	end
	local function parseCount(t)
		t=tostring(t or ""):gsub("<[^>]->","")
		local a,b=t:match("^%s*([%d%.,]+)%s*/%s*([%d%.,]+)[^%d]*$")
		if not a then return nil end
		a=tonumber((a:gsub("[%.,]","")))
		b=tonumber((b:gsub("[%.,]","")))
		if a and b and b>0 then return a,b end
	end

	local function readProgress()
		local counts,names={}, {}
		for _,o in ipairs(pg:GetDescendants()) do
			if (o:IsA("TextLabel") or o:IsA("TextButton")) and not o:IsDescendantOf(gui) then
				local a,b=parseCount(o.Text)
				if a then counts[#counts+1]={o=o,cur=a,max=b}
				else
					local n=norm(o.Text)
					if n then names[#names+1]={o=o,n=n} end
				end
			end
		end
		local prog,cols,nameObj={}, {}, {}
		for _,c in ipairs(counts) do
			local a=c.o.Parent
			for _=1,3 do
				if not a or a==pg then break end
				local cnt=0
				for _,c2 in ipairs(counts) do
					if c2.o:IsDescendantOf(a) then cnt+=1 end
				end
				if cnt==1 then
					local found
					for _,nm in ipairs(names) do
						if nm.n~="SELESAI" and nm.o:IsDescendantOf(a) then found=nm break end
					end
					if found then
						prog[found.n]={cur=c.cur,max=c.max}
						cols[found.n]=a
						nameObj[found.o]=true
						break
					end
				end
				if cnt>1 then break end
				a=a.Parent
			end
		end
		return prog,cols,names,nameObj,#counts
	end

	-- label nama yang BUKAN bagian panel progres = tombol pilih / tombol SELESAI / judul latihan
	local function findLabel(ex,names,nameObj,cols)
		for _,nm in ipairs(names) do
			if nm.n==ex and not nameObj[nm.o] and shown(nm.o) then
				local inCol=false
				for _,c in pairs(cols) do
					if nm.o:IsDescendantOf(c) then inCol=true break end
				end
				if not inCol then return nm.o end
			end
		end
	end
	local function clickable(o)
		if o:IsA("GuiButton") then return o end
		local a=o.Parent
		for _=1,3 do
			if a and a:IsA("GuiButton") and shown(a) then return a end
			a=a and a.Parent
		end
		return o
	end
	-- tebakan latihan aktif dari judul panel latihan (teks nama paling besar)
	local function guessTitle(names,nameObj,cols)
		local best,bestH,tie
		for _,nm in ipairs(names) do
			if nm.n~="SELESAI" and not nameObj[nm.o] and shown(nm.o) then
				local inCol=false
				for _,c in pairs(cols) do
					if nm.o:IsDescendantOf(c) then inCol=true break end
				end
				if not inCol then
					local h=nm.o.TextBounds.Y
					if not bestH or h>bestH+0.5 then best,bestH,tie=nm.n,h,false
					elseif math.abs(h-bestH)<=0.5 and nm.n~=best then tie=true end
				end
			end
		end
		if best and not tie then return best end
	end

	local function tapXY(cx,cy)
		VIM:SendMouseButtonEvent(cx,cy,0,true,game,0)
		task.wait(0.05)
		VIM:SendMouseButtonEvent(cx,cy,0,false,game,0)
	end
	local function tapGui(o)
		local p,sz=o.AbsolutePosition,o.AbsoluteSize
		tapXY(p.X+sz.X/2,p.Y+sz.Y/2+GS:GetGuiInset().Y)
	end

	-- rekam posisi logo dumbbell: tap sekali di logo setelah menekan tombol Set
	local capturing=false
	function FX.captureDumb()
		if capturing then return end
		capturing=true
		setStatus("Tap logo dumbbell sekarang...")
		task.delay(0.6,function()
			local con
			con=UIS.InputBegan:Connect(function(i)
				if not (i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1) then return end
				local pos=i.Position
				local mine=false
				pcall(function()
					for _,o in ipairs(pg:GetGuiObjectsAtPosition(pos.X,pos.Y)) do
						if o:IsDescendantOf(gui) then mine=true break end
					end
				end)
				if mine then return end
				local v=viewport()
				S.dumbX=math.clamp(pos.X/v.X,0,1)
				S.dumbY=math.clamp((pos.Y+GS:GetGuiInset().Y)/v.Y,0,1)
				con:Disconnect()
				capturing=false
				repaint("dumbX")
				setStatus("Tombol dumbbell tersimpan")
			end)
			conns[#conns+1]=con
			task.delay(15,function()
				if capturing then pcall(function() con:Disconnect() end) capturing=false setStatus("Set dumbbell dibatalkan") end
			end)
		end)
	end

	task.spawn(function()
		while alive do
			task.wait(0.5)
			if S.autoSwitch and alive then
				local ok,err=pcall(function()
					local prog,cols,names,nameObj,nCount=readProgress()
					-- lacak latihan yang sedang dihitung (angkanya naik)
					for _,ex in ipairs(ORDER) do
						local p=prog[ex]
						if p then
							if prev[ex] and p.cur>prev[ex] then activeEx=ex end
							prev[ex]=p.cur
						end
					end
					local target
					for _,ex in ipairs(ORDER) do
						local p=prog[ex]
						if p and p.cur<p.max then target=ex break end
					end
					local doneLbl=findLabel("SELESAI",names,nameObj,cols)
					if sw then
						local parts={}
						for _,ex in ipairs(ORDER) do
							local p=prog[ex]
							parts[#parts+1]=ex:sub(1,2)..":"..(p and (p.cur.."/"..p.max) or "?")
						end
						sw.Text=table.concat(parts," ").." | T:"..(target or "-").." A:"..(activeEx or "?").." SEL:"..(doneLbl and "y" or "n")
					end
					if not next(prog) then
						setStatus("Progres latihan tidak terbaca ("..nCount.." angka)")
						return
					end
					if not target then
						setStatus("Semua latihan sudah penuh")
						return
					end
					if os.clock()-lastSw<2 then return end
					if doneLbl then
						-- sedang latihan
						if not activeEx then activeEx=guessTitle(names,nameObj,cols) end
						local p=activeEx and prog[activeEx]
						if p and p.cur>=p.max then
							lastSw=os.clock()
							tapGui(clickable(doneLbl))
							setStatus("Selesai "..activeEx)
							activeEx=nil
						end
					else
						activeEx=nil
						local lbl=findLabel(target,names,nameObj,cols)
						if lbl then
							lastSw=os.clock()
							tapGui(clickable(lbl))
							activeEx=target
							setStatus("Pindah ke "..target)
							nd,zn,pX=nil,nil,nil
						elseif os.clock()-lastDumb>3 then
							-- menu latihan tertutup: buka lewat logo dumbbell
							if S.dumbX>=0 and S.dumbY>=0 then
								lastDumb=os.clock()
								lastSw=os.clock()
								local v=viewport()
								tapXY(S.dumbX*v.X,S.dumbY*v.Y)
								setStatus("Buka menu latihan")
							else
								setStatus("Set Tombol Dumbbell dulu")
							end
						end
					end
				end)
				if not ok and sw then sw.Text="error: "..tostring(err):sub(1,60) end
			end
		end
	end)
end)()

----------------------------------------------------------------
-- LOGIKA: AUTO REJOIN + AUTO EXECUTE
----------------------------------------------------------------
do
	local TPS=game:GetService("TeleportService")
	local qot=queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)

	-- antrikan script agar jalan lagi di server berikutnya
	local function queueSelf()
		if not (S.autoExec and qot and S.scriptUrl~="") then return end
		local src='loadstring(game:HttpGet("'..S.scriptUrl..'"))()'
		pcall(qot,src)
	end
	_G.NADIEL_QUEUE=queueSelf
	bind(lp.OnTeleport,function() queueSelf() end)
	queueSelf()

	local rejoining=false
	local function rejoin()
		if rejoining or not S.autoRejoin then return end
		rejoining=true
		task.spawn(function()
			for i=1,6 do
				if not alive then break end
				setStatus("Auto Rejoin... ("..i..")")
				queueSelf()
				pcall(function()
					if i%2==1 then
						TPS:TeleportToPlaceInstance(game.PlaceId,game.JobId,lp) -- server yang sama
					else
						TPS:Teleport(game.PlaceId,lp) -- server baru
					end
				end)
				task.wait(8)
			end
			rejoining=false
		end)
	end

	-- layar error (kick / disconnect)
	bind(GS.ErrorMessageChanged,function(msg)
		if alive and msg and msg~="" then rejoin() end
	end)
	task.spawn(function()
		pcall(function()
			local cg=game:GetService("CoreGui")
			local ov=cg:WaitForChild("RobloxPromptGui",5):WaitForChild("promptOverlay",5)
			bind(ov.ChildAdded,function(c)
				if alive and c.Name=="ErrorPrompt" then rejoin() end
			end)
		end)
	end)
end
