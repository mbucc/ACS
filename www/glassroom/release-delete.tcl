# $Id: release-delete.tcl,v 3.0.4.1 2000/04/28 15:10:51 carsten Exp $
# release-delete.tcl -- confirm the removal of a software release from glassroom_releases




set_form_variables

# Expects release_id


if { [ad_read_only_p] } {
    ad_return_read_only_maintenance_message
    return
}


# check for user

set user_id [ad_verify_and_get_user_id]

if { $user_id == 0 } {
    ad_returnredirect "/register.tcl?return_url=[ns_urlencode [ns_conn url]]"
    return
}




#snarf the release name

set db [ns_db gethandle]

set select_sql "
select release_name
  from glassroom_releases
 where release_id=$release_id"

set release_name [database_to_tcl_string_or_null $db $select_sql]

ns_db releasehandle $db

# if there's nothing there, it might have been deleted already
if { [empty_string_p $release_name] } {
    ad_returnredirect index.tcl
}


#emit the page contents

ReturnHeaders

ns_write "[ad_header "Delete \"$release_name\""]

<h2>Delete \"$release_name\"</h2>
in [ad_context_bar [list index.tcl Glassroom] [list release-view.tcl?[export_url_vars release_id] "View Release"] "Delete Release"]
<hr>

Are you sure you want to delete this release?

<ul>
   <li> <a href=\"release-delete-2.tcl?[export_url_vars release_id]\">yes, I'm sure</a>
        <br><br>

   <li> <a href=\"release-view.tcl?[export_url_vars release_id]\">no, let me look at the release info again</a>
</ul>

[glassroom_footer]
"





