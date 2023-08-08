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

myLogger:trace("======= Update EXIF " .. os.date() .. " =======")

-- LrTasks.startAsyncTask(function() groupSelected() end)

LrTasks.startAsyncTask(
  function()
    local catalog = LrApplication.activeCatalog()
    local singleTarget = catalog:getTargetPhoto()
    if singleTarget == nil then
      myLogger:trace("No photo selected - did they mean all?")
      if "cancel" == LrDialogs.confirm("No photo selected", "Do you want to run on all visible photos?") then
        return 
      end
    end
    local target = catalog.targetPhotos
    myLogger:trace("Number of targets: " .. #target)
    if #target == 1 and singleTarget ~= nil then
      myLogger:trace("Single photo selected - did they mean all?")
      local reply = LrDialogs.confirm("Single photo selected", "Do you want to run on all visible photos?", "All", "Cancel", "One")
      myLogger:trace("Reply: " .. reply)
      if "cancel" == reply then
        return 
      elseif "ok" == reply then
        target = catalog:getMultipleSelectedOrAllPhotos()
      end
    end
    local allfiles = {}
    for i,photo in ipairs(target) do
      local photoPath = photo.path
      myLogger:trace("photoPath to process: " .. photoPath)
      local ext = LrPathUtils.extension(photoPath)
      if allfiles[ext]==nil then
        allfiles[ext]=''
      end
      allfiles[ext] = allfiles[ext] .. photoPath .. '\n'
    end
    -- myLogger:trace("allfiles is: " .. table_to_string(allfiles))
    local stdout = ''
    for ext, files in pairs(allfiles) do
      -- If I was feeling brave I would run all exiftool jobs in parallel
      -- there's code in Rob Cole's framework that might help but do I want to go there?
      -- Simpler is to use pexiftool.sh to get some parallelism within large lists (at the expense of preserving order)
      myLogger:trace("Processing files with extension " .. ext)
      local status, lstdout, lstderr = executeExiftool(files, ext)
      stdout = stdout .. lstdout
    end
    catalog:withWriteAccessDo("Read metadata from exif",
      function(context)
        local currentPhoto = nil
        local changesThisFile = 0
        local unchangedThisFile = 0
        local filesUpdated = 0
        local filesUnchanged = 0
        local filesNoProps = 0
        for s in stdout:gmatch("[^\r\n]+") do
          myLogger:trace(s)
          local propname,value = s:match("([^:]+):(.*)")
          myLogger:trace(propname .. ':' .. value)
          if propname ~= nil and value ~= nil then
            if propname == "_source" then
              if currentPhoto ~= nil then
                myLogger:trace(changesThisFile .. " value(s) changed, " .. unchangedThisFile .. " value(s) already set")
                if changesThisFile > 0 then
                  filesUpdated = filesUpdated + 1
                elseif unchangedThisFile then
                  filesUnchanged = filesUnchanged + 1
                else
                  filesNoProps = filesNoProps + 1
                end
              end
              currentPhoto = catalog:findPhotoByPath(value)
              myLogger:trace("Updating " .. value)
              changesThisFile = 0
              unchangedThisFile = 0
            elseif propname:sub(1,1) ~= '_' then
              oldvalue,err = currentPhoto:getPropertyForPlugin(_PLUGIN,propname,nil,true)
              if err then
                myLogger:trace("error reading property " .. propname .. ": " .. err)
              elseif oldvalue ~= value then
                myLogger:trace("setting " .. propname .. " to ".. value)
                currentPhoto:setPropertyForPlugin(_PLUGIN,propname,value)
                changesThisFile = changesThisFile + 1
              else
                myLogger:trace(propname .. " already set to ".. value)
                unchangedThisFile = unchangedThisFile + 1
              end
            end
          end
        end
        if currentPhoto ~= nil then
          myLogger:trace(changesThisFile .. " value(s) changed, " .. unchangedThisFile .. " value(s) already set")
          if changesThisFile > 0 then
            filesUpdated = filesUpdated + 1
          elseif unchangedThisFile then
            filesUnchanged = filesUnchanged + 1
          else
            filesNoProps = filesNoProps + 1
          end
        end
        local message = ''
        if filesUpdated ~= 0 then
          message = message .. filesUpdated .. " file"
          if (filesUpdated ~= 1) then
            message = message .. 's'
          end
          message = message .. " updated. "
        end
        if filesUnchanged ~= 0 then
          message = message .. filesUnchanged .. " file"
          if (filesUnchanged ~= 1) then
            message = message .. 's'
          end
          message = message .. " were unchanged. "
        end
        if filesNoProps ~= 0 then
          message = message .. filesNoProps .. " file"
          if (filesNoProps ~= 1) then
            message = message .. 's'
          end
          message = message .. " had no additional properties detected."
        end
        LrDialogs.message(filesUpdated+filesUnchanged+filesNoProps .. " files processed", message, "info")
      end
    ) 
  end
)