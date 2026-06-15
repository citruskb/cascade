VGUI_WARMSTART_IMPULSE = 1
VGUI_WARMSTART_FRICTION_IMPULSE = 2

if not VGUIWarmstartingLoaded then
	GM.VGUIWarmStarting = {}
	VGUIWarmstartingLoaded = true
end


-- From https://youtu.be/ViOrN3jImcs?list=PLbuK0gG93AsENAa67XysaOr5K0cczxye_&t=875
-- The point of this is to give each potential contact point from a collision a unique ID that way its results can be tracked frame-to-frame.

function GM:GetFeatureID(refHitbox, incHitbox, refIDX, incIDX, idx)
	local refPhysbox = refHitbox.physbox
	local incPhysbox = incHitbox.physbox

	local refPhysID = refPhysbox.id
	local incPhysID = incPhysbox.id
	local refHitID = refHitbox.id
	local incHitID = incHirbox.id

	local prefix =
		bit.Bor(
			bit.Lshift(bit.Band(refPhysID, 0xFF), 24),
			bit.Lshift(bit.Band(incPhysID, 0xFF), 16),
			bit.Lshift(bit.Band(refHitID, 0xF), 12),
			bit.Lshift(bit.Band(incHitID, 0xF), 8)
		)

	local refNumPoints = refHitbox.pointsObj:Count()
	local incNumPoints = incHitbox.pointsObj:Count()

	local i11 = refIDX							-- ref edge start vertex (a1)
	local i12 = (i11 + 1) % refNumPoints		-- ref edge end vertex (a2)
	local i21 = incIDX							-- incident edge start vertex (b1)
	local i22 = (i21 + 1) % incNumPoints		-- incident edge end vertex (b2)

	local suffix
	if idx == 1 then
		suffix =
			bit.Bor(
				bit.Lshift(bit.Band(i11, 0xF), 4),
				bit.Band(i22, 0xF)
			)
	else
		suffix =
			bit.Bor(
				bit.Lshift(bit.Band(i12, 0xF), 4),
				bit.Band(i21, 0xF)
			)
	end

	return bit.Bor(prefix, suffix)
end

function GM:VGUIIsPersistentContact(fID, contactPoint)
	local warmContactPoint = self:VGUIGetWarmContactPoint(fID)
	if not warmContactPoint then return end

	if not warmContactPoint:IsEqualTol(contactPoint, VGUIPHYS_WARMSTART_TOL) then return false end

	local count = self:VGUIGetWarmCount(fID)
	if not count then return false end
	if GAMEMODE.VGUIStepCount ~= count + 1 and GAMEMODE.VGUIStepCount ~= count then return false end

	return true
end

function GM:VGUIGetWarmJ(fID)
	local data = Rawget(self.VGUIWarmStarting, fID)
	if not data then return end

	return Rawget(data, "j")
end
function GM:VGUIGetWarmJT(fID)
	local data = Rawget(self.VGUIWarmStarting, fID)
	if not data then return end

	return Rawget(data, "jt")
end
function GM:VGUIGetWarmContactPoint(fID)
	local data = Rawget(self.VGUIWarmStarting, fID)
	if not data then return end

	return Rawget(data, "cp")
end
function GM:VGUIGetWarmCount(fID)
	local data = Rawget(self.VGUIWarmStarting, fID)
	if not data then return end

	return Rawget(data, "count")
end

function GM:VGUIGetWarmstartData(fID) return Rawget(self.VGUIWarmStarting, fID) end
function GM:VGUIInitWarmstartData(fID, cp, j, jt)
	local data = {cp = cp, j = j, jt = jt, count = self.VGUIStepCount}
	Rawset(self.VGUIWarmStarting, fID, data)
end

function GM:VGUISetPersistentContactData(fID, data) self.VGUIWarmStarting[fID] = data end
function GM:VGUIClearPersistentContactData(fID) Rawset(self.VGUIWarmStarting, fID, nil) end

function GM:VGUIWarmstartLambda(fID, j, jT, cp)
	local data = self:VGUIGetWarmstartData(fID)

	Rawset(data, "count", GAMEMODE.VGUIStepCount)
	Rawset(data, "cp", cp)

	if j and j > 0 then
		local oldimp = self:VGUIGetWarmJ(fID)
		local lambda = j
		Rawset(data, "j", oldimp + lambda)
	end

	if jT and jT > 0 then
		local oldfimp = self:VGUIGetWarmJT(fID)
		local lambda = jT
		local newVal = math.Max(0, oldfimp + lambda)
		Rawset(data, "jt", newVal)
	end
end