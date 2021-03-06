include("shared.lua")

ENT.Icon = "vgui/ttt/ttt_manheckler"

function ENT:Initialize()
	self:SetRenderBounds(Vector(-72, -72, -72), Vector(72, 72, 72))

	self.AmbientSound = CreateSound(self, "npc/manhack/mh_engine_loop1.wav")
	self.AmbientSound:Play()
	self.AmbientSound2 = CreateSound(self, "npc/manhack/mh_blade_loop1.wav")
	self.AmbientSound2:Play()

	self.Emitter = ParticleEmitter(self:GetPos())
	self.Emitter:SetNearClip(16, 24)

	self.PixVis = util.GetPixelVisibleHandle()

	hook.Add("CreateMove", self, self.CreateMove)
	hook.Add("ShouldDrawLocalPlayer", self, self.ShouldDrawLocalPlayer)
	hook.Add("CalcView", self, self.CalcView)
end

ENT.NextEmit = 0
local smokegravity = Vector(0, 0, 64)
function ENT:Think()
	self.AmbientSound:PlayEx(0.5, math.Clamp(80 + self:GetVelocity():Length() * 0.3, 80, 160))
	self.AmbientSound2:PlayEx(0.3, 100 + math.sin(CurTime()))

	self.Emitter:SetPos(self:GetPos())

	local perc = math.Clamp(self:GetObjectHealth() / self:GetMaxObjectHealth(), 0, 255)
	if perc < 0.5 and CurTime() >= self.NextEmit then
		self.NextEmit = CurTime() + 0.05 + perc * math.Rand(0.05, 0.25)

		local particle = self.Emitter:Add("particles/smokey", self:GetPos())
		particle:SetStartAlpha(180)
		particle:SetEndAlpha(0)
		particle:SetStartSize(0)
		particle:SetEndSize(math.Rand(8, 20))
		particle:SetVelocity(self:GetVelocity() * 0.7 + VectorRand():GetNormalized() * math.Rand(4, 24))
		particle:SetGravity(smokegravity)
		particle:SetDieTime(math.Rand(0.8, 1.6))
		particle:SetAirResistance(150)
		particle:SetRoll(math.Rand(0, 360))
		particle:SetRollDelta(math.Rand(-2, 2))
		particle:SetCollide(true)
		particle:SetBounce(0.2)
		local sat = perc * 90
		particle:SetColor(sat, sat, sat)
	end
end

function ENT:OnRemove()
	self.AmbientSound:Stop()
	self.AmbientSound2:Stop()
end

function ENT:SetObjectHealth(health)
	self:SetDTFloat(0, health)
end

local colLight = Color(255, 0, 0)
local colWhite = Color(255, 255, 255)
local colHealth = Color(255, 255, 255)
local matLight = Material("sprites/light_ignorez")
function ENT:DrawTranslucent()
	self:DrawModel()

	local lp = LocalPlayer()
	local owner = self:GetOwner()

	local epos = self:GetRedLightPos()
	local LightNrm = self:GetRedLightAngles():Forward()
	local ViewNormal = epos - EyePos()
	local Distance = ViewNormal:Length()
	ViewNormal:Normalize()
	local ViewDot = ViewNormal:Dot( LightNrm * -1 )

	if ViewDot >= 0 then
		if owner:IsValid() and owner:IsPlayer() then
			local vcol = owner:GetPlayerColor()
			if vcol then
				if vcol == vector_origin then
					vcol.x = 1 vcol.y = 1 vcol.z = 1
				end
				vcol:Normalize()
				vcol = vcol * 2.55
				colLight.r = math.Clamp(vcol.r * 100, 0, 255)
				colLight.g = math.Clamp(vcol.g * 100, 0, 255)
				colLight.b = math.Clamp(vcol.b * 100, 0, 255)
			end
		end

		local LightPos = epos + LightNrm * 5

		render.SetMaterial(matLight)
		local Visibile	= util.PixelVisible( LightPos, 16, self.PixVis )	

		if not Visibile then return end

		local Size = math.Clamp(Distance * Visibile * ViewDot * 0.9, 20, 210)

		Distance = math.Clamp(Distance, 32, 800)
		local Alpha = math.Clamp((1000 - Distance) * Visibile * ViewDot, 0, 100)
		colLight.a = Alpha
		colWhite.a = Alpha

		render.DrawSprite(LightPos, Size, Size, colLight, Visibile * ViewDot)
		render.DrawSprite(LightPos, Size*0.4, Size*0.4, colWhite, Visibile * ViewDot)
	end
end

function ENT:CreateMove(cmd)
	if self:GetOwner() ~= LocalPlayer() then return end

	if not self:BeingControlled() then return end

	local buttons = cmd:GetButtons()

	cmd:ClearMovement()

	if bit.band(buttons, IN_JUMP) ~= 0 then
		buttons = buttons - IN_JUMP
		buttons = buttons + IN_BULLRUSH
	end

	if bit.band(buttons, IN_DUCK) ~= 0 then
		buttons = buttons - IN_DUCK
		buttons = buttons + IN_GRENADE1
	end

	cmd:SetButtons(buttons)
end

function ENT:ShouldDrawLocalPlayer(pl)
	if self:GetOwner() ~= LocalPlayer() then return end

	if self:BeingControlled() then
		return true
	end
end

local ViewHullMins = Vector(-4, -4, -4)
local ViewHullMaxs = Vector(4, 4, 4)
function ENT:CalcView(pl, origin, angles, fov, znear, zfar)
	if self:GetOwner() ~= pl then return end

	if not self:BeingControlled() then return end

	local filter = player.GetAll()
	filter[#filter + 1] = self
	local tr = util.TraceHull({start = self:GetPos(), endpos = self:GetPos() + angles:Forward() * -48, mask = MASK_SHOT, filter = filter, mins = ViewHullMins, maxs = ViewHullMaxs})

	return {origin = tr.HitPos + tr.HitNormal * 3}
end
