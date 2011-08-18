The /global directory is here so that you can have custom error
messages.  These must be static .html files and must be referenced in
the AOLserver .ini file as follows:

[ns/server/foobar]
PageRoot=/web/foobar/www
DirectoryFile=index.tcl, index.adp, index.html, index.htm
Webmaster=bigloser@yourdomain.com
NoticeBgColor=#ffffff
EnableTclPages=On
ForbiddenResponse=/global/forbidden.html
NotFoundResponse=/global/file-not-found.html
ServerBusyResponse=/global/server-busy.html
ServerInternalErrorResponse=/global/error.html
UnauthorizedResponse=/global/unauthorized.html
