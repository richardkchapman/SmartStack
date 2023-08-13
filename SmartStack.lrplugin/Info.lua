return {

	LrSdkVersion = 3.0,
	LrSdkMinimumVersion = 3.0,
	LrPluginName = "Smart Stack",
	LrToolkitIdentifier = 'uk.co.richardkchapman.smartstack',
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
		title       = "Propagate flags into stacks...",  -- in File > Plug-in Extras
		file        = "StackPusher.lua",
		enabledWhen = "photosAvailable",
	  },
	  {
		title       = "Autostack by sequence...",  -- in File > Plug-in Extras
		file        = "AutoStack.lua",
		enabledWhen = "photosAvailable",
	  },
	  {
		title       = "Open and select stack...",  -- in File > Plug-in Extras
		file        = "ExpandStack.lua",
		enabledWhen = "photosAvailable",
	  },
	  {
		title       = "Calculate nature stats...",  -- in File > Plug-in Extras
		file        = "NatureStats.lua",
		enabledWhen = "photosAvailable",
	  },
	},

	VERSION = {
		display = "0.1"
	},
}