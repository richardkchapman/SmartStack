
local LrApplication = import( "LrApplication" )
local LrErrors      = import( "LrErrors" )
local LrDialogs     = import( "LrDialogs" )
local LrTasks       = import( "LrTasks" )
local prefs         = import( "LrPrefs" ).prefsForPlugin()
local LrLogger      = import( "LrLogger" )
local spLogger      = LrLogger( "SPLogger" )

local function gpsDifferent(a,b)
  if a == nil or next(a) == nil then
    return b == nil or next(b) == nil
  end
  if b == nil or next(b) == nil then
    return true
  end
  return a.lattitude ~= b.lattitude or a.longitude ~= b.longitude
end

spLogger:enable( "logfile" )

spLogger:trace("======= spLogger started " .. os.date() .. " =======")

LrTasks.startAsyncTask(function()
  local catalog = LrApplication.activeCatalog()
  catalog:withWriteAccessDo("Propagating labels", function()
    local singleTarget = catalog:getTargetPhoto()
    if singleTarget == nil then
      spLogger:trace("No photo selected - did they mean all?")
      if "cancel" == LrDialogs.confirm("No photo selected", "Do you want to run on all visible photos?") then
        return 
      end
    end
    local target = catalog.targetPhotos
    spLogger:trace("Number of targets: " .. #target)
    if #target == 1 and singleTarget ~= nil and not singleTarget:getRawMetadata("isInStackInFolder") then
      spLogger:trace("Single photo selected - did they mean all?")
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
        spLogger:trace("Top file: " .. photoPath)
        stacksDone = stacksDone + 1
        local buddies = photo:getRawMetadata("stackInFolderMembers")
        local label = photo:getRawMetadata("colorNameForLabel")
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
            if buddy:getRawMetadata("colorNameForLabel") ~= label then
                propsUpdated = propsUpdated + 1
                spLogger:trace("Updated label")
                buddy:setRawMetadata("colorNameForLabel", label);
            end
            local buddygps = buddy:getRawMetadata("gps")
            if gpsDifferent(gps, buddygps) or buddy:getRawMetadata("gpsAltitude") ~= altitude then
              propsUpdated = propsUpdated + 1
              spLogger:trace("Updated gps")
              buddy:setRawMetadata("gps", gps);
              buddy:setRawMetadata("gpsAltitude", altitude);
            end
            local allkeys = "location|city|stateProvince|country|isoCountryCode"
            for key in allkeys:gmatch('[^|]+') do
              topval = photo:getFormattedMetadata(key)
              if buddy:getFormattedMetadata(key) ~= topval then
                propsUpdated = propsUpdated + 1
                spLogger:trace("Updated "..key)
                buddy:setRawMetadata(key, topval);
            end
            end
            -- keywords will need more thought for merge cases
            if #keywords > 0 and #buddy:getRawMetadata("keywords") == 0 then
              spLogger:trace("Updated keywords")
              propsUpdated = propsUpdated + 1
              for i,keyword in ipairs(keywords) do
                buddy:addKeyword(keyword);
              end
            end
            if propsUpdated ~= 0 then
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
