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

myLogger:trace("======= NatureStats started " .. os.date() .. " =======")

function getTopKeyword(kwd)
  while true do
    local parent = kwd:getParent()
    if parent == nil then
      return kwd
    end
    kwd = parent
  end
end

function getNatureCategory(kwd)
  while true do
    local parent = kwd:getParent()
    if parent == nil then
      return nil
    elseif parent:getName()=="Nature" then
      return kwd
    end
    kwd = parent
  end
end

function table_to_stats(seen)
  local result = ""
  for k, v in pairs(seen) do
    result = result..k:getName()..": "..v.."\n"
  end
  return result
end

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
      if "cancel" == LrDialogs.confirm("Single photo selected", "Do you want to run on all visible photos?") then
        return 
      end
      target = catalog:getMultipleSelectedOrAllPhotos()
    end
    local seen = {}
    local families = {}
    local numSeen = 0
    for i,photo in ipairs(target) do
      local keywords = photo:getRawMetadata("keywords")
      for j,keyword in ipairs(keywords) do
        local top = getTopKeyword(keyword)
        if top:getName() == "Nature" then
          local family = getNatureCategory(keyword)
          if family==nil then
            myLogger:trace("Keyword "..keyword:getName().." has no family on photo " .. photo.path)
            family = keyword
          end
          local familyName = family:getName()
          if keyword:getName() ~= "Unidentified" and familyName ~= "Plants" and familyName ~= "Fungi" then
            if seen[keyword] == nil then
              seen[keyword] = 1
              numSeen = numSeen + 1
              families[family] = (families[family] or 0) + 1
            else
              seen[keyword] = seen[keyword] + 1
            end
          end
        end
      end
    end
    myLogger:trace("Seen: " .. numSeen .. " species\n\n" .. table_to_stats(seen))
    myLogger:trace("Families: " .. table_to_stats(families))
    if numSeen < 10 then
      LrDialogs.message("Stats", numSeen .. " species\n\n" .. table_to_stats(seen), "info")
    else
      LrDialogs.message("Stats", numSeen .. " species\n\n" .. table_to_stats(families), "info")
    end
  end
)

