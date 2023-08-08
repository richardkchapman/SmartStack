local LrApplication = import( "LrApplication" )
local LrApplicationView = import( "LrApplicationView" )
local LrErrors      = import( "LrErrors" )
local LrPathUtils   = import( "LrPathUtils" )
local LrFileUtils   = import( "LrFileUtils" )
local LrDialogs     = import( "LrDialogs" )
local LrTasks       = import( "LrTasks" )
local LrUUID        = import( "LrUUID" )
local prefs         = import( "LrPrefs" ).prefsForPlugin()
local LrLogger      = import( "LrLogger" )
 
require 'exiftool.lua'

LrTasks.startAsyncTask(function()
  myLogger:trace("Expanding")
  local catalog = LrApplication.activeCatalog()
  local photo = catalog:getTargetPhoto()
  if photo == nil then
    myLogger:trace("No photo selected")
    return 
  end
  if photo:getRawMetadata("isInStackInFolder") and photo:getRawMetadata("stackPositionInFolder") == 1 then
    local buddies = photo:getRawMetadata("stackInFolderMembers")
    expandStack()
    LrTasks.sleep(0.3)
    catalog:setSelectedPhotos(photo, buddies)
    LrApplicationView.toggleLoupe()
  end
end)