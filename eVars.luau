local SupportedFunction = {
    Available = {},
    Unavailable = {}
}

function Log(...)
    return print("[Gousse] : ", ...)
end

local function CheckVariabel(Variable, Name)
    if Variable == nil then
        SupportedFunction.Unavailable[Name] = 'nil'
        return false
    else
        SupportedFunction.Available[Name] = Variable
        return true
    end
end

local function GetFunction(Name : string)
    return SupportedFunction.Available[Name];
end

Log("Checking exploit function compatibility...")

-- Actor Library 
CheckVariabel(create_comm_channel, 'CreateCommChannel') 
CheckVariabel(getactors, 'GetActors') 
CheckVariabel(getactorthreads, 'GetActorThreads') 
CheckVariabel(getdeleteactors, 'GetDeleteActors') 
CheckVariabel(get_comm_channel, 'GetCommChannel') 
CheckVariabel(isparallel, 'IsParallel') 
CheckVariabel(run_on_actor, 'RunOnActor') 
CheckVariabel(run_on_thread, 'RunOnThread')

-- Cache Library
CheckVariabel(cache.invalidate, 'InvalidateCache') 
CheckVariabel(cache.iscached, 'IsCached') 
CheckVariabel(cache.replace, 'CacheReplace') 
CheckVariabel(cloneref, 'CLoneRef') 
CheckVariabel(compareinstances, 'CompareInstances')

-- Closure Library
CheckVariabel(getfunctionhash, 'GetFunctionHash') 
CheckVariabel(isexecutorclosure, 'IsExecutorClosure')
CheckVariabel(hookfunction, 'HookFunction') 
CheckVariabel(isfunctionhooked, 'IsFunctionHooked') 
CheckVariabel(issourthread, 'IsSourThread') 
CheckVariabel(restorefunction, 'RestoreFunction') 
CheckVariabel(setstackhidden, 'SetStackHidden')
CheckVariabel(newlclosure, 'LClosure') 
CheckVariabel(islclosure, 'IsLClosure')
CheckVariabel(newcclosure, 'CClosure')
CheckVariabel(iscclosure, 'IsCClosure')
CheckVariabel(isnewcclosure, 'IsNewCClosure')
CheckVariabel(loadstring, 'Loadstring')

-- Debug Library
CheckVariabel(debug.getconstant, 'GetConstant') 
CheckVariabel(debug.getconstants, 'GetConstants') 
CheckVariabel(debug.getupvalue, 'GetUpValue') 
CheckVariabel(debug.getupvalues, 'GetUpValues')
CheckVariabel(debug.getproto, 'GetProto')
CheckVariabel(debug.getprotos, 'GetProtos')
CheckVariabel(debug.getregistry, 'GetRegistry')
CheckVariabel(debug.setconstant, 'SetConstant') 
CheckVariabel(debug.setupvalue, 'SetUpValue') 
CheckVariabel(debug.setstack, 'SetStack')

-- File Library
CheckVariabel(delfile, 'DeleteFile')
CheckVariabel(delfolder, 'DeleteFolder')
CheckVariabel(appendfile, 'AppendFile')
CheckVariabel(dofile, 'DoFile')
CheckVariabel(isfile, 'IsFile')
CheckVariabel(listfiles, 'ListFiles')
CheckVariabel(loadfile, 'LoadFile')
CheckVariabel(makefolder, 'MakeFolder')
CheckVariabel(readfile, 'ReadFile')
CheckVariabel(writefile, 'WriteFile')

-- Input Library
CheckVariabel(mouse1click, 'Mouse1Click')
CheckVariabel(mouse1press, 'Mouse1Press') 
CheckVariabel(mouse1release, 'Mouse1Release') 
CheckVariabel(mouse2click, 'Mouse2Click') 
CheckVariabel(mouse2press, 'Mouse2Press') 
CheckVariabel(mouse2release, 'Mouse2Release') 
CheckVariabel(mousemoveabs, 'MouseMoveABS')
CheckVariabel(mousemoverel, 'MouseMoveREL') 
CheckVariabel(mousescroll, 'MouseScroll')

-- Instance Library
CheckVariabel(fireclickdetector, 'FireClickDetector') 
CheckVariabel(fireproximityprompt, 'FireProximityPrompt') 
CheckVariabel(firetouchinterest, 'FireTouchInterest') 
CheckVariabel(getcallbackvalue, 'GetCallbackValue') 
CheckVariabel(getcustomasset, 'GetCustomAsset') 
CheckVariabel(gethui, 'GetHui') 
CheckVariabel(getinstances, 'GetInstances')
CheckVariabel(getnilinstances, 'GetNilInstances') 
CheckVariabel(getrendersteppedlist, 'GetRenderSteppedList')

