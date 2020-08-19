local ipairs = ipairs
local type = type

local utils = require("gateway.utils.utils")
local stringy = require("gateway.utils.stringy")
local gateway_db = require("gateway.store.gateway_db")
local judge_util = require("gateway.utils.judge")
local extractor_util = require("gateway.utils.extractor")
local handle_util = require("gateway.utils.handle")
local BasePlugin = require("gateway.plugins.base_handler")
local resty_cookie=require("gateway.lib.cookie")
local json = require("gateway.utils.json")
 


local function ensure_end(uri)
    if not stringy.endswith(uri, "/") then
        uri = uri.."/"
    end
    return uri
end

local function filter_rules(sid, plugin, ngx_var, ngx_var_uri, ngx_var_host)
    local rules = gateway_db.get_json(plugin .. ".selector." .. sid .. ".rules")
    ngx.log(ngx.INFO, "[AB_Divide] rule============",json.encode(rules) )

    if not rules or type(rules) ~= "table" or #rules <= 0 then
        return false
    end
   
    local pass = false

    for i, rule in ipairs(rules) do
        ngx.log(ngx.INFO, "[AB_Divide] rule============",json.encode(rule) )
        if rule.enable == true then
            -- judge阶段
            local pass = judge_util.judge_rule(rule, plugin)
            -- 基础没匹配上时，进行业务匹配
            if  pass then
               return true

            end 
        end
    end
       return false
end


local DivideHandler = BasePlugin:extend()
DivideHandler.PRIORITY = 2000

function DivideHandler:new(store)
    DivideHandler.super.new(self, "ab_divide")
    self.store = store
end

function DivideHandler:init_worker()
    ngx.log(ngx.INFO, "[AB_Divide] ", " @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@init ...........................................................")
    gateway_db.set("a_divide","http://a_upstream");
    gateway_db.set("b_divide","http://default_upstream");
end     

function DivideHandler:access(conf)
    DivideHandler.super.access(self)
    -- ngx.log(ngx.log,"")

    local enable = gateway_db.get("ab_divide.enable")
    ngx.log(ngx.INFO,"enable-----"..type(enable))
    local meta = gateway_db.get_json("ab_divide.meta")
    ngx.log(ngx.INFO,"enable-----"..type(meta))
    local selectors = gateway_db.get_json("ab_divide.selectors")
    ngx.log(ngx.INFO,"enable-----"..type(selectors))
    local ordered_selectors = meta and meta.selectors
    --未配置任何规则时，不进行灰度处理d
    if not enable or enable ~= true or not meta or not ordered_selectors or not selectors then
        ngx.log(ngx.INFO,"未配置规则，不进行灰度处理")
        return
    end

    local ngx_var = ngx.var
    local ngx_var_uri = ngx_var.uri
    local ngx_var_host = ngx_var.host
    --进行渠道匹配
    for i, sid in ipairs(ordered_selectors) do
        ngx.log(ngx.INFO, "==[ab_divide][PASS THROUGH SELECTOR:", sid, "]")
        local selector = selectors[sid]
        ngx.log(ngx.INFO, "==[ab_divide][PASS THROUGH SELECTOR:", sid, "]  rule=",selector.type)

        if selector and selector.enable == true then
            local selector_pass 
            if selector.type == 0 then -- 全流量选择器
                selector_pass = true
            else
                selector_pass = judge_util.judge_selector(selector, "ab_divide")-- selector judge
            end
            ngx.log(ngx.INFO, "==[ab_divide][PASS THROUGH SELECTOR:", sid, "] result=",selector_pass)
            --渠道匹配成功时，进行规则匹配
            if selector_pass then
                if selector.handle and selector.handle.log == true then
                    ngx.log(ngx.INFO, "[ab_divide][PASS-SELECTOR:", sid, "] ", ngx_var_uri)
                end
            
                local match = filter_rules(sid, "ab_divide", ngx_var, ngx_var_uri, ngx_var_host)
                --规则匹配成功，进行灰度转发
                if match then -- 进行灰度出路
                    
                    -- ngx.log(ngx.INFO, "[AB_Divide] 转发到灰度 ")
                    local a_divide = gateway_db.get("a_divide")
                    ngx.log(ngx.INFO, "[AB_Divide] 转发到灰度 "..a_divide)
                    ngx_var.upstream_url='http://a_upstream'
                    ngx_var.upstream_host = ngx_var_host
                   
                else 
                    local b_divide = gateway_db.get("b_divide");
                    ngx.log(ngx.INFO, "[AB_Divide] 转发到正式 "..b_divide)

                end
            else
                if selector.handle and selector.handle.log == true then
                    ngx.log(ngx.INFO, "[ab_divide][NOT-PASS-SELECTOR:", sid, "] ", ngx_var_uri)
                end
            end

            -- if continue or break the loop
            if selector.handle and selector.handle.continue == true then
                -- continue next selector
            else
                break
            end
        end
    end
    


    
    -- local ngx_var = ngx.var
    -- local ngx_var_uri = ngx_var.uri
    -- local ngx_var_host = ngx_var.host
    -- local cookie, err = resty_cookie:new()
    -- local just = false;
    -- if cookie then

    --     local cookies,err = cookie:get_all();
    --     ngx.log(ngx.INFO, "[AB_Divide] ", "......................"..ngx_var_uri)
    --     if cookies then
    --         for k, v in pairs(cookies) do
    --             if k == "tel" and v == "1" then
    --                 just=true;
    --                 break
    --             end    
    --         end
    --     end    
        
    -- end 
    
   
    -- local enable = gateway_db.get("ab_divide.enable")
    -- local meta = gateway_db.get_json("ab_divide.meta")
    -- local selectors = gateway_db.get_json("ab_divide.selectors")
    -- local ordered_selectors = meta and meta.selectors
    
    -- if not enable or enable ~= true or not meta or not ordered_selectors or not selectors then
    --     return
    -- end

    -- local ngx_var = ngx.var
    -- local ngx_var_uri = ngx_var.uri
    -- local ngx_var_host = ngx_var.host

    -- for i, sid in ipairs(ordered_selectors) do
    --     ngx.log(ngx.INFO, "==[ab_divide][PASS THROUGH SELECTOR:", sid, "]")
    --     local selector = selectors[sid]
    --     if selector and selector.enable == true then
    --         local selector_pass 
    --         if selector.type == 0 then -- 全流量选择器
    --             selector_pass = true
    --         else
    --             selector_pass = judge_util.judge_selector(selector, "ab_divide")-- selector judge
    --         end

    --         if selector_pass then
    --             if selector.handle and selector.handle.log == true then
    --                 ngx.log(ngx.INFO, "[ab_divide][PASS-SELECTOR:", sid, "] ", ngx_var_uri)
    --             end

    --             local stop = filter_rules(sid, "ab_divide", ngx_var, ngx_var_uri, ngx_var_host)
    --             if stop then -- 不再执行此插件其他逻辑
    --                 return
    --             end
    --         else
    --             if selector.handle and selector.handle.log == true then
    --                 ngx.log(ngx.INFO, "[ab_divide][NOT-PASS-SELECTOR:", sid, "] ", ngx_var_uri)
    --             end
    --         end

    --         -- if continue or break the loop
    --         if selector.handle and selector.handle.continue == true then
    --             -- continue next selector
    --         else
    --             break
    --         end
    --     end
    -- end
    
end

return DivideHandler
