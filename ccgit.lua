print("Hello gitter")
_baseurl = "https://api.github.com"
_token = "1x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"
_baseheader = {Authorization=_token, Accept="application/vnd.github.v3+json"}

_owner = "ArchAngel075"
_repo = "ccgit"

function _getResponseCode() return -1 end

function make(owner,repo,resource,path,params,method)
    local path = _baseurl .. "/" .. (resource) .. "/" .. (owner or _owner) .. "/" .. (repo or _repo) .. "/" .. (path)
    print("path is [",path,"]")
    local header = {}
    --copy in base header requirements
    for k,v in pairs(_baseheader) do
        header[k] = v
    end
    --copy in and overwrite with params
    for k,v in pairs(params or {}) do
        header[k] = v
    end
    --make request and return
    local req = http[method or "get"](path, header) or {getResponseCode = _getResponseCode }
    if(req.getResponseCode() ~= -1) then
        req.json = textutils.unserialiseJSON(req.readAll());
    end
    return req
end


function getBranches(owner, repo)
    return make(owner,repo,"repos","branches")
end

function fetchContent(path,owner,repo)
    local fetch = false
    if(path) then
        fetch = make(owner,repo,"repos","contents/" .. (path))
    else
        fetch = make(owner,repo,"repos","contents/")
    end
    if(fetch.getResponseCode() ~= -1) then
        print("-----RESULTS-----")
        for k,v in pairs(fetch.json) do
            if(type(v) =="table") then
                print(k)
                for i,o in pairs(v) do
                    print("",i,o)
                end
            else
                print(k,v)
            end
        end
        print("----------")
    else
        print("got",fetch.getResponseCode())
    end
    return fetch;
end

function downloadFile(url,to,force_overwrite)
    local force_overwrite = force_overwrite or false,0
    if(fs.exists(to) and not force_overwrite) then return false,0 end
    local handle = fs.open(to,"w")
    local downloadRequest = http.get(url)
    if (downloadRequest and downloadRequest.getResponseCode() == 200) then
        handle.write(downloadRequest.readAll())
    end
    handle.flush()
    handle.close()
    return true,fs.getSize(to);
end

function downloadContent(root,path,owner,repo)
    
    local fetch = fetchContent(path,owner,repo)
    if(fetch.getResponseCode() ~= -1) then
        print("-----DOWNLOADING RESULTS-----")
        for k,resource in pairs(fetch.json) do
            if(type(resource) =="table") then
                if(resource.type == "file") then
                    local filepath = resource.name
                    if(root) then
                        filepath = root .."/".. filepath;
                    end
                    print("","","...downloading '" .. resource.name .. "'",resource.size)
                    local download,written = downloadFile(resource.download_url, filepath);
                    print("","","success: ",download, "written: ",written)
                end
            else
                print(k,resource)
            end
        end
        print("----------")
    else
        print("got",fetch.getResponseCode())
    end
end

local req = downloadContent("ccgit")
