local RS=game:GetService("RunService")
local GS=game:GetService("GuiService")
local UIS=game:GetService("UserInputService")
local VIM=game:GetService("VirtualInputManager")
local Stats=game:GetService("Stats")
local Players=game:GetService("Players")
local lp=Players.LocalPlayer
local pg=lp:WaitForChild("PlayerGui")
if _G.AWC then pcall(_G.AWC) end

local VERSION="v1.4.2"
-- Upload gambar logo ke repo GitHub dengan nama logo.jpg, lalu pastikan link ini benar
local LOGO_URL="https://raw.githubusercontent.com/nadilulumannafiz01-dev/NADIEL-ANS-SCRIPT/main/logo.jpg"
local LOGO_FILE="nadiel_logo.jpg"
local THEME_FILE="nadiel_theme.txt"
local START=os.clock()
local alive=true

local S={auto=true,latency=0.06,clickMode=1,clickPos=50,
	fly=false,vert=0,speed=60,flyCam=true,noclip=false,arrows=true,
	slot=1,max=4,
	aim=false,aimFov=150,aimSmooth=40,aimObjects=true,aimPlayers=false,autoShoot=false,
	finish=false,
	collect=false,collectR=40,collectTP=false}
local cps,conns,bv={}, {}, nil
local function bind(sig,fn) local c=sig:Connect(fn) conns[#conns+1]=c return c end
local function isPress(i) return i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch end
local function isMove(i) return i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch end

----------------------------------------------------------------
-- TEMA
----------------------------------------------------------------
local C={
	bg=Color3.fromRGB(10,14,26), side=Color3.fromRGB(13,19,36), row=Color3.fromRGB(20,28,50),
	acc=Color3.fromRGB(0,140,255), txt=Color3.fromRGB(232,238,250), sub=Color3.fromRGB(128,142,170),
	off=Color3.fromRGB(52,64,92), offTxt=Color3.fromRGB(110,122,150),
}
local DEFAULT_ACC=Color3.fromRGB(0,140,255)

pcall(function()
	if readfile and isfile and isfile(THEME_FILE) then
		local r,g,b=readfile(THEME_FILE):match("(%d+),(%d+),(%d+)")
		if r then
			C.acc=Color3.fromRGB(math.min(255,tonumber(r)),math.min(255,tonumber(g)),math.min(255,tonumber(b)))
		end
	end
end)

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
	for _,fn in ipairs(themeHooks) do pcall(fn) end
	if save and writefile then
		pcall(writefile,THEME_FILE,string.format("%d,%d,%d",
			math.floor(col.R*255+0.5),math.floor(col.G*255+0.5),math.floor(col.B*255+0.5)))
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
		local has=fresh or (isfile and isfile(LOGO_FILE))
		if not has then return end
		local ok2,asset=pcall(getcustomasset,LOGO_FILE)
		if ok2 and asset and alive and img.Parent then
			img.Image=asset
			if fallback then fallback.Visible=false end
		end
	end)
end

----------------------------------------------------------------
-- WINDOW
----------------------------------------------------------------
local gui=new("ScreenGui",{Name="NadielHub",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=999})
if not pcall(function() gui.Parent=(gethui and gethui()) or game:GetService("CoreGui") end) or not gui.Parent then gui.Parent=pg end

local W,H=460,270
local main=new("Frame",{Size=UDim2.new(0,W,0,H),Position=UDim2.new(0.5,-W/2,0.5,-H/2),BackgroundColor3=C.bg,Active=true,ClipsDescendants=true},gui)
round(main,12)
local mainStroke=new("UIStroke",{Thickness=1},main)
onTheme(function() mainStroke.Color=C.acc:Lerp(C.bg,0.78) end)

local head=new("Frame",{Size=UDim2.new(1,0,0,44),BackgroundTransparency=1},main)
local hIcon=new("ImageLabel",{Size=UDim2.new(0,28,0,28),Position=UDim2.new(0,10,0,8),BackgroundColor3=C.side,
	ScaleType=Enum.ScaleType.Crop,Image=""},head)
round(hIcon,14)
local hFall=label(hIcon,"▲",16,UDim2.new(),UDim2.new(1,0,1,0),C.acc,Enum.Font.GothamBold,Enum.TextXAlignment.Center)
accent(hFall,"TextColor3")
applyLogo(hIcon,hFall)
label(head,"Nadiel Hub",14,UDim2.new(0,42,0,6),UDim2.new(0,200,0,18),C.txt,Enum.Font.GothamBold)
label(head,"by Nadiel x Claude",11,UDim2.new(0,42,0,24),UDim2.new(0,200,0,14),C.sub)

