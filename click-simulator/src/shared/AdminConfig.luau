local AdminConfig = {}

AdminConfig.AdminIds = {
	000000000,  -- IMPORTANTE: substitua pelo seu UserId do Roblox
}

function AdminConfig.isAdmin(userId: number): boolean
	for _, id in ipairs(AdminConfig.AdminIds) do
		if id == userId then return true end
	end
	return false
end

return AdminConfig
