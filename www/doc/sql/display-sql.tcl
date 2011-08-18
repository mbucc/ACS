# $Id: display-sql.tcl,v 3.0 2000/02/06 03:36:57 ron Exp $
# display-sql.tcl
#
# by philg on 12/19/98
# 
# enables user to see a .sql file without encountering the 
# AOLserver's db module magic (offering to load the SQL into a database) 
#
# patched by philg at Jeff Banks's request on 12/5/99
# to close the security hole whereby a client adds extra form
# vars
# 

set_form_variables

# url (full relative path)

# this is normally a password-protected page, but to be safe let's
# check the incoming URL for ".." to make sure that someone isn't 
# doing 
# https://photo.net/doc/sql/display-sql.tcl?url=/../../../../etc/passwd
# for example

if { [string match "*..*" $url] } {
    ad_return_error "Can't back up beyond the pageroot" "You can't use display-sql.tcl to look at files underneath the pageroot."
    return
} 

ns_returnfile 200 text/plain "[ns_info pageroot]$url"
