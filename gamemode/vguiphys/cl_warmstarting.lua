VGUI_WARMSTART_IMPULSE = 1
VGUI_WARMSTART_FRICTION_IMPULSE = 2

if not VGUIWarmstartingLoaded then
	GM.VGUIWarmStarting = {}
	VGUIWarmstartingLoaded = true
end


-- From https://youtu.be/ViOrN3jImcs?list=PLbuK0gG93AsENAa67XysaOr5K0cczxye_&t=875
-- The point of this is to give each potential contact point from a collision a unique ID that way its results can be tracked frame-to-frame.

function GM:GetFeatureID(refHitbox, incHitbox, refIDX, incIDX, idx)
	local refPhysbox = Rawget(refHitbox, "_physbox")
	local incPhysbox = Rawget(incHitbox, "_physbox")

	local refPhysID = Rawget(refPhysbox, "_id")
	local incPhysID = Rawget(incPhysbox, "_id")
	local refHitID = Rawget(refHitbox, "_id")
	local incHitID = Rawget(incHitbox, "_id")

	local prefix =
		bit.Bor(
			bit.Lshift(bit.Band(refPhysID, 0xFF), 24),
			bit.Lshift(bit.Band(incPhysID, 0xFF), 16),
			bit.Lshift(bit.Band(refHitID, 0xF), 12),
			bit.Lshift(bit.Band(incHitID, 0xF), 8)
		)

	local refNumPoints = Rawget(refHitbox, "_points"):Count()
	local incNumPoints = Rawget(incHitbox, "_points"):Count()

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

	return true
end

function GM:VGUIGetWarmImpulse(fID)
	local data = Rawget(self.VGUIWarmStarting, fID)
	if not data then return end

	return Rawget(data, "imp")
end
function GM:VGUIGetWarmFrictionImpulse(fID)
	local data = Rawget(self.VGUIWarmStarting, fID)
	if not data then return end

	return Rawget(data, "fimp")
end
function GM:VGUIGetWarmContactPoint(fID)
	local data = Rawget(self.VGUIWarmStarting, fID)
	if not data then return end

	return Rawget(data, "cp")
end

function GM:VGUIGetWarmstartData(fID) return Rawget(self.VGUIWarmStarting, fID) end
function GM:VGUIInitWarmstartData(fID, cp, imp, fimp)
	local data = {cp = cp, imp = imp, fimp = fimp}
	Rawset(self.VGUIWarmStarting, fID, data)
end

function GM:VGUISetPersistentContactData(fID, data) self.VGUIWarmStarting[fID] = data end
function GM:VGUIClearPersistentContactData(fID) Rawset(self.VGUIWarmStarting, fID, nil) end

function GM:VGUIWarmstartLambda(fID, imp, fimp, cp)
	local data = self:VGUIGetWarmstartData(fID)

	-- Update the contact point.
	Rawset(data, "cp", cp)

	-- This means though that our previous warmstart plus a correction was added in the last collision resolution.
	-- Add the adjustment.
	if imp and not imp:IsZero() then
		local oldimp = self:VGUIGetWarmImpulse(fID)
		local lambda = imp
		Rawset(data, "imp", oldimp + lambda)
	end

	if fimp and not fimp:IsZero() then
		local oldfimp = self:VGUIGetWarmFrictionImpulse(fID)
		lambda = fimp
		Rawset(data, "fimp", oldfimp + lambda)
	end
end