local function headBtn(text,x)
	return new("TextButton",{Text=text,TextSize=16,Font=Enum.Font.GothamBold,TextColor3=C.sub,BackgroundTransparency=1,
		Size=UDim2.new(0,30,0,30),Position=UDim2.new(1,x,0,7)},head)
end
local bMin=headBtn("–",-72)
local bClose=headBtn("X",-38)

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

-- minimize jadi logo gambar (bisa digeser, tap untuk buka)
local LS=52
local logo=new("ImageButton",{Size=UDim2.new(0,LS,0,LS),Position=UDim2.new(0,20,0,60),BackgroundColor3=C.side,Image="",
	ScaleType=Enum.ScaleType.Crop,AutoButtonColor=false,Visible=false,Active=true},gui)
round(logo,LS/2)
accent(new("UIStroke",{Thickness=2},logo),"Color")
local logoFall=label(logo,"▲",22,UDim2.new(),UDim2.new(1,0,1,0),C.acc,Enum.Font.GothamBold,Enum.TextXAlignment.Center)
accent(logoFall,"TextColor3")
applyLogo(logo,logoFall)

local function viewport()
	local cam=workspace.CurrentCamera
	return cam and cam.ViewportSize or Vector2.new(800,400)
end
local function clampXY(x,y,w,h)
	local vs=viewport()
	return math.clamp(x,0,math.max(0,vs.X-w)),math.clamp(y,0,math.max(0,vs.Y-h))
end

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
local pages,tabBtns={}, {}
local function addTab(name,order)
	local b=new("TextButton",{Text=name,TextSize=12,Font=Enum.Font.GothamMedium,TextColor3=C.sub,BackgroundColor3=C.row,
		BackgroundTransparency=1,Size=UDim2.new(1,0,0,28),LayoutOrder=order,AutoButtonColor=false},tabList)
	round(b,8)
	local p=new("ScrollingFrame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,
		CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=false},content)
	accent(p,"ScrollBarImageColor3")
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
	onTheme(paint)
	local function set(v,silent) on=v paint() if not silent then cb(on) end end
	new("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=""},r).MouseButton1Click:Connect(function() set(not on) end)
	return set
end

local function slider(page,title,desc,mn,mx,def,cb)
	local r=base(page,title,desc)
	local val=label(r,tostring(def),11,UDim2.new(1,-176,0.5,-8),UDim2.new(0,32,0,16),C.sub,Enum.Font.Gotham,Enum.TextXAlignment.Right)
	local bar=new("Frame",{Size=UDim2.new(0,100,0,4),Position=UDim2.new(1,-134,0.5,-2),BackgroundColor3=C.off},r)
	round(bar,2)
	local fill=new("Frame",{Size=UDim2.new((def-mn)/(mx-mn),0,1,0)},bar)
	accent(fill,"BackgroundColor3")
	round(fill,2)
	local hit=new("TextButton",{Size=UDim2.new(1,0,0,28),Position=UDim2.new(0,0,0.5,-14),BackgroundTransparency=1,Text=""},bar)
	local drag=false
	local function show(v)
		fill.Size=UDim2.new(math.clamp((v-mn)/(mx-mn),0,1),0,1,0)
		val.Text=tostring(v)
	end
	local function set(x)
		local a=math.clamp((x-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
		local v=math.floor(mn+(mx-mn)*a+0.5)
		show(v)
		cb(v)
	end
	hit.InputBegan:Connect(function(i) if isPress(i) then drag=true set(i.Position.X) end end)
	bind(UIS.InputChanged,function(i) if drag and isMove(i) then set(i.Position.X) end end)
	bind(UIS.InputEnded,function(i) if isPress(i) then drag=false end end)
	return show
end

local function button(page,title,desc,text,cb)
	local r=base(page,title,desc)
	local b=new("TextButton",{Text=text,TextSize=12,Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1),
		Size=UDim2.new(0,76,0,26),Position=UDim2.new(1,-86,0.5,-13)},r)
	accent(b,"BackgroundColor3")
	round(b,6)
	b.MouseButton1Click:Connect(function() cb(b) end)
	return b
end

local function textRow(page,title,desc,cb)
	local r=base(page,title,desc)
	local tb=new("TextBox",{Text="",PlaceholderText="kata kunci",TextSize=11,Font=Enum.Font.Gotham,TextColor3=C.txt,
		PlaceholderColor3=C.sub,BackgroundColor3=C.off,ClearTextOnFocus=false,Size=UDim2.new(0,84,0,26),
		Position=UDim2.new(1,-94,0.5,-13)},r)
	round(tb,6)
	tb.FocusLost:Connect(function()
		local t=tb.Text:lower():gsub("^%s+",""):gsub("%s+$","")
		if #t>0 then cb(t) tb.Text="" setStatus("Ditambah: "..t) end
	end)
end

local function holdRow(page,title,desc)
	local r=base(page,title,desc)
	local function hb(text,x,v)
		local b=new("TextButton",{Text=text,TextSize=11,Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1),
			Size=UDim2.new(0,56,0,26),Position=UDim2.new(1,x,0.5,-13)},r)
		accent(b,"BackgroundColor3")
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
local pCol=addTab("Auto Collect",4)
local pFly=addTab("Fly",5)
local pCP=addTab("Checkpoint",6)
local pObby=addTab("Obby",7)
local pTema=addTab("Tema",8)
local pSet=addTab("Settings",9)

----------------------------------------------------------------
-- DASHBOARD
----------------------------------------------------------------
do
	local hd=new("Frame",{Size=UDim2.new(1,0,0,74),BackgroundColor3=C.row,LayoutOrder=1},pDash)
	round(hd,8)
	local bar=new("Frame",{Size=UDim2.new(0,3,1,-16),Position=UDim2.new(0,8,0,8),BorderSizePixel=0},hd)
	accent(bar,"BackgroundColor3")
	round(bar,2)
	local ttl=label(hd,"NADIEL HUB",16,UDim2.new(0,20,0,6),UDim2.new(1,-30,0,22),C.acc,Enum.Font.GothamBold)
	accent(ttl,"TextColor3")
	label(hd,"Creator: Nadiel[Drewyhall9]",11,UDim2.new(0,20,0,30),UDim2.new(1,-30,0,14),C.txt,Enum.Font.GothamMedium)
	label(hd,"Pengguna: "..lp.DisplayName.." (@"..lp.Name..")",10,UDim2.new(0,20,0,48),UDim2.new(1,-30,0,14),C.sub)

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
	local vCol=card("AUTO COLLECT",3)
	local vFly=card("FLY",4)
	local vNoc=card("NOCLIP",5)
	local vFin=card("AUTO FINISH",6)
	local vFps=card("FPS",7)
	local vPing=card("PING",8)
	local vUp=card("UPTIME",9)
	local vVer=card("VERSION",10)
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
		setState(vCol,S.collect)
		setState(vFly,S.fly)
		setState(vNoc,S.noclip)
		setState(vFin,S.finish)
	end)
