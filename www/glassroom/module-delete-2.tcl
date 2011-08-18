# $Id: module-delete-2.tcl,v 3.0.4.1 2000/04/28 15:10:44 carsten Exp $
# module-delete-2.tcl -- remove a module from glassroom_modules
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



# snarf the module name

set db [ns_db gethandle]

set select_sql "
select module_name || ' ' || current_version
  from glassroom_modules
 where module_id=$module_id"

set module_name [database_to_tcl_string_or_null $db $select_sql]


# emit the page contents

ReturnHeaders

ns_write "[ad_header "Module \"$module_name\" Deleted"]

<h2>Module \"$module_name\" Deleted</h2>
<hr>
"

set count [database_to_tcl_string $db "select count(*) from glassroom_modules where module_id=$module_id"]

if { $count > 0 } {
    set db2 [ns_db gethandle subquery]

    set select_sql "select release_id from glassroom_releases where module_id = $module_id"
    set selection [ns_db select $db $select_sql]

    while { [ns_db getrow $db $selection] } {
	set_variables_after_query

	ns_db dml $db2 "delete from glassroom_releases where release_id = $release_id"
    }

    ns_db releasehandle $db2

}

set delete_sql "delete from glassroom_modules where module_id=$module_id"

#!!! what to do if delete fails...

ns_db dml $db $delete_sql

ns_db releasehandle $db


ns_write "
Deletion of $module_name confirmed.

<p>


<a href=index.tcl>Return to the Glass Room</a>

[glassroom_footer]
"
