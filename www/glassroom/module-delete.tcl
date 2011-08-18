# $Id: module-delete.tcl,v 3.0.4.1 2000/04/28 15:10:45 carsten Exp $
# module-delete.tcl -- confirm the removal of a software module from glassroom_modules
#


set_form_variables

# Expects module_id


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



#snarf the module name

set db [ns_db gethandle]

set select_sql "
select module_name || ' ' || current_version
  from glassroom_modules
 where module_id=$module_id"

set module_name [database_to_tcl_string_or_null $db $select_sql]


# if there's nothing there, it might have been deleted already
if { [empty_string_p $module_name] } {
    ad_returnredirect index.tcl
}


#emit the page contents

ReturnHeaders

ns_write "[ad_header "Delete \"$module_name\""]

<h2>Delete \"$module_name\"</h2>
in [ad_context_bar [list index.tcl Glassroom] [list module-view.tcl?[export_url_vars module_id] "View Module"] "Delete Module"]
<hr>

"

set count [database_to_tcl_string $db "select count(*) from glassroom_releases where module_id = $module_id"]

if { $count > 0 } {
    ns_write "Are you sure you want to delete this module and its associated releases?
<blockquote><ul>"
    set select_sql "select release_name, release_id from glassroom_releases where module_id = $module_id order by release_name"
    set selection [ns_db select $db $select_sql]
    while { [ns_db getrow $db $selection ] } {
	set_variables_after_query
	ns_write "      <li> <a href=\"release-view.tcl?[export_url_vars release_id]\">$release_name</a>"
    }
    ns_write "</ul></blockquote> <p>&nbsp;<p> "
} else {
    ns_write "Are you sure you want to delete this module?"
}





ns_db releasehandle $db


ns_write "

<ul>
   <li> <a href=\"module-delete-2.tcl?[export_url_vars module_id]\">yes, I'm sure</a>
        <br><br>

   <li> <a href=\"module-view.tcl?[export_url_vars module_id]\">no, let me look at the module info again</a>
</ul>

[glassroom_footer]
"





