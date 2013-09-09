#/groups/group-new-3.tcl
ad_page_contract {
    @cvs-id group-new-3.tcl,v 3.3.2.17 2001/01/10 21:17:39 khy Exp

    @param group_id the ID of the group
    @param group_name the name of the group
    @param spam_policy spam policy predicate
    @param short_name the short name of the group
    @param new_member_policy the new member policy
    @param parent_group_id the group_id of this group(optional)
    @param admin_email the admin's email address
 Purpose: creation of a new user group
 
 Note: groups_public_dir, group_type_url_p, group_type, group_type_pretty_name, 
       group_type_pretty_plural, group_public_root_url and group_admin_root_url
       are set in this environment by ug_serve_group_pages. if group_type_url_p
       is 0, then group_type, group_type_pretty_name and group_type_pretty_plural
       are empty strings)
} {
    group_id:notnull,naturalnum,verify
    {return_url "[ug_url]/[ad_urlencode $short_name]/"}
    {parent_group_id ""}
    {admin_email "[db_null]"}
    group_name:notnull
    short_name:notnull
    spam_policy:notnull
    new_member_policy:notnull
    group_type:notnull
    custom_fields:optional
    custom:array,optional
} -errors {
    group_name:notnull {Please give us a name for the group}
    short_name:notnull {Please give us a short name for the group}
}

set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    ad_returnredirect "/register/index?return_url=[ad_urlencode "[ug_url]/group-new-2?group_type=$group_type"]"
    return
}

if {![ad_allow_group_type_creation_p $user_id $group_type]} {
    ad_return_warning "Group Type Closed" "You are trying to create
    a new user group for a group type that is closed.  Only
    site-wide administrators can create a user group for a closed group type."
    return
}

# Structure of this script:
#   check inputs 
#   prepare transaction
#   if transaction fails, try to figure out if it 
#     failed because the group_id was already in there
#     (i.e., user hit submit twice)
#   if transaction succeeds, redirect user to group home page 

set exception_text ""
set exception_count 0

if { [db_string ug_long_name_check {
    select 1 as one from user_groups where group_name=:group_name
} -default 0] == 1 } {
    # duplicate group name.
    incr exception_count
    append exception_text "<li>The group name you specified, $group_name, is already taken.  Please use a different group name."
} 
if { [db_string ug_short_name_check {
    select 1 as one from user_groups where short_name=:short_name
} -default 0] == 1 } {
    # duplicate short name.
    incr exception_count
    append exception_text "<li>The short name you specified, $short_name, is already taken.  Please use a different short name."
}

# let's check constraints imposed on the extra columns

# cnk@arsdigita.com I am ignoring what vars are passed in from the
# previous page and instead using the meta data from the group
# type. Since group-new-2.tcl is constructed from this same meta
# date we are fine but should document this in case someone gets
# creative with the previous form.

# lets do some input validation based on the column type info from user_group_type_fields  
# WARNING this does not do check constraint violation checking

# In the same loop, construct the insert

set col_list "group_id"
set val_list ":group_id"

