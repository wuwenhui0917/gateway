local ipairs = ipairs
local type = type
local utils = require("gateway.utils.utils")
local stringy = require("gateway.utils.stringy")
local json = require("gateway.utils.json")
local BasePlugin = require("gateway.plugins.base_handler")
local MapLinkHandler = BasePlugin:extend()
function MapLinkHandler:new(store)
    MapLinkHandler.super.new(self, "map_link")
    self.store = store
end
local path="conf/pageinfo.txt"

function MapLinkHandler:init_worker()
    ngx.log(ngx.INFO, "[map_link] ", "init ...........................................................")
    local file = io.open(path, "r")
    if file then
        for line in file:lines()  do 
            if string.byte(line)~=string.byte("!") then
               local pageinfo = stringy.split(line,"!")
               local srcurl = pageinfo[1]
               local desurl=pageinfo[2]
                if srcurl~=nil and desurl~=nil then
                   page_data:set(srcurl,desurl)
                end
            end
        end 
        io.close(file) 
    end
end     

function MapLinkHandler:access(conf)
    DivideHandler.super.access(self)
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
        ngx_redirect(to_redirect, redirect_status)
    end
end

return MapLinkHandler
