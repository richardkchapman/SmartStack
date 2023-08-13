
local LrApplication = import( "LrApplication" )
local LrErrors      = import( "LrErrors" )
local LrDialogs     = import( "LrDialogs" )
local LrTasks       = import( "LrTasks" )
local prefs         = import( "LrPrefs" ).prefsForPlugin()
local LrLogger      = import( "LrLogger" )

require 'exiftool.lua'

local function gpsDifferent(a,b)
  if a == nil or next(a) == nil then
    return b == nil or next(b) == nil
  end
  if b == nil or next(b) == nil then
    return true
  end
  return a.lattitude ~= b.lattitude or a.longitude ~= b.longitude
end

myLogger:trace("======= Stack propagator started " .. os.date() .. " =======")

LrTasks.startAsyncTask(function()
  local catalog = LrApplication.activeCatalog()
  catalog:withWriteAccessDo("Propagating labels", function()
    local singleTarget = catalog:getTargetPhoto()
    if singleTarget == nil then
      myLogger:trace("No photo selected - did they mean all?")
      if "cancel" == LrDialogs.confirm("No photo selected", "Do you want to run on all visible photos?") then
        return 
      end
    end
    local target = catalog.targetPhotos
    myLogger:trace("Number of targets: " .. #target)
    if #target == 1 and singleTarget ~= nil and not singleTarget:getRawMetadata("isInStackInFolder") then
      myLogger:trace("Single photo selected - did they mean all?")
      if "cancel" == LrDialogs.confirm("Single photo selected", "Do you want to run on all visible photos?") then
        return 
      end
      target = catalog:getMultipleSelectedOrAllPhotos()
    end
    local stacksDone = 0
    local childrenChecked = 0
    local childrenUpdated = 0
    for i,photo in ipairs(target) do
      local photoPath = photo.path
      if photo:getRawMetadata("isInStackInFolder") and photo:getRawMetadata("stackPositionInFolder") == 1 then
        -- myLogger:trace("Top file: " .. photoPath)
        stacksDone = stacksDone + 1
        local buddies = photo:getRawMetadata("stackInFolderMembers")
        local label = photo:getFormattedMetadata("label")
        local gps = photo:getRawMetadata("gps")
        local altitude = photo:getRawMetadata("gpsAltitude")
        local keywords = photo:getRawMetadata("keywords")
        local topMetadata = photo:getRawMetadata(nil)
        for j,buddy in ipairs(buddies) do
          assert(j == buddy:getRawMetadata("stackPositionInFolder"))
          if j ~= 1 then
            local propsUpdated = 0
            childrenChecked = childrenChecked + 1
            local buddyPath = buddy:getRawMetadata("path")
            if buddy:getFormattedMetadata("label") ~= label then
                propsUpdated = propsUpdated + 1
                myLogger:trace("Updated label from " .. buddy:getFormattedMetadata("label") .. " to " .. label)
                buddy:setRawMetadata("label", label);
            end
            local buddygps = buddy:getRawMetadata("gps")
            if gpsDifferent(gps, buddygps) or buddy:getRawMetadata("gpsAltitude") ~= altitude then
              propsUpdated = propsUpdated + 1
              myLogger:trace("Updated gps")
              buddy:setRawMetadata("gps", gps);
              buddy:setRawMetadata("gpsAltitude", altitude);
            end
            local allkeys = "location|city|stateProvince|country|isoCountryCode"
            for key in allkeys:gmatch('[^|]+') do
              topval = photo:getFormattedMetadata(key)
              if buddy:getFormattedMetadata(key) ~= topval then
                propsUpdated = propsUpdated + 1
                myLogger:trace("Updated "..key)
                buddy:setRawMetadata(key, topval);
              end
            end
            -- keywords will need more thought for merge cases
            local buddyKeys = buddy:getRawMetadata("keywords")
            if table_to_string(keywords) ~= table_to_string(buddyKeys) then
              myLogger:trace("Updated keywords")
              propsUpdated = propsUpdated + 1
              -- MORE - we could make this bit conditional, if we wanted to preserve keywords on children that were not on top
              for i,keyword in ipairs(buddyKeys) do
                buddy:removeKeyword(keyword);
              end
              for i,keyword in ipairs(keywords) do
                buddy:addKeyword(keyword);
              end
            end
            if propsUpdated ~= 0 then
              myLogger:trace("Updated props for " .. buddy.path)
              childrenUpdated = childrenUpdated + 1
            end
          end
        end
      end
    end
    local message = stacksDone .. " stack"
    if (stacksDone ~= 1) then
      message = message .. 's'
    end
    message = message .. " and " .. childrenChecked .. ' child'
    if (childrenChecked ~= 1) then
      message = message .. 'ren'
    end
    message = message .. " files checked. "
    message = message .. childrenUpdated .. " file"
    if (childrenUpdated ~= 1) then
      message = message .. 's'
    end
    message = message .. " updated."
    LrDialogs.message("Checking complete", message, "info")
  end)  
end)
