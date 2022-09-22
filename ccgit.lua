local _baseurl = "https://api.github.com"
local _token = "SECRET";
if(fs.exists("_token")) then
    local _tokenFile = fs.open("_token","r");
    _token = _tokenFile.readAll();
    _tokenFile.close()
else
    error("please provide GIT HUB API PERSONALISED TOKEN (PAT) in a file _token on the root directory.")
end

local _baseheader = {Authorization=_token, Accept="application/vnd.github.v3+json"}

local _owner = "ArchAngel075"
local _repo = "ccgit"

local function _getResponseCode() return -1 end

local function make(owner,repo,resource,path,params,method)
    local path = _baseurl .. "/" .. (resource) .. "/" .. (owner or _owner) .. "/" .. (repo or _repo) .. "/" .. (path)
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


local function getBranches(owner, repo)
    local fetch = make(owner,repo,"repos","branches")
    if(fetch.getResponseCode() ~= -1) then
        return fetch
    else error("unable to fetch branches for owner:".. owner .."| repo:".. repo)
    end
end

local function fetchContent(path,owner,repo)
    local fetch = false
    if(path) then
        fetch = make(owner,repo,"repos","contents/" .. (path))
    else
        fetch = make(owner,repo,"repos","contents/")
    end
    if(fetch.getResponseCode() ~= -1) then
        -- print("-----RESULTS-----")
        -- for k,v in pairs(fetch.json) do
        --     if(type(v) =="table") then
        --         print(k)
        --         for i,o in pairs(v) do
        --             print("",i,o)
        --         end
        --     else
        --         print(k,v)
        --     end
        -- end
        -- print("----------")
    else
        print("got",fetch.getResponseCode())
    end
    return fetch;
end

local function downloadFile(url,to,force_overwrite)
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

local function downloadContent(root,path,owner,repo)
    
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
                    local download,written = downloadFile(resource.download_url, filepath, true);
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



local _args = {...}
if(_args[1] == "fetch" and _args[2] and _args[3] and _args[4]) then
    local owner = _args[2]
    local repo = _args[3]
    local path = _args[4]
    downloadContent(path,nil,ower,repo)
elseif(_args[1] == "branches" and _args[2] and _args[3]) then
    local owner = _args[2]
    local repo = _args[3]
    local fetch = getBranches(owner, repo)
    print("-----RESULTS-----")
    for k,v in pairs(fetch.json) do
        if(type(v) =="table") then
            print(v.name)
        else
            print(k,v)
        end
    end
    print("----------")
else
    print("unknown command", unpack(_args))
    print("accepted :")
    print("fetch {owner} {repo} {path}")
    print("","{owner}","the owner of the repo")
    print("","{repo}","the repo to fetch (main branch only FOR NOW)")
    print("","{path}","the local path to save files to")
end