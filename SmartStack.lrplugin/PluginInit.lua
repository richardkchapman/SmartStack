 local LrPathUtils = import 'LrPathUtils'
 local LrLogger = import 'LrLogger'
 local myLogger = LrLogger( 'BetterImport' )
 
 local prefs = import 'LrPrefs'.prefsForPlugin()
 if true or prefs['debug'] == 'logfile' then
     myLogger:enable('logfile')
 else
     myLogger:disable()
 end
 