local AdminConfig = {}

AdminConfig.AdminIds = {
	9658715268, 1679623289  -- IMPORTANTE: substitua pelo seu UserId do Roblox
}

function AdminConfig.isAdmin(userId: number): boolean
	for _, id in ipairs(AdminConfig.AdminIds) do
		if id == userId then return true end
	end
	return false
end

return AdminConfig
