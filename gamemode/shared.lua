DeriveGamemode("orange-juice")

GM.Name		=	"Cascade"
GM.Author	=	"Citrus"
GM.Email	=	"citruskb@outlook.com"
GM.Website	=	""

local PlayerManager = player_manager
function GM:GetHandsModel(pl)
	return PlayerManager.TranslatePlayerHands(PlayerManager.TranslateToPlayerModelName(pl:GetModel()))
end