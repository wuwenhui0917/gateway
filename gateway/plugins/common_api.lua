local ipairs = ipairs
local type = type
local tostring = tostring
local table_insert = table.insert
local json = require("gateway.utils.json")
local gateway_db = require("gateway.store.gateway_db")
local utils = require("gateway.utils.utils")
local stringy = require("gateway.utils.stringy")
local dao = require("gateway.store.dao")
local aes = require("resty.aes")

-- build common apis
return function(plugin)
    local API = {}

    API["/" .. plugin .. "/enable"] = {
        post = function(store)
            return function(req, res, next)
                local enable = req.body.enable
                if enable == "1" then enable = true else enable = false end

                local plugin_enable = "0"
                if enable then plugin_enable = "1" end
                local update_result = dao.update_enable(plugin, store, plugin_enable)

                if update_result then
                    local success, _, _ = gateway_db.set(plugin .. ".enable", enable)
                    if success then
                        return res:json({
                            success = true ,
                            msg = (enable == true and "succeed to enable plugin" or "succeed to disable plugin")
                        })
                    end
                end

                res:json({
                    success = false,
                    msg = (enable == true and "failed to enable plugin" or "failed to disable plugin")
                })
            end
        end
    }

    -- fetch config from store
    API["/" .. plugin .. "/fetch_config"] = {
        GET = function(store)
            return function(req, res, next)
                local success, data =  dao.compose_plugin_data(store, plugin)
                if success then
                    return res:json({
                        success = true,
                        msg = "succeed to fetch config from store",
                        data = data
                    })
                else
                    ngx.log(ngx.ERR, "error to fetch plugin[" .. plugin .. "] config from store")
                    return res:json({
                        success = false,
                        msg = "error to fetch config from store"
                    })
                end
            end
        end
    }

    -- get config in gateway's node now
    API["/" .. plugin .. "/config"] = {
        GET = function(store)
            return function(req, res, next)
                local enable = gateway_db.get(plugin .. ".enable") or false
                local meta = gateway_db.get_json(plugin .. ".meta") or {}

                local selectors = {}
                if meta and meta.selectors and type(meta.selectors)=="table" then
                    for i, sid in ipairs(meta.selectors) do
                        local selector = {}
                        local cache_selectors = gateway_db.get_json(plugin .. ".selectors") or {}
                        for j, selector_detail in pairs(cache_selectors) do
                            if j == sid then
                                selector = selector_detail
                                if selector_detail.rules and type(selector_detail.rules) == "table" then
                                    local rule_ids = selector_detail.rules
                                    local cache_rules = gateway_db.get_json(plugin .. ".selector." .. sid .. ".rules") or {}
                                    local rules = {}
                                    for m, rule_id in ipairs(rule_ids) do
                                        for n, rule in ipairs(cache_rules) do
                                            if rule_id == rule.id then
                                                table_insert(rules, rule)
                                            end
                                        end
                                    end
                                    selector.rules = rules
                                else
                                    selector.rules = {}
                                end
                            end
                        end
                        table_insert(selectors, selector)
                    end
                end

                return res:json({
                    success = true,
                    msg = "succeed to get configuration in this node",
                    data = {
                        enable = enable,
                        selectors = selectors
                    }
                })
            end
        end
    }

    -- update the local cache to data stored in db
    API["/" .. plugin .. "/sync"] = {
        POST = function(store)
            return function(req, res, next)
                local load_success = dao.load_data_by_mysql(store, plugin)
                if load_success then
                    return res:json({
                        success = true,
                        msg = "succeed to load config from store"
                    })
                else
                    ngx.log(ngx.ERR, "error to load plugin[" .. plugin .. "] config from store")
                    return res:json({
                        success = false,
                        msg = "error to load config from store"
                    })
                end
            end
        end
    }

    

   --获取插件的基础原来信息 add by wuwh6
   API["/p/m"]={

       GET=function(store)
           return function(req,res,next)
                local plugin_id=ngx.req.get_uri_args().pid
                local selectinf=nil
                local rules=nil
             
		if  plugin_id then
                     
                     local plginfo = dao.get_meta(plugin_id,store)
                     
                     if  not plginfo then
                        return res:json({
                        success = false,
                        plugin_id=plugin_id,
                        msg = "selector not found when creating rule"
			
                       })
                     else 
                        local selecid =plginfo.value
                        local selecid = json.decode(selecid).selectors[1]
                        
                        ngx.log(ngx.ERR,type(selecid) .. "select"..selecid)
                        if not selectid then
                           selectinf = dao.get_selector(plugin_id,store,selecid)
                           local ruleid = json.decode(selectinf.value).rules
                           ngx.log(ngx.ERR,type(ruleid) .. "rules>>>>>>>>>>>>>>>>>>>>>>"..#ruleid )
                           if #ruleid >0  then
                             rules=dao.get_rules_of_selector(plugin_id,store,ruleid)
                             --ngx.log(ngx.ERR,"rulesresult>>>>>>>>>>>>>>>>>>>>>>"..rules)

                           end
                           
                           
                        end    
                        selectinf.value=json.decode(selectinf.value)
                        plginfo.value = json.decode(plginfo.value)
 			return res:json({
                        success = true,
                        selector=selectinf,
			meta=plginfo,
		        rule=rules
                       })
                     end
                  end               
                  
           end
       end


   }


   --新增插件配置 add by wuwh6
   API["/p/a"]={
       POST=function(store)
           return function(req,res,next)
               local pluginid=req.body.plugin
               --添加插件基础数据
               local plugintype=req.body.meta
               --渠道编码
               local chanid=req.body.chanid
               --选择器数据
               local selector = req.body.selector
               --规则数据
               local ruleinfo = req.body.rule
               --插件名称
	       local plugintable = req.body.pluginName
               --local plguin = dao.get_meta(pluginid)
               --选择器更新
               --local selector = dao.get_selector(plugin_id, store, selector_id)
	       if not pluginid  then
                    return res:json({
                        success = false,
                        msg = "plugin must not nil"
                    })
            
               end
                
                if not plugintable  then
                    return res:json({
                        success = false,
                        msg = "pluginName must not nil"
                    })
            
               end
               
                if not plugintype  then
                    return res:json({
                        success = false,
                        msg = "meta must not nil"
                    })
            
               end
               
               if not chanid  then
                    return res:json({
                        success = false,
                        msg = "chanid must not nil"
                    })
            
               end
               
               if not selector  then
                    return res:json({
                        success = false,
                        msg = "selector must not nil"
                    })
            
               end
               
               if not ruleinfo  then
                    return res:json({
                        success = false,
                        msg = "ruleinfo must not nil"
                    })
            
               end
               
               ngx.log(ngx.ERR,"meta>>>>>>>>>>>>>>>>>>>>>>"..json.decode(plugintype).id)
               --开始插入数据插件数据
		local inserttag = dao.create_pluginData(plugintable,store,json.decode(plugintype),"meta",chanid,json.decode(plugintype).id)
                if not inserttag then
                    return res:json({
                        success = false,
                        msg = "create pluginmeta error"
                    })
                end
                ngx.log(ngx.ERR,"selector>>>>>>>>>>>>>>>>>>>>>>"..selector)
                --创建选择器数据
                local insertselecttag = dao.create_pluginData(plugintable,store,json.decode(selector),"selector",chanid,json.decode(selector).id)

                 if not insertselecttag then
                    return res:json({
                        success = false,
                        msg = "create selector error"
                    })
                end
                ngx.log(ngx.ERR,"rule>>>>>>>>>>>>>>>>>>>>>>"..ruleinfo)
		--创建规则
                local insertruletag = dao.create_pluginData(plugintable,store,json.decode(ruleinfo),"rule",chanid,json.decode(ruleinfo).id)

                 if not insertruletag then
                    return res:json({
                        success = false,
                        msg = "create rule error"
                    })
                end
		--创建成功
                return res:json({
                        success = true,
                        msg = "create "..plugintype.."成功"
                    })
                
               
		
            end
        end
         
   }


 --add by wuwh6 同步缓存
 API["/p/sync"] = {
        POST = function(store)
            return function(req, res, next)
   
                local plugin_id=req.body.pid
                if not plugin_id then
                   return res:json({
                        success = false,
                        msg = "pid must not null"
                    })
                end
                plugin_id = json.decode(plugin_id).plugin

                 for id,plugin in ipairs(plugin_id) do
                       ngx.log(ngx.ERR, ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>[" .. id .. plugin.."] config from store")
                       local load_success = dao.load_data_by_mysql(store, plugin)
                       if not local_success then
                            ngx.log(ngx.ERR, "error to load plugin[" .. plugin .. "] config from store")
                       end
                   
                 end        
                    return res:json({
                        success = true,
                        msg = "succeed to load config from store"
                    })
                
            end
        end
    }

API["/r/d"]={

   GET=function(store)
      return function(req,res,next)
         local laes =aes.new()
         local msg = leas.encrypt("nihaodsds")
         local de = leas.decrypt(msg)
         ngx.log(ngx.ERR,"dsdss dex======"..msg)
         ngx.log(ngx.ERR,"yuan====".. de)     
         return res:json({
                        success = true,
                        demg=msg,
                        src=
                        msg = "succeed to load config from store"
                    })
         
      end
   end,


   POST=function(store)
     return function(req,res,next)
            local chanid=req.body.chanid
       
     end
   end

}


   --删除信息 addby wuwh
   API["/p/d"]={

       POST=function(store)
         return function(req,res,next)
               local plugin_id=req.body.data
               ngx.log(ngx.ERR,"rule>>>>>>>>>>>>>>>>>>>>>>"..plugin_id)
	       
	       if plugin_id then  
                  local plugin_data = json.decode(plugin_id)
                  local chanid = plugin_data.chanid
                  ngx.log(ngx.ERR,"chanid>>>>>>>>>>>>>>>>>>>>>>"..chanid)
                  local ruleid = plugin_data.ruleid
                  local selectid = plugin_data.selectid
                  local pluginid = plugin_data.pluginid
                  ngx.log(ngx.ERR,"pluginid>>>>>>>>>>>>>>>>>>>>>>"..pluginid)
		  if not pluginid then
                    return res:json({
                            success = false,
                            msg = "pluginid not nil"
                        
                         })
                  end

                   
                  if  ruleid  then
                      if not dao.delete_rules_of_selector(pluginid,store,ruleid) then
                         return res:json({
                            success = false,
                            msg = "delete rule error"
                        
                         })
                      end      
                  end
                  if  selectid  then
                      if not dao.delete_selector(pluginid,store,selectid) then
                         return res:json({
                            success = false,
                            msg = "delete select error"
                        
                         })
                      end      
                  end
		  return res:json({
                        success = true,
                        msg = "delete sucessful"
                        
                    })
                  
                  
                  
               else 
                     return res:json({
                        success = false,
                        msg = "data must not nil"
                        
                    })
               end
         end
       end


  }


    API["/" .. plugin .. "/selectors/:id/rules"] = {
        POST = function(store) -- create
            return function(req, res, next)
                local selector_id = req.params.id
                ngx.log(ngx.ERR,"ruleid============================="..selector_id)
                local selector = dao.get_selector(plugin, store, selector_id)
                if not selector or not selector.value then
                    return res:json({
                        success = false,
                        msg = "selector not found when creating rule"
                    })
                end

                local current_selector = json.decode(selector.value)
                if not current_selector then
                    return res:json({
                        success = false,
                        msg = "selector could not be decoded when creating rule"
                    })
                end

                local rule = req.body.rule
                rule = json.decode(rule)
                rule.id = utils.new_id()
                rule.time = utils.now()

                -- 插入到mysql
                local insert_result = dao.create_rule(plugin, store, rule)

                -- 插入成功
                if insert_result then
                    -- update selector
                    current_selector.rules = current_selector.rules or {}
                    table_insert(current_selector.rules, rule.id)
                    local update_selector_result = dao.update_selector(plugin, store, current_selector)
                    if not update_selector_result then
                        return res:json({
                            success = false,
                            msg = "update selector error when creating rule"
                        })
                    end

                    -- update local selectors
                    local update_local_selectors_result = dao.update_local_selectors(plugin, store)
                    if not update_local_selectors_result then
                        return res:json({
                            success = false,
                            msg = "error to update local selectors when creating rule"
                        })
                    end

                    local update_local_selector_rules_result = dao.update_local_selector_rules(plugin, store, selector_id)
                    if not update_local_selector_rules_result then
                        return res:json({
                            success = false,
                            msg = "error to update local rules of selector when creating rule"
                        })
                    end
                else
                    return res:json({
                        success = false,
                        msg = "fail to create rule"
                    })
                end

                res:json({
                    success = true,
                    msg = "succeed to create rule"
                })
            end
        end,

        GET = function(store)
            return function(req, res, next)
                local selector_id = req.params.id

                local rules = gateway_db.get_json(plugin .. ".selector." .. selector_id .. ".rules") or {}
                res:json({
                    success = true,
                    data = {
                        rules = rules
                    }
                })
            end
        end,

        PUT = function(store) -- modify
            return function(req, res, next)
                local selector_id = req.params.id
                local rule = req.body.rule
                rule = json.decode(rule)
                rule.time = utils.now()

                local update_result = dao.update_rule(plugin, store, rule)

                if update_result then
                    local old_rules = gateway_db.get_json(plugin .. ".selector." .. selector_id .. ".rules") or {}
                    local new_rules = {}
                    for _, v in ipairs(old_rules) do
                        if v.id == rule.id then
                            rule.time = utils.now()
                            table_insert(new_rules, rule)
                        else
                            table_insert(new_rules, v)
                        end
                    end

                    local success, err, forcible = gateway_db.set_json(plugin .. ".selector." .. selector_id .. ".rules", new_rules)
                    if err or forcible then
                        ngx.log(ngx.ERR, "update local rules error when modifing:", err, ":", forcible)
                        return res:json({
                            success = false,
                            msg = "update local rules error when modifing"
                        })
                    end

                    return res:json({
                        success = success,
                        msg = success and "ok" or "failed"
                    })
                end

                res:json({
                    success = false,
                    msg = "update rule to db error"
                })
            end
        end,

        DELETE = function(store)
            return function(req, res, next)
                local selector_id = req.params.id
                local selector = dao.get_selector(plugin, store, selector_id)
                if not selector or not selector.value then
                    return res:json({
                        success = false,
                        msg = "selector not found when deleting rule"
                    })
                end

                local current_selector = json.decode(selector.value)
                if not current_selector then
                    return res:json({
                        success = false,
                        msg = "selector could not be decoded when deleting rule"
                    })
                end

                local rule_id = tostring(req.body.rule_id)



                if not rule_id or rule_id == "" then
                    return res:json({
                        success = false,
                        msg = "error param: rule id shoule not be null."
                    })
                end

                local delete_result = store:delete({
                    sql = "delete from " .. plugin .. " where `key`=? and `type`=?",
                    params = { rule_id, "rule"}
                })


                if delete_result then
                    -- update selector
                    local old_rules_ids = current_selector.rules or {}
                    local new_rules_ids = {}
                    for _, orid in ipairs(old_rules_ids) do
                        if orid ~= rule_id then
                            table_insert(new_rules_ids, orid)
                        end
                    end
                    current_selector.rules = new_rules_ids

                    local update_selector_result = dao.update_selector(plugin, store, current_selector)
                    if not update_selector_result then
                        return res:json({
                            success = false,
                            msg = "update selector error when deleting rule"
                        })
                    end

                    -- update local selectors
                    local update_local_selectors_result = dao.update_local_selectors(plugin, store)
                    if not update_local_selectors_result then
                        return res:json({
                            success = false,
                            msg = "error to update local selectors when deleting rule"
                        })
                    end

                    -- update local rules of selector
                    local update_local_selector_rules_result = dao.update_local_selector_rules(plugin, store, selector_id)
                    if not update_local_selector_rules_result then
                        return res:json({
                            success = false,
                            msg = "error to update local rules of selector when creating rule"
                        })
                    end
                else
                    res:json({
                        success = false,
                        msg = "delete rule from db error"
                    })
                end

                res:json({
                    success = true,
                    msg = "succeed to delete rule"
                })
            end
        end
    }

    -- update rules order
    API["/" .. plugin .. "/selectors/:id/rules/order"] = {
        PUT = function(store)
            return function(req, res, next)
                local selector_id = req.params.id

                local new_order = req.body.order
                if not new_order or new_order == "" then
                    return res:json({
                        success = false,
                        msg = "error params"
                    })
                end

                local tmp = stringy.split(new_order, ",")
                local rules = {}
                if tmp and type(tmp) == "table" and #tmp > 0 then
                    for _, t in ipairs(tmp) do
                        table_insert(rules, t)
                    end
                end

                local update_selector_result, update_local_selectors_result, update_local_selector_rules_result
                local selector = dao.get_selector(plugin, store, selector_id)
                if not selector or not selector.value then
                    ngx.log(ngx.ERR, "error to find selector when resorting rules of it")
                    return res:json({
                        success = true,
                        msg = "error to find selector when resorting rules of it"
                    })
                else
                    local new_selector = json.decode(selector.value) or {}
                    new_selector.rules = rules
                    update_selector_result = dao.update_selector(plugin, store, new_selector)
                    if update_selector_result then
                        update_local_selectors_result = dao.update_local_selectors(plugin, store)
                    end
                end

                if update_selector_result and update_local_selectors_result then
                    update_local_selector_rules_result = dao.update_local_selector_rules(plugin, store, selector_id)
                    if update_local_selector_rules_result then
                        return res:json({
                            success = true,
                            msg = "succeed to resort rules"
                        })
                    end
                end

                ngx.log(ngx.ERR, "error to update local data when resorting rules, update_selector_result:", update_selector_result, " update_local_selectors_result:", update_local_selectors_result, " update_local_selector_rules_result:", update_local_selector_rules_result)
                res:json({
                    success = false,
                    msg = "fail to resort rules"
                })
            end
        end
    }

    API["/" .. plugin .. "/selectors"] = {
        GET = function(store) -- get selectors
            return function(req, res, next)
                res:json({
                    success = true,
                    data = {
                        enable = gateway_db.get(plugin .. ".enable"),
                        meta = gateway_db.get_json(plugin .. ".meta"),
                        selectors = gateway_db.get_json(plugin .. ".selectors")
                    }
                })
            end
        end,

        DELETE = function(store) -- delete selector
            --- 1) delete selector
            --- 2) delete rules of it
            --- 3) update meta
            --- 4) update local meta & selectors
            return function(req, res, next)

                local selector_id = tostring(req.body.selector_id)
                if not selector_id or selector_id == "" then
                    return res:json({
                        success = false,
                        msg = "error param: selector id shoule not be null."
                    })
                end

                -- get selector
                local selector = dao.get_selector(plugin, store, selector_id)
                if not selector or not selector.value then
                    return res:json({
                        success = false,
                        msg = "error: can not find selector#" .. selector_id
                    })
                end

                -- delete rules of it
                local to_del_selector = json.decode(selector.value)
                if not to_del_selector then
                    return res:json({
                        success = false,
                        msg = "error: decode selector#" .. selector_id .. " failed"
                    })
                end

                local to_del_rules_ids = to_del_selector.rules or {}
                local d_result = dao.delete_rules_of_selector(plugin, store, to_del_rules_ids)
                ngx.log(ngx.ERR, "delete rules of selector:", d_result)

                -- update meta
                local meta = dao.get_meta(plugin, store)
                local current_meta = json.decode(meta.value)
                if not meta or not current_meta then
                   return res:json({
                        success = false,
                        msg = "error: can not find meta"
                    })
                end

                local current_selectors_ids = current_meta.selectors or {}
                local new_selectors_ids = {}
                for _, v in ipairs(current_selectors_ids) do
                    if  selector_id ~= v then
                        table_insert(new_selectors_ids, v)
                    end
                end
                current_meta.selectors = new_selectors_ids

                local update_meta_result = dao.update_meta(plugin, store, current_meta)
                if not update_meta_result then
                    return res:json({
                        success = false,
                        msg = "error: update meta error"
                    })
                end

                -- delete the very selector
                local delete_selector_result = dao.delete_selector(plugin, store, selector_id)
                if not delete_selector_result then
                    return res:json({
                        success = false,
                        msg = "error: delete the very selector error"
                    })
                end

                -- update local meta & selectors
                local update_local_meta_result = dao.update_local_meta(plugin, store)
                local update_local_selectors_result = dao.update_local_selectors(plugin, store)
                if update_local_meta_result and update_local_selectors_result then
                    return res:json({
                        success = true,
                        msg = "succeed to delete selector"
                    })
                else
                    ngx.log(ngx.ERR, "error to delete selector, update_meta:", update_local_meta_result, " update_selectors:", update_local_selectors_result)
                    return res:json({
                        success = false,
                        msg = "error to udpate local data when deleting selector"
                    })
                end
            end
        end,

        POST = function(store) -- create a selector
            return function(req, res)
                local selector = req.body.selector
                selector = json.decode(selector)
                selector.id = utils.new_id()
                selector.time = utils.now()

                -- create selector
                local insert_result = dao.create_selector(plugin, store, selector)

                -- update meta
                local meta = dao.get_meta(plugin, store)
                local current_meta = json.decode(meta and meta.value or "{}")
                if not meta or not current_meta then
                   return res:json({
                        success = false,
                        msg = "error: can not find meta when creating selector"
                    })
                end
                current_meta.selectors = current_meta.selectors or {}
                table_insert(current_meta.selectors, selector.id)
                local update_meta_result = dao.update_meta(plugin, store, current_meta)
                if not update_meta_result then
                    return res:json({
                        success = false,
                        msg = "error: update meta error when creating selector"
                    })
                end

                -- update local meta & selectors
                if insert_result then
                    local update_local_meta_result = dao.update_local_meta(plugin, store)
                    local update_local_selectors_result = dao.update_local_selectors(plugin, store)
                    if update_local_meta_result and update_local_selectors_result then
                        return res:json({
                            success = true,
                            msg = "succeed to create selector"
                        })
                    else
                        ngx.log(ngx.ERR, "error to create selector, update_meta:", update_local_meta_result, " update_selectors:", update_local_selectors_result)
                        return res:json({
                            success = false,
                            msg = "error to udpate local data when creating selector"
                        })
                    end
                else
                    return res:json({
                        success = false,
                        msg = "error to save data when creating selector"
                    })
                end
            end
        end,

        PUT = function(store) -- update
            return function(req, res, next)
                local selector = req.body.selector
                selector = json.decode(selector)
                selector.time = utils.now()
                -- 更新selector
                local update_selector_result = dao.update_selector(plugin, store, selector)
                if update_selector_result then
                    local update_local_selectors_result = dao.update_local_selectors(plugin, store)
                    if not update_local_selectors_result then
                        return res:json({
                            success = false,
                            msg = "error to local selectors when updating selector"
                        })
                    end
                else
                    return res:json({
                        success = false,
                        msg = "error to update selector"
                    })
                end

                return res:json({
                    success = true,
                    msg = "succeed to update selector"
                })
            end
        end
    }

    -- update selectors order
    API["/" .. plugin .. "/selectors/order"] = {
        PUT = function(store)
            return function(req, res, next)
                local new_order = req.body.order
                if not new_order or new_order == "" then
                    return res:json({
                        success = false,
                        msg = "error params"
                    })
                end

                local tmp = stringy.split(new_order, ",")
                local selectors = {}
                if tmp and type(tmp) == "table" and #tmp > 0 then
                    for _, t in ipairs(tmp) do
                        table_insert(selectors, t)
                    end
                end

                local update_meta_result, update_local_meta_result
                local meta = dao.get_meta(plugin, store)
                if not meta or not meta.value then
                    ngx.log(ngx.ERR, "error to find meta when resorting selectors")
                    return res:json({
                        success = true,
                        msg = "error to find meta when resorting selectors"
                    })
                else
                    local new_meta = json.decode(meta.value) or {}
                    new_meta.selectors = selectors
                    update_meta_result = dao.update_meta(plugin, store, new_meta)
                    if update_meta_result then
                        update_local_meta_result = dao.update_local_meta(plugin, store)
                    end
                end

                if update_meta_result and update_local_meta_result then
                    res:json({
                        success = true,
                        msg = "succeed to resort selectors"
                    })
                else
                    ngx.log(ngx.ERR, "error to update local meta when resorting selectors, update_meta_result:", update_meta_result, " update_local_meta_result:", update_local_meta_result)
                    res:json({
                        success = false,
                        msg = "fail to resort selectors"
                    })
                end
            end
        end
    }

    return API
end
