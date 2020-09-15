local BaseAPI = require("gateway.plugins.base_api")
local common_api = require("gateway.plugins.common_api")

local api = BaseAPI:new("map_link-api", 2)
api:merge_apis(common_api("map_link"))

api:get("/map_link/short", function(store)
    return function(req, res, next)
        
        res:json({
            success = true,
            data = "hello"
        })
    end
end)



return api
