--	Feature ID - make sure that contact points are uniquely trackable frame-to-frame.

function GM:VGUIPhysGetFeatureID(refHitbox, incHitbox, refIDX, incIDX, idx)
	local refPhysbox = refHitbox.physbox
	local incPhysbox = incHitbox.physbox

	local refPhysID = refPhysbox.id
	local incPhysID = incPhysbox.id
	local refHitID = refHitbox.id
	local incHitID = incHitbox.id

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

	return ToString(bit.Bor(prefix, suffix))
end