-- MT Library
CheckVariabel(getnamecallmethod, 'GetNamecallMethod') 
CheckVariabel(getrawmetatable, 'GetRawMetatable') 
CheckVariabel(hookmetamethod, 'HookMetaMethod') 
CheckVariabel(isreadonly, 'IsReadOnly')
CheckVariabel(makereadonly, 'MakeReadOnly') 
CheckVariabel(setnamecallmethod, 'SetNamecallMethod')
CheckVariabel(setrawmetatable, 'SetRawMetatable') 
CheckVariabel(setreadonly, 'SetReadOnly') 

-- Miscellaneous Library
CheckVariabel(clearteleportqueue, 'ClearTeleportQueue') 
CheckVariabel(getfpscap, 'GetFPSCap') 
CheckVariabel(gethwid, 'GetHWID') 
CheckVariabel(getfflag, 'GetFFlag') 
CheckVariabel(getfflagtype, 'GetFFlagType') 
CheckVariabel(getobjects, 'GetObjects') 
CheckVariabel(httpget or game.HttpGet, 'HttpGet') 
CheckVariabel(identifyexecutor, 'IdentifyExecutor')
CheckVariabel(messagebox, 'MessageBox') 
CheckVariabel(request, 'Request') 
CheckVariabel(saveinstance, 'SaveInstance') 
CheckVariabel(setclipboard, 'SetClipBoard') 
CheckVariabel(setfflag, 'SetFFlag') 
CheckVariabel(setfpscap, 'SetFPSCap') 
CheckVariabel(setrbxclipboard, 'SetRBXClipboard') 

-- RakNet
CheckVariabel(raknet, 'RakNet')

-- Reflection Library
CheckVariabel(getbspval, 'GetBSPValue') 
CheckVariabel(gethiddenproperties, 'GetHiddenProperteis') 
CheckVariabel(gethiddenproperty, 'GetHiddenProperty') 
CheckVariabel(getpcd, 'GetPCD') 
CheckVariabel(getproperties, 'GetProperties') 
CheckVariabel(getproximitypromptduration, 'GetProxmityPromptDuration')
CheckVariabel(getsimulationradius, 'GetSimulationRadius') 
CheckVariabel(isnetworkowner, 'IsNetworkOwner') 
CheckVariabel(isscriptable, 'IsScriptable') 
CheckVariabel(sethiddenproperty, 'SetHiddenProperty') 
CheckVariabel(setproximitypromptduration, 'SetProximityPromptDuration') 
CheckVariabel(setscriptable, 'SetScriptable') 
CheckVariabel(setsimulationradius, 'SetSimulationRadius') 

-- Script Library
CheckVariabel(getloadedmodules, 'GetLoadedModules') 
CheckVariabel(getrunningscripts, 'GetRunningScripts') 
CheckVariabel(getscriptbytecode, 'GetScriptByteCode') 
CheckVariabel(getscriptclosure, 'GetScriptClosure') 
CheckVariabel(getscriptfromthread, 'GetScriptFromThread') 
CheckVariabel(getscriptthread, 'GetScriptThread') 
CheckVariabel(getscripthash, 'GetScriptHash') 
CheckVariabel(getscripts, 'GetScripts') 
CheckVariabel(getthreadidentity, 'GetThreadIdentity') 
CheckVariabel(setthreadidentity, 'SetThreadIdentity') 
CheckVariabel(dumpbytecode, 'DumpByteCode') 
CheckVariabel(decompile, 'Decompile') 

-- Signal Library 
CheckVariabel(firesignal, 'FireSignal') 
CheckVariabel(cansignalreplicate, 'CanSignalReplicate') 
CheckVariabel(getconnection, 'GetConnection') 
CheckVariabel(getconnections, 'GetConnections') 
CheckVariabel(getsignalarguments, 'GetSignalArguments') 
CheckVariabel(getsignalargumentsinfo, 'GetSignalArgumentsInfo') 
CheckVariabel(getsignalwhitelist, 'GetSignalWhitelist') 
CheckVariabel(replicatesignal, 'ReplicateSignal') 

-- Websocket Library 
CheckVariabel(WebSocket.connect, 'WebSocketConnect') 

Log("Exploit functions have been collected, waiting for result...")

local TotalFunction = #SupportedFunction.Available + #SupportedFunction.Unavailable
local FunctionFound = #SupportedFunction.Available
local Percent = math.floor((FunctionFound / TotalFunction) * 100)

Log(("Executor compatibility : %d%%"):format(Percent))

local Gousse = {}
function Gousse:retrieveGithub(Destination : string, File : string)
    local Url = ("https://raw.githubusercontent.com/Jexytd/Gousse/refs/heads/main/%s/%s.luau"):format(Destination, File);
    local Status, Content = pcall(GetFunction("Request"), Url);
    
    return Status and Content or nil
end

return SupportedFunction, Gousse