end

----------------------------------------------------------------
-- AUTOMATIC
----------------------------------------------------------------
local dbg
toggle(pAuto,"Auto Click","Klik tepat di tengah zona hijau",true,function(v) S.auto=v setStatus(v and "Auto ON" or "Auto OFF") end)
slider(pAuto,"Latency (ms)","Naikkan jika klik telat",0,150,60,function(v) S.latency=v/1000 end)
slider(pAuto,"Titik Klik (%)","50 = tengah zona hijau",10,90,50,function(v) S.clickPos=v end)
button(pAuto,"Mode Klik","Zona / Panel / Layar","Zona",function(b)
	S.clickMode=S.clickMode%3+1
	b.Text=({"Zona","Panel","Layar"})[S.clickMode]
	setStatus("Mode klik: "..b.Text)
end)
do
	local r=base(pAuto,"Status Deteksi","Jarum dan zona hijau")
	dbg=label(r,"-",11,UDim2.new(1,-130,0,0),UDim2.new(0,120,1,0),C.acc,Enum.Font.GothamMedium,Enum.TextXAlignment.Right)
	accent(dbg,"TextColor3")
end

----------------------------------------------------------------
-- AUTO AIM
----------------------------------------------------------------
local AIMKEYS={"target","sasaran","bullseye","dummy"}
local aimCache,aimT,lastShot={}, 2, 0

local ring=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0.5,0,0.5,0),
	Size=UDim2.new(0,S.aimFov*2,0,S.aimFov*2),BackgroundTransparency=1,Visible=false,Active=false},gui)
round(ring,S.aimFov)
local ringStroke=new("UIStroke",{Thickness=1.5,Transparency=0.35},ring)
accent(ringStroke,"Color")

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
-- AUTO COLLECT
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