db_foreach get_extra_column_info "
select column_name, pretty_name, column_type, column_actual_type, column_extra
from user_group_type_fields
where group_type = :group_type" {

    # id not null columns and then check that we have input for them
    if { [regexp -nocase {not null} $column_extra ] } {
	if { $custom($column_name) == "" } { 
	    append exception_text "<li>Please enter a value for $column_name.\n"
	    incr exception_count
	}
    }
    
    if { [string match $column_type "special"] } {
	# we're ignoring special columns from touching the database
    } elseif { [string match $column_type "date"] } {
	# for date columns have to construct the date, and verify it is valid date 
	# grab the variables and put them in the col_name date array
	set ${column_name}(month) $custom(${column_name}.month)
	set ${column_name}(day) $custom(${column_name}.day)
	set ${column_name}(year) $custom(${column_name}.year)
	
	## try to construct the date
	if ![ad_page_contract_filter_proc_date $column_name $column_name] {
	    # date invalid - null is ok and would not choke here
	    append exception_text "<li>Please enter a valid date, including 4 digit year for $pretty_name"
	    incr exception_count 
	} else {
	    lappend col_list $column_name
	    lappend val_list "to_date('[set ${column_name}(date)]', 'YYYY-MM-DD')"
	}

    # check if number columns are numeric
    } elseif { [regexp -nocase {numeric|integer|number} $column_type ] } {
	if { ![empty_string_p $custom($column_name) ] && ![ad_var_type_check_number_p $custom($column_name)] } {
	    append exception_text "<li>Please enter a number for $column_name - no non-numeric characters at all.\n"
	    incr exception_count
	} else {
	    # construct the query
	    set $column_name $custom($column_name)
	    lappend col_list $column_name
	    lappend val_list ":$column_name"
	}

    # check lengths on char and varchar columns
    } elseif [ regexp {char\(([^)]*)} $column_actual_type match size ] {
	# col is a char or varchar, check length
	if { [string length $custom($column_name)] > $size } {
	    incr exception_count
	    append exception_text "<li>The text you entered for $pretty_name is too long to fit in the field, please edit it to get it below $size characters."
	} else {
	    # construct the query
	    set $column_name $custom($column_name)
	    lappend col_list $column_name
	    lappend val_list ":$column_name"
	}

    # not sure what type of column this might be but it slipped past our regexps
    } else {
	
	# construct the query
	set $column_name $custom($column_name)
	lappend col_list $column_name
	lappend val_list ":$column_name"
    }
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

# everything checks out, but check the approval policy. 

if { [ad_administrator_p $user_id] || ([db_string get_approval_policy "select approval_policy from user_group_types where group_type = :group_type"] == "open") } {
    set approved_p "t"
} else {
    set approved_p "f"
}

# set insert_for_user_groups ")"

set n_custom_fields [db_string get_cnt_from_ugtf "select count(*) from user_group_type_fields where group_type = :group_type"]

ns_log notice "custom fields: $n_custom_fields"

set helper_table_name [ad_user_group_helper_table_name $group_type]

if { $n_custom_fields > 0 } {
    set insert_for_helper_table "
    INSERT INTO $helper_table_name
    ([join $col_list ", "])
    VALUES
    ([join $val_list ", "])"
}



db_transaction {

    db_dml insert_for_ug "
    insert into user_groups
    (group_id, group_type, group_name, short_name, admin_email, creation_user, 
     creation_ip_address, approved_p, new_member_policy, spam_policy, 
     parent_group_id, registration_date)
    values
    (:group_id,:group_type,:group_name, :short_name, :admin_email, :user_id, 
     '[ns_conn peeraddr]', :approved_p, :new_member_policy, :spam_policy, 
     :parent_group_id, sysdate)
    "
    
    if [info exists insert_for_helper_table] {
	db_dml group_helper_fields_insert $insert_for_helper_table 
    }

    # let's add all the modules to this groups, which are associated with this group type
    
    db_dml insert_into_cs {
	insert into content_sections
	(section_id, scope, section_type, requires_registration_p, visibility, group_id, 
	 section_key, module_key, section_pretty_name, enabled_p)
	select content_section_id_sequence.nextval, 'group', section_type_from_module_key(module_key), 'f', 'public', :group_id,
	module_key, module_key, pretty_name_from_module_key(module_key), 't'
	from user_group_type_modules_map
	where group_type=:group_type
    }

} on_error {
    if { [db_string test_ug_insert {
	select 1 as one 
	from user_groups 
	where group_id=:group_id
    } -default 0] != 0 } {
	# group was already in database, so we can assume that this was a double click
	ad_returnredirect $return_url
	return
    }

    if { [db_0or1row get_groupname_already "select group_name as other_group_name from user_groups where short_name=:short_name"] } {
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
db_release_unused_handles

ad_returnredirect $return_url

