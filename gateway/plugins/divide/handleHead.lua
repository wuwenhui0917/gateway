
local handle = {}
local cjson = require("cjson.safe")


function handle.encode(data, empty_table_as_object)
    if not data then return nil end

    if cjson.encode_empty_table_as_object then
        -- empty table default is arrya
        cjson.encode_empty_table_as_object(empty_table_as_object or false)
    end

    if require("ffi").os ~= "Windows" then
        cjson.encode_sparse_array(true)
    end

    return cjson.encode(data)
end

function handle.decode(data)
    if not data then return nil end

    return cjson.decode(data)
end


function handle.postHandle()
    
    ngx.log(ngx.ERR, "request mehod................................................. " ..ngx.req.get_method() );
    local methodName = ngx.req.get_method();
    if "POST"==methodName then
        ngx.log(ngx.ERR, "request mehod==============POST " );
        --读取body体
        ngx.req.read_body();
        local body = ngx.req.get_body_data();
        ngx.log(ngx.ERR, "request body+++++++++++++++++++++++++==" .. body);
        --ngx.log(ngx.INFO, "request body " .. body);
        --local chanId=body.chanId;
    -- local userId = body.userId;
        --ngx.req.set_header("chanId",chanId);
        --ngx.req.set_header("userId",userId);
        --设置baody体
        if   body  then

            local json_body = handle.decode(body);
	    --ngx.log(ngx.ERR, "request body+++++++++++++++++++++++++==" .. json_body);
            local chanid = json_body.chanid;
	    local userid = json_body.userid;
            ngx.log(ngx.ERR, "chanid+++++++++++++++++++++++++==" .. chanid);
            ngx.log(ngx.ERR, "userid+++++++++++++++++++++++++==" .. userid);
            
            if userid then
               ngx.req.set_header("uid",userid);
            end
            if chanid then
               ngx.req.set_header("cId",chanid);
            end
           
           --原来的报文重新放进去，供后续转发数据
            ngx.req.set_body_data(body)
        end
    end    
end

return handle