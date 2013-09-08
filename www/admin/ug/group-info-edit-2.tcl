ad_page_contract {
    @param group_id ID of the group

    @cvs-id group-info-edit-2.tcl,v 3.2.2.9 2000/12/16 01:51:42 cnk Exp
} {
    group_id:notnull,naturalnum
    group_info:array
}

set group_type [db_string get_group_type "select group_type 
from user_groups where group_id = :group_id"]

# this proc finds the name of a pre-existing _info table 
# or makes one if it is not there already
set helper_table_name [ad_user_group_helper_table_name $group_type]

# are we inserting or updating?
if { [db_string select_records_exist_p "
    select count(*)
    from $helper_table_name
    where group_id=:group_id"] > 0 } {
	set helper_table_dml "    UPDATE $helper_table_name
    SET"
	set update_p 1
	set set_vars [list]
} else {
    set update_p 0
    set helper_table_dml "    INSERT INTO $helper_table_name"
    set col_list [list group_id]
    set val_list [list ":group_id"]
}

set var_names [array names group_info]

# cnk@arsdigita.com I am ignoring what vars are passed in from the
# previous page and instead using the meta data from the group
# type. Since group-info-edit.tcl is constructed from this same meta
# date we are fine but should document this in case someone gets
# creative with the previous form.

# let's do some input validation based on the column type info from user_group_type_fields  
# WARNING this does not do guard against check-constraint violations 

# In the same loop, construct the insert or update

set exception_text ""
set exception_count 0

db_foreach get_extra_column_info "
select column_name, pretty_name, column_type, column_actual_type, column_extra
from user_group_type_fields
where group_type = :group_type" {

    # id not null columns and then check that we have input for them
    if { [regexp -nocase {not null} $column_extra ] } {
	if { [string match $column_type "special"] } {
	    append exception_text "<li> We have a big
problem. There is a column in the extra information table for this
group that is defined as \"not null\" but with a column type of
\"special\". This means that there was no way for you to enter data
for \"$pretty_name\" but you mush insert something into that
column. I think it is time to complain to your programmer."
            incr exception_count
	} elseif { [empty_string_p $group_info($column_name)] } { 
	    append exception_text "<li>Please enter a value for $column_name.\n"
	    incr exception_count
	}
    }
    
    # for date columns have to construct the date, and verify it is valid date 
    if { [string match $column_type "special"] } {
	# we're ignoring special columns from touching the database
    } elseif { [string match $column_type "date"] } {
	# grab the variables and put them in the col_name date array
	set ${column_name}(month) $group_info($column_name.month)
	set ${column_name}(day) $group_info($column_name.day)
	set ${column_name}(year) $group_info($column_name.year)

	ns_log Notice "date column parts [subst ${column_name}(month)]"

	## try to construct the date
	if ![ad_page_contract_filter_proc_date $column_name $column_name] {
	    # date invalid - null is ok and would not choke here
	    append exception_text "<li>Please enter a valid date, including 4 digit year for $pretty_name"
	    incr exception_count 
	} else {
	    # add to list of vars inserted or updated
	    if $update_p {
		lappend set_vars "    $column_name = to_date('[set ${column_name}(date)]', 'YYYY-MM-DD')\n"
	    } else {
		lappend col_list $column_name
		lappend val_list "to_date('[set ${column_name}(date)]', 'YYYY-MM-DD')"
	    }
	}

    # check if number columns are numeric
    } elseif { [regexp -nocase {numeric|integer|number} $column_type ] } {
	if { ![empty_string_p $group_info($column_name) ] && ![ad_var_type_check_number_p $group_info($column_name)] } {
	    append exception_text "<li>Please enter a number for $column_name - no non-numeric characters at all.\n"
	    incr exception_count
	} else {
	    # construct the query
	    set $column_name $group_info($column_name)
	    if $update_p {
		lappend set_vars "    $column_name = :$column_name\n"
	    } else {
		lappend col_list $column_name
		lappend val_list ":$column_name"
	    }
	}

    # check lengths on char and varchar columns
    } elseif [ regexp {char\(([^)]*)} $column_actual_type match size ] {
	# col is a char or varchar, check length
	if { [string length $group_info($column_name)] > $size } {
	    incr exception_count
	    append exception_text "<li>The text you entered for $pretty_name is too long to fit in the field, please edit it to get it below $size characters."
	} else {
	    # construct the query
	    set $column_name $group_info($column_name)
	    if $update_p {
		lappend set_vars "    $column_name = :$column_name\n"
	    } else {
		lappend col_list $column_name
		lappend val_list ":$column_name"
	    }
	}

    # not sure what type of column this might be but it slipped past our regexps
    } else {
	
	# construct the query
	set $column_name $group_info($column_name)
	if $update_p {
	    lappend set_vars "    $column_name = :$column_name\n"
	} else {
	    lappend col_list $column_name
	    lappend val_list ":$column_name"
	}
    }
}

if { $exception_count != 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

if $update_p {
    append helper_table_dml "    [join $set_vars ", "]
    WHERE group_id = :group_id"
} else {
    append helper_table_dml "
    ([join $col_list ", "])
    VALUES
    ([join $val_list ", "])"
}

db_dml update_helper_table $helper_table_dml

db_release_unused_handles

ad_returnredirect "group?group_id=$group_id"

