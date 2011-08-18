# /www/download/download-edit-2.tcl
#
# Date:     01/04/2000
# Author :  ahmeds@mit.edu
# Purpose:  adds new downloadable file
#
# $Id: download-edit-2.tcl,v 3.0.6.3 2000/05/18 00:05:15 ron Exp $
# -----------------------------------------------------------------------------

set_the_usual_form_variables
# maybe scope, maybe scope related variables (group_id)
# download_name, description, html_p, download_id

ad_scope_error_check

set db [ns_db gethandle]
ad_scope_authorize $db $scope admin group_admin none

set user_id [download_admin_authorize $db $download_id]

# Radiobuttons and selects may give us trouble if none are selected
# The columns that might cause trouble are html_p
if ![info exists html_p] {
    set html_p ""
    set QQhtml_p ""
}

# Now check to see if the input is good as directed by the page designer

set exception_count 0
set exception_text ""

# we were directed to return an error for download_name
if {![info exists download_name] ||[empty_string_p $download_name]} {
    incr exception_count
    append exception_text "<li>You did not enter a value for download_name.<br>"
} 


if {[string length $description] > 4000} {
    incr exception_count
    append exception_text "<LI>\"description\" is too long\n"
}

if {$exception_count > 0} {
    ad_scope_return_complaint $exception_count $exception_text $db
    return
}

# So the input is good --
# Now we'll do the update of the downloads table.
if [catch {ns_db dml $db "update downloads 
      set creation_date = sysdate, 
      creation_user = $user_id, 
      download_name = '$QQdownload_name', 
      description = '$QQdescription', 
      html_p = '$QQhtml_p'
      where download_id = '$download_id'" } errmsg] {

# Oracle choked on the update
    ad_scope_return_error "Error in update" "We were unable to do your update in the database. Here is the error that was returned:
<p>
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>" $db
    return
}

ad_returnredirect download-view.tcl?[export_url_scope_vars download_id]


