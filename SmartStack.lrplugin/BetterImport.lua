local LrApplication = import( "LrApplication" )
local LrErrors      = import( "LrErrors" )
local LrPathUtils   = import( "LrPathUtils" )
local LrFileUtils   = import( "LrFileUtils" )
local LrDialogs     = import( "LrDialogs" )
local LrTasks       = import( "LrTasks" )
local LrUUID        = import( "LrUUID" )
local prefs         = import( "LrPrefs" ).prefsForPlugin()
local LrLogger      = import( "LrLogger" )
 
require 'exiftool.lua'

--[[
  This was going to be a better importer, that included setting more info from metagata and using it to group files from a stack.
  But Lightroom API only has an "import one file" function and it is painfully slow.

  So new approach will be to do the extra metadata after import. I have found a hack that allows me to group selected files
  when running on Mac

  
myLogger:trace("======= Better Import started " .. os.date() .. " =======")

LrTasks.startAsyncTask(
  function()
    local catalog = LrApplication.activeCatalog()
    local allfiles = {}
    for photoPath in LrFileUtils.recursiveFiles('/Volumes/OM SYSTEM/DCIM') do
      myLogger:trace("photoPath to process: " .. photoPath)
      local ext = LrPathUtils.extension(photoPath):lower()
      if allfiles[ext]==nil then
        allfiles[ext]=''
      end
      allfiles[ext] = allfiles[ext] .. photoPath .. '\n'
    end
    local stdout = ''
    for ext, files in pairs(allfiles) do
      -- If I was feeling brave I would run all exiftool jobs in parallel
      -- there's code in Rob Cole's framework that might help but do I want to go there?
      -- Simpler is to use pexiftool.sh to get some parallelism within large lists (at the expense of preserving order)
      myLogger:trace("Processing files with extension " .. ext)
      local status, lstdout, lstderr = executeExiftool(files, ext)
      stdout = stdout .. lstdout
    end
    allfiles = {}
    local fileinfo = {}
    for s in stdout:gmatch("[^\r\n]+") do
      local propname,value = s:match("([^:]+):(.*)")
      if propname ~= nil and value ~= nil then
        if propname == "_source" then
          if fileinfo._source ~= nil then
            allfiles[#allfiles+1] = fileinfo
          else
            myLogger:trace(#fileinfo .. table_to_string(fileinfo))
          end
          fileinfo = {}
        end
        fileinfo[propname] = value
      end
    end
    allfiles[#allfiles+1] = fileinfo
    table.sort(allfiles, function(a,b) return a._source < b._source end)
    local lastdir = ''
    local basedir = '/Users/rchapman/Photos'
    catalog:withProlongedWriteAccessDo(
      {title="Import files from SD card",
       pluginName="Better Import",
       func = function(context)
        for i,file in ipairs(allfiles) do
          local Y,M,D,h,m,s = file._shotdate:match("([0-9]+):([0-9]+):([0-9]+) ([0-9]+):([0-9]+):([0-9]+)")
          local dest = basedir
          dest = LrPathUtils.child(dest, Y)
          dest = LrPathUtils.child(dest, Y..'-'..M)
          dest = LrPathUtils.child(dest, Y..'-'..M..'-'..D)
          if (dest ~= lastdir) then
            myLogger:trace("Create directory" .. dest)
            lastdir = dest
            LrFileUtils.createAllDirectories(dest)
          end
          dest = LrPathUtils.child(dest, Y..M..D..'-'..h..m..s)
          local fileno = file._filenum
          if fileno ~= nil then
            dest = dest .. '-' .. fileno
          end
          local source = file._source
          local ext = LrPathUtils.extension(source):lower()
          dest = LrPathUtils.addExtension(dest, ext)
          myLogger:trace("LrFileUtils.copy(" .. source .. ", " .. dest ..')')
          LrFileUtils.copy(source,dest)
          catalog:addPhoto(dest)
        end
      end
    }
    )
  end
)

