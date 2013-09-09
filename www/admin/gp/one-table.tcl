ad_page_contract {
    General permisssions page for a single table.

    @author mark@ciccarello.com
    @creation-date February 2000
    @cvs-id one-table.tcl,v 3.3.2.4 2000/07/21 03:57:25 ron Exp
} {
    table_name:notnull
    rownum:optional
}

set rows_per_page 50

ReturnHeaders

set row_count [db_string row_count_select "select count(*) from $table_name"];

set table_name [string toupper $table_name]
set bind_vars [ad_tcl_vars_to_ns_set table_name]

db_1row table_name_select "select pretty_table_name_singular, pretty_table_name_plural, denorm_view_name, lower(id_column_name) as id_column_name
                           from general_table_metadata
                           where upper(table_name) = :table_name" -bind $bind_vars

set html "[ad_admin_header  "General Permissions Administration for $pretty_table_name_plural" ]
<h2>General Permissions Administration for $pretty_table_name_plural</h2>
[ad_admin_context_bar { "index.tcl" "General Permissions"} "One Table"]
<hr>
"

#
# get the list of displayable columns
#
set column_list ""
set column_name_list ""

db_foreach display_column_select "select column_pretty_name, column_name, is_date_p, use_as_link_p
    from table_metadata_denorm_columns
    where upper(table_name) = :table_name
    order by display_ordinal" -bind $bind_vars {
	lappend column_list [list $column_pretty_name $column_name $is_date_p $use_as_link_p]
	lappend column_name_list $column_name
}

#
# start at record one if not specified
#

if { [info exists rownum] } {
    set rownum_first_this_page $rownum
} else {
    set rownum_first_this_page 1
}

#
# make sure the starting row isn't too high
#

if { $rownum_first_this_page >= $row_count } {
    set rownum_first_this_page [expr $row_count - $rows_per_page]
    if { $rownum_first_this_page < 1 } {
        set rownum_first_this_page 1
    }
}

#
# figure out the last row number on this page
#

set rownum_last_this_page [expr $rownum_first_this_page + $rows_per_page - 1]
if { $rownum_last_this_page > $row_count } {
    set rownum_last_this_page [expr $row_count]
}

#
# and the first on the next page, "" if there is no next page
#

set rownum_first_next_page [expr $rownum_last_this_page + 1]
if { $rownum_first_next_page > $row_count } {
    set rownum_first_next_page ""
}

#
# finally the starting row number of the previous page, "" if no previous
#

if { $rownum_first_this_page == "1" } {
    set rownum_first_previous_page ""
} else {
    set rownum_first_previous_page [expr $rownum_first_this_page - $rows_per_page]
    if { $rownum_first_previous_page < 1 } {
        set rownum_first_previous_page 1
    }
}
    
if { $row_count > $rows_per_page } {
    set to_row_num 1
    set to_page_num 1
    append html "<br>"
    if { $rownum_first_previous_page != "" } {
        append html "<a href=\"one-table?[export_url_vars table_name]&rownum=$rownum_first_previous_page\">\[prev\]</a>"
    } else {
        append html "\[prev\]"
    }

    while { $to_row_num <= $row_count } {
        if { $to_row_num != $rownum_first_this_page } {
            append html " <a href=\"one-table?[export_url_vars table_name]&rownum=$to_row_num\">$to_page_num</a>"
	} else {
            append html " <b>$to_page_num</b>"
	}
        incr to_page_num
        incr to_row_num $rows_per_page
    }
    
    if { $rownum_first_next_page != "" } {
        append html " <a href=\"one-table?[export_url_vars table_name]&rownum=$rownum_first_next_page\">\[next\]</a>"
    } else {
        append html " \[next\]"
    }

}
    

append html "
<p>There are $row_count $pretty_table_name_plural.  Here are $rownum_first_this_page to $rownum_last_this_page.
"

# go ahead and flush the output so far so the user doesn't have to wait to see something
ns_write $html

set html "
<table>
<tr>
"

# generate column headers

foreach column $column_list {
    append html "<th>[lindex $column 0]</th>"
}

append html "</tr>"

set n 0
set bind_vars [ad_tcl_vars_to_ns_set rownum_first_this_page rownum_last_this_page]

db_foreach column_select "select * from (
        select [join $column_name_list ","], rownum as row_number 
        from $denorm_view_name ) 
        where row_number >= :rownum_first_this_page and row_number <= :rownum_last_this_page" -bind $bind_vars {
    if { $n % 2 } {
        set bgcolor "#FFFFFF"
    } else {
        set bgcolor "#CCCCCC"
    }
    append html "<tr bgcolor=\"$bgcolor\">"
    foreach column $column_list {
        set column_name [lindex $column 1]
        upvar 0 $column_name column_value
        if { [lindex $column 3] == "t" } {
            upvar 0 $id_column_name row_id
            append html "<td><a href=\"one-row?[export_url_vars table_name row_id]\">$column_value</a></td>"
	} else {
	    append html "<td>$column_value</td>"
	}
    }
    append html "</tr>"        
    incr n
}

append html "
</table>

[ad_admin_footer]"

db_release_unused_handles
ns_write $html

