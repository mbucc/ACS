# /www/download/admin/download-edit-2.tcl
ad_page_contract {
    processes the new information for a download file

    @param download_id the ID of the file being edited
    @param download_name the new name
    @param description the new description
    @param html_p is the description in html?
    @param scope
    @param group_id

    @author ahmeds@mit.edu
    @creation-date 4 Jan 2000
    @cvs-id download-edit-2.tcl,v 3.8.2.4 2000/07/21 03:59:18 ron Exp
} {
    download_name:trim,notnull
    description:trim,html
    html_p
    download_id:integer,notnull
    scope:optional
    group_id:optional,integer
}

# -----------------------------------------------------------------------------

ad_scope_error_check

ad_scope_authorize $scope admin group_admin none

set user_id [download_admin_authorize $download_id]

page_validation {
    if {[string length $description] > 4000} {
	error "\"description\" is too long\n"
    }
}

# Now we'll do the update of the downloads table.
# KS - I don't understand why we are inserting sysdate here
if [catch {db_dml download_update "update downloads 
      set creation_date = sysdate, 
      creation_user = :user_id, 
      download_name = :download_name, 
      description = :description, 
      html_p = :html_p
      where download_id = :download_id"} errmsg] {

# Oracle choked on the update
    ad_scope_return_error "Error in update" "We were unable to do your update in the database. Here is the error that was returned:
<p>
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>"
    return
}

ad_returnredirect download-view?[export_url_scope_vars download_id]

