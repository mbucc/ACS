# $Id: ad-audit-trail.tcl,v 3.0 2000/02/06 03:12:10 ron Exp $
# ad-audit-trail.tcl 
# by jkoontz@arsdigita.com August 1999 based on code by teadams@mit.edu 
#
# documented in /doc/audit.html 
#
# two procs helpful for building pages that show audit history for a set of
# id's in a table between specific dates

# ARGUMENT
# db - database handle
# audit_table_name - table that holds the audit records
# main_table_name - table that holds the main record
# id_column_list - list of column names representing the unique key in 
#      audit_table_name and main_table_name
# id_list - list of ids of the unique record you are auditing
# columns_not_reported - tcl list of names in audit_table_name 
#      and main_table that you don't want displayed
# start_date - ANSI standard time to begin viewing records
# end_date - ANSI standard time to stop viewing records
# restore_url - URL of a tcl page that would restore a given record to 
#               the main table. Form variables for the page:  id id_column
#               main_table_name audit_table_name and rowid

    proc_doc ad_audit_trail { db id_list audit_table_name main_table_name id_column_list { columns_not_reported ""} {start_date ""} {end_date ""} {restore_url ""}} {Returns an HTML fragment showing changes to one row in the OLTP system between the times start_date and end_date (YYYY-MM-DD HH24:MI:SS).  There will be one section for each row in the audit table and a single section for the occurrence of id (must be unique) in main_table, the entire affair sorted by time (descending). If a restore_url is provided, a link will appear next to each non-delete section to the restore url with the current rowid and ad_audit_trail arguments.} {

    # These values will be part of an audit entry description
    # and do not need to be reported seperately
    lappend columns_not_reported modifying_user_name
    lappend columns_not_reported last_modifying_user
    lappend columns_not_reported last_modified
    lappend columns_not_reported modified_ip_address
    lappend columns_not_reported delete_p
    lappend columns_not_reported rowid

    # HTML string to be returned at the end of the proc
    set return_string ""

    # The date restrictions should only be added if start_date or end_date
    # is not empty
    set date_clause ""
    if { ![empty_string_p $end_date] } {
	append date_clause "and last_modified < to_date('$end_date','YYYY-MM-DD HH24:MI:SS')"
    }
    if { ![empty_string_p $start_date] } {
	append date_clause "\nand last_modified > to_date('$start_date','YYYY-MM-DD HH24:MI:SS')"
    }

    # Generate main and audit table restrictions for 
    # the ids in the id columns
    set main_table_id_clause ""
    set audit_table_id_clause ""
    set count 0

    # check that the ids are not going to cause a problem
    set id_list [DoubleApos $id_list]
    foreach id $id_list {
	set id_column [lindex $id_column_list $count]
	incr count

	append main_table_id_clause "\nand $main_table_name.$id_column = '$id'"
	append audit_table_id_clause "\nand $audit_table_name.$id_column = '$id'"
    }

    # Get the entries in the audit table
    set selection [ns_db select $db "select 
 $audit_table_name.*, $audit_table_name.rowid,
 to_char($audit_table_name.last_modified,'Mon DD, YYYY HH12:MI AM')
  as last_modified,
 users.first_names || ' ' || users.last_name as modifying_user_name
from $audit_table_name, users 
where users.user_id = $audit_table_name.last_modifying_user
$audit_table_id_clause
$date_clause
order by $audit_table_name.last_modified asc"]

    # The first record displayed may not represent an insert if 
    # start_date is not empty. So display the first record as an update
    # if start_date is not empty.
    if { ![empty_string_p $start_date] } {
	# Not all records will be displayed, so first record may not be
	# an insert.
	set audit_count 1
    } else {
	# All records are being displayed so first record is an insert
	set audit_count 0
    }

    # used to keep track of previous record's data so that only updated
    # information is displayed.
    set old_selection [ns_set create old_selection]

    while { [ns_db getrow $db $selection] } {
       ad_audit_process_row
       append return_string $audit_entry
    }

    # get the current records
    set selection [ns_db select $db "
select 
 $main_table_name.*,  
 users.first_names || ' ' || users.last_name as modifying_user_name, 
 to_char($main_table_name.last_modified,'Mon DD, YYYY HH12:MI AM')
  as last_modified
from $main_table_name, users 
where users.user_id = $main_table_name.last_modifying_user
$main_table_id_clause
$date_clause
order by $main_table_name.last_modified asc"]

    # tell ad_audit_process_row that this is not a deleted row
    set delete_p "f"

    while { [ns_db getrow $db $selection] } {
	ad_audit_process_row    
	append return_string $audit_entry
    }

    return $return_string
}

proc ad_audit_process_row {} {
    # internal proc for ad_audit_trail
    # Sets audit_entry to the HTML fragement representing one line
    # from the audit table or main table.
    # First it identifies whether the row was a delete, update, or insert
    # Second, it builds a table of values that changed from the last row
    
    uplevel {
	set_variables_after_query

	# Loop through each column key and value in the selection
	set selection_counter_i 0
	set modification_count 0
	set selection_size [ns_set size $selection]

	if { $delete_p == "t" } {
	    # Entry in the audit table is for a deleted row
	    # Set the audit entry to a single line
	    set audit_entry "<h4>Delete on $last_modified by 
	      [ec_admin_present_user $last_modifying_user $modifying_user_name]
	      </a> ($modified_ip_address)</h4>"

	    # Reset the audit value records
	    set audit_count 0
	    set old_selection [ns_set create old_selection]

	} else {
	    if { $audit_count == 0 } {
		# No previous audit entry for this ID key
		set audit_entry "<h4>Insert on $last_modified by 
		  [ec_admin_present_user $last_modifying_user $modifying_user_name]
		  </a> ($modified_ip_address)</h4><table>"
	    } else {
		# This audit entry represents an update to the main row
		set audit_entry "<h4>Update on $last_modified by 
		  [ec_admin_present_user $last_modifying_user $modifying_user_name]
		  </a> ($modified_ip_address)</h4><table>"
	    }
	
	    while { $selection_counter_i < $selection_size } {
		set column [ns_set key $selection $selection_counter_i]
		set value   [ns_set value $selection $selection_counter_i]
		if { [lsearch -glob $columns_not_reported $column] == -1 } {
		    if { $audit_count > 0 } {
			if { $value != [ns_set get $old_selection $column] } {
			    # report if the value changed
			    if { [empty_string_p [ns_set get $old_selection $column]]} { 
				append audit_entry "<tr><td  valign=top>
				Added $column:</td><td>[ns_quotehtml $value]</td></tr>"
			    } else {
				append audit_entry "<tr><td  valign=top>
				Modified $column:</td><td>[ns_quotehtml $value]</td></tr>"
			    }
			    incr modification_count
			}
			
		    } elseif { ![empty_string_p $value] }  {
			# report initial value if it is not blank
			append audit_entry "<tr><td  valign=top>
			Added $column:</td><td>[ns_quotehtml $value]</td></tr>"
		    }
		}
		ns_set update $old_selection $column $value
		incr selection_counter_i
	    }
	    if { $audit_count > 0 && $modification_count == 0 } {
		# if it is the same person on the same day, we don't care
		if {[string compare $last_modified [ns_set get $old_selection last_modified]] != 0 || [string compare $last_modifying_user [ns_set get $old_selection last_modifying_user]] != 0  } {
		    append audit_entry "<tr><td colspan=2>Recorded again with no modifications</td></tr>"
		} else {
		    set audit_entry ""
		}
	    }
	    append audit_entry "</table>"
	    if { ![empty_string_p $restore_url] } {
		append audit_entry "Restore <a href=\"$restore_url?[export_url_vars id id_column main_table_name audit_table_name rowid]\">this record</a> to the main table."
	    }
	    incr audit_count
	}
    }
}

proc_doc ad_audit_delete_row { db id_list id_column_list audit_table_name } "Inserts an entry to the audit table to log a delete. Each id is inserted into its id_column as well as user_id, IP address, and date." {

    # VARIABLES
    # db - database handle
    # audit_table_name - table that holds the audit records
    # id_column_list - column names of the primary key(s) in 
    #      audit_table_name 
    # id_list -  ids of the record you are processing

    set id_column_join [join $id_column_list ", "]
    set id_join [join $id_list ", "]

    ns_db dml $db "insert into $audit_table_name
    ($id_column_join, last_modified, 
    last_modifying_user, modified_ip_address, delete_p)
    values
    ($id_join, sysdate, 
    '[ad_get_user_id]', '[DoubleApos [ns_conn peeraddr]]','t')
    "

}

proc_doc ad_audit_trail_for_table { db main_table_name audit_table_name id_column {start_date ""} {end_date ""} {audit_url ""} {restore_url ""}} "Returns the audit trail for each id from the id_column for updates and deletes from main_table_name and audit_table_name that occured between start_date and end_date. If start_date is blank, then it is assumed to be when the table was created, if end_date is blank then it is assumed to be the current time. The audit_url, if it exists, will be given the calling arguments for ad_audit_trail." {

    # Text being returned by the proc
    set return_html ""

    # Build a sql string to only return records which where last modified
    # between the start date and end date
    set date_clause_list [list]
    if { ![empty_string_p $end_date] } {
	lappend date_clause_list "last_modified < to_date('$end_date','YYYY-MM-DD HH24:MI:SS')"
    } 
    if { ![empty_string_p $start_date] } {
	lappend date_clause_list "last_modified > to_date('$start_date','YYYY-MM-DD HH24:MI:SS')"
    }

    # Generate a list of ids for records that where modified in the time
    # between start_date and end_date.
    set id_list [database_to_tcl_list $db "select distinct $id_column from $main_table_name where [join $date_clause_list "\nand "]"]

    # Display the grouped modifications to each id in id_list
    foreach id $id_list {

	# Set the HTML link tags to a page which displays the full 
	# audit history.
	if { ![empty_string_p $audit_url] } {
	    set id_href "<a href=\"$audit_url?[export_url_vars id id_column main_table_name audit_table_name]\">"
	    set id_href_close "</a>"
	} else {
	    set id_href ""
	    set id_href_close ""
	}

	append return_html "
<h4>$id_column is $id_href$id$id_href_close</h4>
<blockquote>
[ad_audit_trail $db $id $audit_table_name $main_table_name $id_column "" $start_date $end_date]
</blockquote>
"
}

    # We will now repeate the process to display the modifications 
    # that took place between start_date and end_date but occured on
    # records that have been deleted.


    # Add a constraint to view only deleted ids and
    # look into the audit table instead of the main table
    lappend date_clause_list "delete_p = 't'"
    set id_list [database_to_tcl_list $db "select distinct $id_column from $audit_table_name where [join $date_clause_list "\nand "] "]

    # Display the grouped modifications to each id in id_list
    foreach id $id_list {

	# Set the HTML link tags to a page which displays the full 
	# audit history.
	if { ![empty_string_p $audit_url] } {
	    set id_href "<a href=\"$audit_url?[export_url_vars id id_column main_table_name audit_table_name]\">"
	    set id_href_close "</a>"
	} else {
	    set id_href ""
	    set id_href_close ""
	}

	append return_html "
<h4>Deleted $id_column is $id_href$id$id_href_close</h4>
<blockquote>
[ad_audit_trail $db $id $audit_table_name $main_table_name $id_column "" $start_date $end_date $restore_url]
</blockquote>
"
    }

    return $return_html
}