return {

	LrSdkVersion = 3.0,
	LrSdkMinimumVersion = 3.0,
	LrPluginName = "Better Import",
	LrToolkitIdentifier = 'uk.co.richardkchapman.betterimport',
    LrPluginInfoProvider="PluginInfoProvider.lua",
    LrPluginInfoUrl = "https://roxieX.website",
    LrInitPlugin = "PluginInit.lua",
    LrMetadataProvider= "CustomMetadata.lua",
    XLrMetadataTagsetFactory = "Tagset.lua",
     
	LrExportMenuItems = {
	  {	title       = "Read extra EXIF...",  -- in File > Plug-in Extras
		file        = "UpdateEXIF.lua",
		enabledWhen = "photosAvailable",
	  },
	  {
		title       = "Propogate flags into stacks...",  -- in File > Plug-in Extras
		file        = "StackPusher.lua",
		enabledWhen = "photosAvailable",  -- probably not
	  },
	  {
		title       = "Autostack by sequence...",  -- in File > Plug-in Extras
		file        = "AutoStack.lua",
		enabledWhen = "photosAvailable",  -- probably not
	  },
	  {
		title       = "Open and select stack...",  -- in File > Plug-in Extras
		file        = "ExpandStack.lua",
		enabledWhen = "photosAvailable",  -- probably not
	  },
--[[	  {
		title       = "Fix collection...",  -- in File > Plug-in Extras
		file        = "FixCollection.lua",
		enabledWhen = "photosAvailable",  -- probably not
	  },
	  {
		title       = "Find not in collection...",  -- in File > Plug-in Extras
		file        = "FindNotInCollection.lua",
		enabledWhen = "photosAvailable",  -- probably not
	  },
	  --]]
	},

	VERSION = {
		display = "0.1"
	},
}