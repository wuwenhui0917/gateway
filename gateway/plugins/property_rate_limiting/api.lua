local BaseAPI = require("gateway.plugins.base_api")
local common_api = require("gateway.plugins.common_api")
local plugin_config =  require("gateway.plugins.property_rate_limiting.plugin")

local api = BaseAPI:new(plugin_config.api_name, 2)
api:merge_apis(common_api(plugin_config.table_name))
return api
