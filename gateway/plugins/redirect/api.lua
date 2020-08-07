local BaseAPI = require("gateway.plugins.base_api")
local common_api = require("gateway.plugins.common_api")

local api = BaseAPI:new("redirect-api", 2)
api:merge_apis(common_api("redirect"))
return api
