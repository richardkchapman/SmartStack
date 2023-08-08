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

myLogger:trace("======= FixCollection started " .. os.date() .. " =======")

LrTasks.startAsyncTask(
  function()
    -- Should I unstack first?
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
      if "cancel" == LrDialogs.confirm("Single photo selected", "Do you want to run on all visible photos?") then
        return 
      end
      target = catalog:getMultipleSelectedOrAllPhotos()
    end
    local candidates = {}
    bad = 0
    fixable = 0
    catalog:withWriteAccessDo("Read metadata from exif",
      function()
        for i,photo in ipairs(target) do
          local oldcollections = photo:getContainedCollections()
          if #oldcollections == 0 then
            bad = bad + 1
            candidates[#candidates+1] = photo
          else
            local ok = false
            for i,collection in ipairs(oldcollections) do
              local Y = collection:getName():match("^([0-9][0-9][0-9][0-9])")
              if Y~=nil then
                ok = true
                break
              end
            end
            if not ok then
              bad = bad + 1
              candidates[#candidates+1] = photo
            end  
          end
        end
      end
    )
    if #candidates then
      catalog:setSelectedPhotos(candidates[1], candidates)
    else
      catalog:setSelectedPhotos(nil, {})
    end
    LrDialogs.message(#target .. " files checked, ".. bad .. " bad files found",  fixable .. " could be fixed", "info")
end
)

