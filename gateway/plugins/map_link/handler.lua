--
-- 长短链接映射api：加载长短链接配置到共享缓存中
--  author :wwh6
local ipairs = ipairs
local type = type
local utils = require("gateway.utils.utils")
local stringy = require("gateway.utils.stringy")
local json = require("gateway.utils.json")
local BasePlugin = require("gateway.plugins.base_handler")
local page_data = ngx.shared.page_data
local ngx_redirect = ngx.redirect
local link = require("gateway.plugins.map_link.link")
local MapLinkHandler = BasePlugin:extend()
function MapLinkHandler:new(store)
    MapLinkHandler.super.new(self, "map_link")
    self.store = store
end


--启动加载长短连接处理
function MapLinkHandler:init_worker()
    local redisstore = self.store
    local ok, err = ngx.timer.at(3, 
    function(premature,sstore)
        link.init(sstore)
    end, 
    redisstore)


   
end     

function MapLinkHandler:redirect()
    
    local string_find = string.find
    local request_method = ngx.var.request_method
    local args = nil
    local param = nil
    local param2 = nil
    local page_data = ngx.shared.page_data
    local ngx_var = ngx.var
    local ngx_var_host = ngx_var.http_host
    local ngx_var_scheme = ngx_var.scheme
    local ngx_var_args = ngx_var.args
    local ngx_var_uri = ngx_var.uri

    ngx.log(ngx.INFO, "[map_link>>>>>>>>>>>>>>>>>>>>>>] ", "handle ..........................................................."..ngx_var_uri)


    -- -- 获取url参数
    -- if "GET" == request_method then
    --     args = ngx.req.get_uri_args()
    -- elseif "POST" == request_method then
    --     ngx.req.read_body()
    --     args = ngx.req.get_post_args()
    -- end
    local to_redirect = page_data:get(ngx_var_uri)

    if to_redirect and to_redirect ~= ngx_var_uri then
        local redirect_status =302
        -- if redirect_status ~= 301 and redirect_status ~= 302 then
        --     redirect_status = 301
        -- end

        if string_find(to_redirect, 'http') ~= 1 then
            to_redirect = ngx_var_scheme .. "://" .. ngx_var_host .. to_redirect
        end

        if ngx_var_args ~= nil then
            if string_find(to_redirect, '?') then -- 不存在?，直接缀上url args
                to_redirect = to_redirect .. "&" .. ngx_var_args
            else
                to_redirect = to_redirect .. "?" .. ngx_var_args
            end
        end
        local redisstore = self.store
        if redisstore  and redisstore:getType() == "redis" then
            local result = redisstore:incr("shortlink"..ngx_var_uri)
        end    

        ngx_redirect(to_redirect, redirect_status)
    end
end

return MapLinkHandler
