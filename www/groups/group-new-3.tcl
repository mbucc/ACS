# $Id: group-new-3.tcl,v 3.0.4.2 2000/04/28 15:10:56 carsten Exp $
# File: /groups/group-new-3.tcl
# Date: mid-1998
# Contact: teadams@mit.edu, tarik@mit.edu
# Purpose: creation of a new user group
# 
# Note: groups_public_dir, group_type_url_p, group_type, group_type_pretty_name, 
#       group_type_pretty_plural, group_public_root_url and group_admin_root_url
#       are set in this environment by ug_serve_group_pages. if group_type_url_p
#       is 0, then group_type, group_type_pretty_name and group_type_pretty_plural
#       are empty strings)

set user_id [ad_verify_and_get_user_id]

set_the_usual_form_variables
# everything for a new group, including extra fields and the group_id
# maybe return_url

if {$user_id == 0} {
   ad_returnredirect "/register/index.tcl?return_url=[ad_urlencode "[ug_url]/group-new-2.tcl?group_type=$group_type"]"
    return
}
if { ![exists_and_not_null parent_group_id] } {
    set parent_group_id ""
    set QQparent_group_id ""
}

# Structure of this script:
#   check inputs 
#   prepare transaction
#   if transaction fails, try to figure out if it 
#     failed because the group_id was already in there
#     (i.e., user hit submit twice)
#   if transaction succeeds, redirect user to group home page 

set db [ns_db gethandle]

set exception_text ""
set exception_count 0

if { ![exists_and_not_null group_name] } {
    append exception_text "<li>Please give us a name for the group.\n"
    incr exception_count
}

if { ![exists_and_not_null short_name] } {
    append exception_text "<li>Please give us a short name for the group.\n"
    incr exception_count
}

# let's check constraints imposed on the extra columns

set non_null_columns [database_to_tcl_list_list $db "select column_name, pretty_name
from user_group_type_fields
where group_type = '$QQgroup_type'
and lower(column_extra) like '%not null%'"]

foreach column_spec $non_null_columns {
    set column_name [lindex $column_spec 0]
    set column_pretty_name [lindex $column_spec 1]
    if { ![info exists $column_name] || [empty_string_p [set $column_name]] } {
	append exception_text "<li>Please enter a value for $column_name.\n"
	incr exception_count
    }
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

# everything checks out 

if { [ad_administrator_p $db $user_id] || ([database_to_tcl_string $db "select approval_policy from user_group_types where group_type = '$QQgroup_type'"] == "open") } {
    set approved_p "t"
} else {
    set approved_p "f"
}

set insert_for_user_groups "insert into user_groups
(group_id, group_type, group_name, short_name, admin_email, creation_user, creation_ip_address, approved_p, new_member_policy, spam_policy, parent_group_id, registration_date)
values
($group_id,'$QQgroup_type','$QQgroup_name', '$QQshort_name', '$QQadmin_email', $user_id,'[ns_conn peeraddr]', '$approved_p', '$QQnew_member_policy', '$QQspam_policy', '$QQparent_group_id', sysdate)"

set n_custom_fields [database_to_tcl_string $db "select count(*) from user_group_type_fields where group_type = '$QQgroup_type'"]

if { $n_custom_fields > 0 } {
    set helper_table_name [ad_user_group_helper_table_name $group_type]
    # let's use the utilities.tcl procedure util_prepare_insert
    # for this we need to produce an ns_conn form-style structure
    set helper_fields [ns_set new]
    foreach helper_column [database_to_tcl_list $db "select column_name from user_group_type_fields where group_type = '$QQgroup_type'"] {
	if [info exists $helper_column] {
	    ns_set put $helper_fields $helper_column [set $helper_column]
	}
    }
    if { [ns_set size $helper_fields] > 0 } {
	set insert_for_helper_table [util_prepare_insert $db $helper_table_name group_id $group_id $helper_fields]
    }
}

if { ![info exists return_url] } {
    set return_url "[ug_url]/[ad_urlencode $short_name]/"
}

if [catch { 
    ns_db dml $db "begin transaction"

    ns_db dml $db $insert_for_user_groups
    if [info exists insert_for_helper_table] {
	ns_db dml $db $insert_for_helper_table
    }

    # let's add all the modules to this groups, which are associated with this group type
    
    ns_db dml $db "
    insert into content_sections
    (section_id, scope, section_type, requires_registration_p, visibility, group_id, 
    section_key, module_key, section_pretty_name, enabled_p)
    select content_section_id_sequence.nextval, 'group', section_type_from_module_key(module_key), 'f', 'public', $group_id,
           module_key, module_key, pretty_name_from_module_key(module_key), 't'
    from user_group_type_modules_map
    where group_type='$QQgroup_type'
    "

    ns_db dml $db "end transaction" 
} errmsg] {
    # something went wrong
    ns_db dml $db "abort transaction" 

    set selection [ns_db 0or1row $db "select 1 from user_groups where group_id=$group_id"]
    if { ![empty_string_p $selection] } {
	# group was already in database, so we can assume that this was a double click
	ad_returnredirect $return_url
	return
    }

    set selection [ns_db 0or1row $db "select group_name as other_group_name from user_groups where short_name='$QQshort_name'"]
    if { ![empty_string_p $selection] } {
	set_variables_after_query

	incr exception_count
	set exception_text "
	<li>Short Name $short_name is already used by the group $other_group_name. Please choose different short name.
	"
	ad_return_complaint $exception_count $exception_text
	return
    }
    
    ad_return_error "database choked" "The database choked on your insert:
    <blockquote>
    <pre>
    $errmsg
    </pre>
    </blockquote>
    You can back up, edit your data, and try again"
    return
}

# insert went OK

ad_returnredirect $return_url
