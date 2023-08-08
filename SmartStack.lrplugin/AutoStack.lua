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

myLogger:trace("======= AutoStack started " .. os.date() .. " =======")

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
    for i,photo in ipairs(target) do
      local photoPath = photo.path
      local dateTime = photo:getRawMetadata('dateTimeOriginal')
      local filenum,err1 = photo:getPropertyForPlugin(_PLUGIN,'filenum',nil,true)
      local sequence,err2 = photo:getPropertyForPlugin(_PLUGIN,'sequence',nil,true)
      if err1 ~= nil then
        myLogger:trace(photoPath .. ': ' .. err1)
      end
      if err2 ~= nil then
        myLogger:trace(photoPath .. ': ' .. err2)
      end
      if filenum ~= nil and sequence ~= nil then
        candidates[#candidates+1] = { path=photoPath, date=dateTime, filenum=tonumber(filenum), sequence=tonumber(sequence)}
      end
    end
    if #candidates == 0 then
      LrDialogs.message("No files with sequence info found - do you need to run UpdateExif?", nil, "error")
      return
    end
    myLogger:trace("Finished gathering")
    table.sort(candidates, function(a,b)
                            if a.date == b.date then
                              return a.filenum < b.filenum
                            else
                              return a.date < b.date
                            end
                           end)
    local groups = {}
    local group = {}
    local nextseq = 0
    local nextfile = 0
    local prevfile = 0
    for i,c in ipairs(candidates) do
      --myLogger:trace("Checking "..table_to_string(c))
      myLogger:trace(c.sequence..' '..c.filenum)
      if c.filenum <= prevfile then
        myLogger:trace("Out of sequence")  -- can happen at a card change
      end
      prevfile = c.filenum
      if c.sequence==1 then  -- MORE - would be better to say 'if lastnum + sequence - lastsequence == thisnum, then same seq, else new'
        if #group > 1 then
          groups[#groups+1] = group
        end
        group = {c}
        nextfile = c.filenum+1
        nextseq = c.sequence+1
      elseif c.sequence==nextseq and c.filenum==nextfile then
        group[#group+1] = c
        nextfile = c.filenum+1
        nextseq = c.sequence+1
      else
        if #group > 1 then
          groups[#groups+1] = group
        end
        group = {}
      end
    end
    if #group > 1 then
      groups[#groups+1] = group
    end
    if #groups==0 then
      LrDialogs.message("No sequences found.", nil, "info")
      return
    elseif "cancel" == LrDialogs.confirm(#groups .. " sequences found", "Group them now?") then
      return
    end
    for i,group in ipairs(groups) do
      groupPhotos = {}
      for j,file in ipairs(group) do
        local photo = catalog:findPhotoByPath(file.path)
        assert(photo ~= nil)
        groupPhotos[#groupPhotos+1] = photo
      end
      catalog:setSelectedPhotos(groupPhotos[1], groupPhotos)
      groupSelected()
    end
  end
)

