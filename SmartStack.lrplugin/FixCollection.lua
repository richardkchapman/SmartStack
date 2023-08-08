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
          local photoPath = photo.path
          local photoDir = LrPathUtils.parent(photoPath)
          if photo:getRawMetadata('isVirtualCopy')
--          if photoDir=='/Users/rchapman/Pictures/Lightroom/Mobile Downloads.lrdata' or 
--             photoDir=='/Users/rchapman/Pictures/Lightroom/Mobile Downloads.lrdata/downloaded-smart-previews'
          then
            local filename = LrPathUtils.leafName(photoPath)
            bad = bad + 1
            -- MORE would be better to get it from the file metadata really, in case name is wrong
            local Y,M,D,h,m,s = filename:match("^20([0-9][0-9])([0-9][0-9])([0-9][0-9])-([0-9][0-9])([0-9][0-9])([0-9][0-9])")
            if D==nil then
              myLogger:trace("Failed to parse "..filename)
            else
              local expectedPath = '/Users/rchapman/More Photos/20' .. Y..'/'..'20'..Y..'-'..M..'/20'..Y..'-'..M..'-'..D
              local expectedFile = LrPathUtils.child(expectedPath, filename)
              local shoulduse = catalog:findPhotoByPath(expectedFile)
              if shoulduse == nil then
                expectedPath = '/Users/rchapman/More Photos/20' .. Y..'/'..M..'/20'..Y..'-'..M..'-'..D
                expectedFile = LrPathUtils.child(expectedPath, filename)
                shoulduse = catalog:findPhotoByPath(expectedFile)
              end
              if shoulduse ~= nil then
                fixable = fixable + 1
                local collections = shoulduse:getContainedCollections()
                local oldcollections = photo:getContainedCollections()
                for f,collection in ipairs(oldcollections) do
                  myLogger:trace("Target collection: "..oldcollections[1]:getName())
                  collection:addPhotos({shoulduse})
                  collection:removePhotos({photo})
                end
              else
                myLogger:trace(expectedFile .. " not found")
              end
            end
          end
        end
      end
    )
    LrDialogs.message(#target .. " files checked, ".. bad .. " bad files found",  fixable .. " could be fixed", "info")
end
)

