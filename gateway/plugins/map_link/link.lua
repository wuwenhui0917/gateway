-- 长短链接映射处理累
-- 并进行对应处理
-- author :wwh6
local _LINK = {}
local json = require("gateway.utils.json")
local page_data = ngx.shared.page_data
local path="/home/wuwenhui/works/temp/pageinfo.txt"
--设置短链接配置地址
local page_redis_key="mlink_short"

function _LINK.init(store)
    local type = store:getType()
    if type == "redis" then
        ngx.log(ngx.INFO, "[map_link] ", "getType is redis")
        local info = store:getListInfo("mlink_short",0,-1)
        if info then
            local listinfo = json.decode(info)
            if listinfo then
                for pageinfo in listinfo do
                    ngx.log(ngx.INFO, "[map_link] ", pageinfo)
                end
            end    
            
        end    

    else 
        ngx.log(ngx.INFO, "[map_link] ", "init ...........................................................")
        local file = io.open(path, "r")
        if file then
            for line in file:lines()  do 
                if string.byte(line)~=string.byte("#") then
                local pageinfo = stringy.split(line,"#")
                local srcurl = pageinfo[1]
                local desurl=pageinfo[2]
                    if srcurl~=nil and desurl~=nil then
                    ngx.log(ngx.INFO, " MapLinkHandler ", srcurl,"===========",desurl)

                    page_data:set(srcurl,desurl)
                    end
                end
            end 
            io.close(file) 
        end
    end    
end    
return _LINK