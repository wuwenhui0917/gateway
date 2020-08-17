local BaseAPI = require("gateway.plugins.base_api")
local common_api = require("gateway.plugins.common_api")

local api = BaseAPI:new("ab_divide-api", 2)
api:merge_apis(common_api("ab_divide"))
return api
