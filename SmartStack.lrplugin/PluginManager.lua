 local LrView = import "LrView"
 local LrHttp = import "LrHttp"
 local app = import 'LrApplication'
 local LrDialogs = import "LrDialogs"
 local LrPathUtils = import 'LrPathUtils'
 local LrBinding = import "LrBinding"
 local LrFunctionContext = import 'LrFunctionContext'
 
 PluginManager = {}
 
 function PluginManager.sectionsForTopOfDialog( viewFactory, propertyTable )
   return {}
 end
 function PluginManager.sectionsForBottomOfDialog( viewFactory, propertyTable )
   return {}
 end
 