toggle(pCol,"Auto Collect","Ambil item di sekitar secara otomatis",false,function(v)
	S.collect=v
	colScan=0
	setStatus(v and "Collect ON" or "Collect OFF")
end)
slider(pCol,"Jangkauan (stud)","Jarak maksimal ambil item",10,200,40,function(v) S.collectR=v end)
toggle(pCol,"Teleport ke Item","Pindah ke item terdekat bila di luar jangkauan",false,function(v) S.collectTP=v end)
textRow(pCol,"Kata Kunci Item","Contoh: bintang",function(t) table.insert(COLK,t) colScan=0 end)
button(pCol,"Scan Ulang","Cari ulang item yang bisa diambil","SCAN",function()
	task.spawn(function()
		refreshCollect()
		setStatus("Item: "..#colCache)
	end)
end)

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
-- FLY + KONTROL
----------------------------------------------------------------
local updateFc
local function stopFly()
	S.fly=false S.vert=0
	if bv then bv:Destroy() bv=nil end
	if updateFc then updateFc() end
end

local setFlyUI
local fc=new("Frame",{Size=UDim2.new(0,52,0,112),Position=UDim2.new(1,-70,0.5,-56),BackgroundTransparency=1,Visible=false},gui)
local function fcBtn(text,y,size)
	local b=new("TextButton",{Text=text,TextSize=size or 20,Font=Enum.Font.GothamBold,TextColor3=C.txt,BackgroundColor3=C.side,
		Size=UDim2.new(0,52,0,52),Position=UDim2.new(0,0,0,y),AutoButtonColor=false},fc)
	round(b,26)
	accent(new("UIStroke",{Thickness=2},b),"Color")
	return b
end
local fUp=fcBtn("▲",0)
local fDn=fcBtn("▼",60)

updateFc=function() fc.Visible=S.fly and S.arrows end

local function holdBtn(b,v)
	b.InputBegan:Connect(function(i) if isPress(i) then S.vert=v end end)
	b.InputEnded:Connect(function(i) if isPress(i) and S.vert==v then S.vert=0 end end)
end
holdBtn(fUp,1)
holdBtn(fDn,-1)

setFlyUI=toggle(pFly,"Fly","Joystick untuk gerak, tombol untuk naik/turun",false,function(v)
	if v then
		local r=hrp()
		if not r then setStatus("Karakter belum siap") setFlyUI(false,true) updateFc() return end
		bv=new("BodyVelocity",{MaxForce=Vector3.one*1e9,Velocity=Vector3.zero},r)
		S.fly=true
		setStatus("Fly ON")
	else
		stopFly() setStatus("Fly OFF")
	end
	updateFc()
end)
slider(pFly,"Fly Speed","Kecepatan terbang",10,300,60,function(v) S.speed=v end)
toggle(pFly,"Arah Kamera","Terbang ke arah pandangan kamera",true,function(v) S.flyCam=v end)
toggle(pFly,"Noclip","Tembus dinding dan objek",false,function(v)
	S.noclip=v
	setStatus(v and "Noclip ON" or "Noclip OFF")
end)
toggle(pFly,"Panah Naik/Turun","Muncul otomatis saat Fly ON",true,function(v) S.arrows=v updateFc() end)
holdRow(pFly,"Naik / Turun","Tahan tombol")

bind(lp.CharacterAdded,function()
	stopFly()
	if setFlyUI then setFlyUI(false,true) end
	updateFc()
end)

bind(RS.Heartbeat,function()
	if not S.fly then return end
	local r=hrp()
	local h=lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
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
				local fwd=mv:Dot(flat)
				local rgt=mv:Dot(right)
				vel=(look*fwd+cam.CFrame.RightVector*rgt)*S.speed
			else
				vel=mv*S.speed
			end
		else
			vel=mv*S.speed
		end
	end
	bv.Velocity=vel+Vector3.new(0,S.vert*S.speed,0)
end)

-- noclip (hanya aktif saat toggle ON, otomatis dipulihkan saat OFF)
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
-- TEMA
----------------------------------------------------------------
local presets={
	{"Biru",0,140,255},{"Ungu",150,90,255},{"Merah",255,70,80},
	{"Hijau",40,200,120},{"Oranye",255,150,40},{"Pink",255,90,170},
}
local tr,tg,tb=math.floor(C.acc.R*255+0.5),math.floor(C.acc.G*255+0.5),math.floor(C.acc.B*255+0.5)
local showR,showG,showB

do
	ord+=1
	local r=new("Frame",{Size=UDim2.new(1,0,0,76),BackgroundColor3=C.row,LayoutOrder=ord},pTema)
	round(r,8)
	label(r,"Warna Tema",13,UDim2.new(0,10,0,6),UDim2.new(1,-20,0,18),C.txt,Enum.Font.GothamMedium)
	label(r,"Pilih warna utama UI",10,UDim2.new(0,10,0,24),UDim2.new(1,-20,0,14),C.sub)
	for i,pr in ipairs(presets) do
		local col=Color3.fromRGB(pr[2],pr[3],pr[4])
		local b=new("TextButton",{Text="",BackgroundColor3=col,Size=UDim2.new(0,32,0,32),
			Position=UDim2.new(0,10+(i-1)*42,0,40),AutoButtonColor=false},r)
		round(b,16)
		b.MouseButton1Click:Connect(function()
			tr,tg,tb=pr[2],pr[3],pr[4]
			if showR then showR(tr) showG(tg) showB(tb) end
			setTheme(col,true)
			setStatus("Tema: "..pr[1])
		end)
	end
end

showR=slider(pTema,"Merah (R)","Atur warna sendiri",0,255,tr,function(v) tr=v setTheme(Color3.fromRGB(tr,tg,tb),true) end)
showG=slider(pTema,"Hijau (G)","",0,255,tg,function(v) tg=v setTheme(Color3.fromRGB(tr,tg,tb),true) end)
showB=slider(pTema,"Biru (B)","",0,255,tb,function(v) tb=v setTheme(Color3.fromRGB(tr,tg,tb),true) end)
button(pTema,"Reset Warna","Kembali ke biru bawaan","RESET",function()
	tr,tg,tb=0,140,255
	showR(tr) showG(tg) showB(tb)
	setTheme(DEFAULT_ACC,true)
	setStatus("Tema direset")
end)

----------------------------------------------------------------
-- SETTINGS & UNLOAD
----------------------------------------------------------------
button(pSet,"Tutup Script","Hapus UI dan matikan semua fitur","UNLOAD",function() if _G.AWC then _G.AWC() end end)

do
	local armedClose=false
	bClose.MouseButton1Click:Connect(function()
		if armedClose then
			if _G.AWC then _G.AWC() end
			return
		end
		armedClose=true
		bClose.TextColor3=Color3.fromRGB(255,90,90)
		setStatus("Tekan X lagi untuk tutup")
		task.delay(2,function()
			if alive and bClose.Parent then
				armedClose=false
				bClose.TextColor3=C.sub
				setStatus("Siap")
			end
		end)
	end)
end

_G.AWC=function()
	alive=false
	S.finish=false
	S.aim=false
	S.collect=false
	S.noclip=false
	stopFly()
	for p in pairs(ncOrig) do
		if p.Parent then p.CanCollide=true end
		ncOrig[p]=nil
	end
	for _,c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	table.clear(conns)
	table.clear(aimCache)
	table.clear(colCache)
	table.clear(themeHooks)
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
local clicks,lastDbg=0,""
local function grn(c) return c.G>.6 and c.R<.5 and c.B<.65 and c.G>c.R+.25 end
local function wht(c) return c.R>.9 and c.G>.9 and c.B>.9 end

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

-- pasangkan jarum dan zona yang sejajar secara vertikal
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
	return bn,bz
end

local function setDbg(txt)
	if txt~=lastDbg then
		lastDbg=txt
		if dbg then dbg.Text=txt end
	end
end

local function doClick()
	local zp,zs=zn.AbsolutePosition,zn.AbsoluteSize
	local cx,cy=zp.X+zs.X/2,zp.Y+zs.Y/2
	if S.clickMode==2 and zn.Parent and zn.Parent:IsA("GuiObject") then
		local pa=zn.Parent
		cx=pa.AbsolutePosition.X+pa.AbsoluteSize.X/2
		cy=pa.AbsolutePosition.Y+pa.AbsoluteSize.Y/2
	end
	if S.clickMode==3 then
		local vs=viewport()
		cx,cy=vs.X*0.3,vs.Y*0.55
	else
		-- tambah inset topbar hanya jika GUI game tidak mengabaikannya
		local sg=zn:FindFirstAncestorOfClass("ScreenGui")
		if not (sg and sg.IgnoreGuiInset) then cy+=GS:GetGuiInset().Y end
	end
	VIM:SendMouseButtonEvent(cx,cy,0,true,game,0)
	task.delay(0.03,function()
		pcall(function() VIM:SendMouseButtonEvent(cx,cy,0,false,game,0) end)
	end)
	clicks+=1
end

bind(RS.RenderStepped,function(dt)
	if not S.auto then return end
	if nd and not shown(nd) then nd=nil pX=nil end
	if zn and not shown(zn) then zn=nil end
	if not nd or not zn then
		setDbg("Mencari...")
		t+=dt
		if t>.25 then
			t=0
			nd,zn=findPair()
			pX=nil
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
	setDbg("OK • klik: "..clicks)
end)
