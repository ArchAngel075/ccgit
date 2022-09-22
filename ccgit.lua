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

local function makeRaw(url,params,method)
    local path = url
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

local function checkRateLimit()
    local path = _baseurl .. "/rate_limit"
    local fetch = makeRaw(path)
    print(fetch.getResponseCode())
    print(fetch.readLine())
    print(fetch.json.resources.core.used,"of",fetch.json.resources.core.limit, "with",fetch.json.resources.core.remaining,"remaining")
    print("resets in ",fetch.json.resources.core.reset)
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

local function downloadRecursively(tree,root,sub)
    --print("root is",root);
    for k,resource in pairs(tree) do
        if(resource.type == "file") then
            local filepath = resource.name
            if(root) then
                filepath = root .."/".. filepath;
            end
            print("","","...downloading '" .. filepath .. "'",resource.size)
            local download,written = downloadFile(resource.download_url, filepath, true);
            print("","","success: ",download, "written: ",written)
        elseif(resource.type == "blob") then
            print("","","...downloading '" .. root .. resource.path .. "'",resource.size)
            local download,written = downloadFile(resource.url, root .. resource.path, true);
            print("","","success: ",download, "written: ",written)
        elseif(resource.type == "dir") then
            local subfetch = makeRaw(resource.git_url)
            local subtree = subfetch.json.tree
            local filepath = resource.path .. "/"
            if(root) then
                filepath = root .."/".. filepath;
            end
            downloadRecursively(subtree,filepath,true)
        elseif(resource.type == "tree") then
            local subfetch = makeRaw(resource.url)
            local subtree = subfetch.json.tree
            local filepath = resource.path
            if(root) then
                filepath = root .. filepath;
            end
            downloadRecursively(subtree,filepath .. "/",true)
        end
    end
end

local function downloadContent(root,path,owner,repo)
    
    local fetch = fetchContent(path,owner,repo)
    if(fetch.getResponseCode() ~= -1) then
        print("-----DOWNLOADING RESULTS-----")
        downloadRecursively(fetch.json,root)
        print("----------")
    else
        print("got",fetch.getResponseCode())
    end
end



local _args = {...}
if(_args[1] == "fetch" and _args[2] and _args[3] and _args[4]) then
    local owner = _args[2]
    local repo = _args[3]
    local path = _args[4] or repo
    downloadContent(path,nil,owner,repo)
    checkRateLimit()
elseif(_args[1] == "branches" and _args[2] and _args[3]) then
    local owner = _args[2]
    local repo = _args[3]
    checkRateLimit()
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
elseif(_args[1] == "check") then
    checkRateLimit()
else
    print("unknown command", unpack(_args))
    print("accepted :")
    print("fetch {owner} {repo} {path}")
    print("","{owner}","the owner of the repo")
    print("","{repo}","the repo to fetch (main branch only FOR NOW)")
    print("","{path}","the local path to save files to")
end