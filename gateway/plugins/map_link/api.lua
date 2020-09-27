--
-- 长短链接映射api：加载长短链接配置到共享缓存中
--  author :wwh6
local BaseAPI = require("gateway.plugins.base_api")
local common_api = require("gateway.plugins.common_api")
local link = require("gateway.plugins.map_link.link")
local api = BaseAPI:new("map_link-api", 2)
api:merge_apis(common_api("map_link"))

api:get("/map_link/reload", function(parastore)
    
    return function(req, res, next)
        local gateway = context.gateway
        local store = gateway.data.store
        link.init(store)
        res:json({
            success = true,
            data = "ok"
        })
    end
end)


api:get("/map_link/count", function(parastore)
    
    return function(req, res, next)
        local uriid =  req.query.resid
        if not uriid or uriid =="" then 
            res:json({
                success = false,
                data = "resid must not empty"
            })
            return 
        end  
        local gateway = context.gateway
        local redisstore = gateway.data.store
        if redisstore  and redisstore:getType() == "redis" then
            local result = redisstore:get("shortlink/"..uriid)
            if result then
                res:json({
                    success = true,
                    data = "ok"..uriid,
                    count=result
                })
            else 
                res:json({
                    success = false,
                    data = "ok"..uriid
                })

            end     
        end 
    end
end)
return api
