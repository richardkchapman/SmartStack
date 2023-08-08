local LrApplication = import( "LrApplication" )
local LrErrors      = import( "LrErrors" )
local LrPathUtils   = import( "LrPathUtils" )
local LrFileUtils   = import( "LrFileUtils" )
local LrDialogs     = import( "LrDialogs" )
local LrTasks       = import( "LrTasks" )
local LrUUID        = import( "LrUUID" )
local prefs         = import( "LrPrefs" ).prefsForPlugin()
local LrLogger      = import( "LrLogger" )

myLogger      = LrLogger( 'BetterImport' )
 
prefs = import 'LrPrefs'.prefsForPlugin()
if true or prefs['debug'] == 'logfile' then
  myLogger:enable('logfile')
else
  myLogger:disable()
end

-- Convert a lua table into a lua syntactically correct string, for debugging and tracing purposes

function table_to_string(tbl)
  local result = "{"
  for k, v in pairs(tbl) do
      -- Check the key type (ignore any numerical keys - assume its an array)
      if type(k) == "string" then
          result = result.."[\""..k.."\"]".."="
      end

      -- Check the value type
      if type(v) == "table" then
          result = result..table_to_string(v)
      elseif type(v) == "boolean" then
          result = result..tostring(v)
      else
          result = result.."\""..v.."\""
      end
      result = result..","
  end
  -- Remove trailing commas from the result
  if result ~= "{" then
      result = result:sub(1, result:len()-1)
  end
  return result.."}\n"
end

--[[
  Use applescript/assistive tech to get Lightroom to group the selected photos
  No, this won't work on Windows.
]]

function groupSelected()
  local myPath = _PLUGIN.path
  local group = LrPathUtils.child(myPath, "group.osa")
  local commandLine = 'osascript ' .. group
  local exitStatus = LrTasks.execute (commandLine)
end

function expandStack()
  local myPath = _PLUGIN.path
  local group = LrPathUtils.child(myPath, "expandStack.osa")
  local commandLine = 'osascript ' .. group
  local exitStatus = LrTasks.execute (commandLine)
end

--[[
  Execute exiftool on a supplied list of files, running multiple instances in parallel to speed things up
  No, this won't work on Windows.
]]

function executeExiftool (filelist, extension)
  local myPath = _PLUGIN.path
  local pexiftool = LrPathUtils.child(myPath, "pexiftool.sh")
  local formatFile1 = LrPathUtils.child(myPath, "common.tags")
  local formatFile2 = LrPathUtils.child(myPath, extension .. ".tags")
  local uuid = LrUUID.generateUUID ()
  filelistFile = LrPathUtils.child (LrPathUtils.getStandardFilePath ("temp"), uuid .. ".files")
  f = io.open(filelistFile, "w")
  if nil ~= f then
    f:write(filelist)
    f:flush()
    f:close()
  end
  local commandLine = pexiftool .. ' "' .. filelistFile .. '" -q -q -m -ext '.. extension .. ' -p "' .. formatFile1 .. '"'
  if LrFileUtils.exists(formatFile2) then
    commandLine = commandLine .. ' -p "' .. formatFile2 .. '"'
  end
  -- commandLine = commandLine .. ' -@ "' .. filelistFile .. '"'
  outFile = LrPathUtils.child (LrPathUtils.getStandardFilePath ("temp"), uuid .. ".out")
  errFile = LrPathUtils.child (LrPathUtils.getStandardFilePath ("temp"), uuid .. ".err")
  commandLine = commandLine .. ' > "' .. outFile .. '"' .. ' 2>"' .. errFile .. '"'
  myLogger:trace("Command: ".. commandLine)
  local exitStatus = LrTasks.execute (commandLine)
  
  local output, errOutput = "", ""
  local success = false
  success, output = pcall (LrFileUtils.readFile, outFile)
  success, errOutput = pcall (LrFileUtils.readFile, errFile)
  --success = pcall (LrFileUtils.delete, fileListFile)
  --success = pcall (LrFileUtils.delete, outFile)
  --success = pcall (LrFileUtils.delete, errFile)
  
  return exitStatus, output, errOutput
end
