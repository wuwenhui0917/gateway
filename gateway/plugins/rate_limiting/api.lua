local BaseAPI = require("gateway.plugins.base_api")
local common_api = require("gateway.plugins.common_api")

local api = BaseAPI:new("rate-limiting-api", 2)
api:merge_apis(common_api("rate_limiting"))
return api
