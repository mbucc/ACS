ad_library {
    Took these defs out of the /www/doc/schema-browser/index.tcl file.
}

ad_proc sb_get_tables_list {} {} {

    set tables ""

    db_foreach schema_browser_index_get_tables "select table_name 
    from user_tables order by table_name" {
        lappend tables $table_name
    }

    db_release_unused_handles
    return $tables

}

ad_proc sb_get_tables { selected_table_name } {} {

    set n_columns 4
    set return_string ""

    set tables [util_memoize "sb_get_tables_list"]

    set n_rows [expr ([llength $tables] - 1) / $n_columns + 1]

    append return_string "<table>"
    for { set row 0 } { $row < $n_rows } { incr row } {
         append return_string "<tr>"
         for {set column 0} {$column < $n_columns} {incr column} {
             set i_element [expr $n_rows * $column + $row]
             if { $i_element < [llength $tables] } {
                 set table_name [lindex $tables $i_element]
                 if { $table_name == $selected_table_name } {
                     append return_string "<td><b>[string tolower $table_name]</b></td>"
	         } else {
                     append return_string "<td><a href=\"index?[export_url_vars table_name]\">[string tolower $table_name]</a></td>"
                 }
	     }
          
         }   
     append return_string "</tr>"
    }

    append return_string "</table>"

    return $return_string

}

ad_proc sb_get_triggers { table_name } {} {
    set return_string "\n-- $table_name triggers:"
    db_foreach sb_get_triggers_select_1 "
        select
            trigger_name,
            trigger_type,
            triggering_event,
            status
        from
            user_triggers
        where
             table_name = upper(:table_name)
    " {
        append return_string "\n--\t<a href=\"trigger?[export_url_vars trigger_name]\">$trigger_name</a> $triggering_event $trigger_type $status"
    } if_no_rows {
        append return_string "\n--\tnone"
    }

    return $return_string        
}

ad_proc sb_get_child_tables { table_name {html_anchor_p "f"} } {} {

  #
  # child tables -- put in comments about each child table that references this one
  #

  set return_string ""
  
  # this takes about 8 minutes to run -- for one table!
  #   set selection [ns_db select $db "
  #        select
  #            childcon.constraint_name,
  #            parentcol.column_name as parent_column,
  #            childcol.column_name as child_column,
  #            childcol.table_name as child_table,
  #            parentcol.table_name as parent_table
  #        from
  #            user_constraints childcon,
  #            user_cons_columns parentcol,
  #            user_cons_columns childcol
  #        where
  #            childcon.r_constraint_name = parentcol.constraint_name and
  #            childcon.constraint_name = childcol.constraint_name and
  #            childcon.constraint_type = 'R' and
  #            parentcol.table_name = '$table_name'
  #    "]

  # since the above is so slow, forget about joining in user_cons_columns for the child table, so we won't know the
  # column names of the child table involved.
    append return_string "\n-- child tables:"
    set child_count 1
    db_foreach schema_browser_index_get_user_constraints "
         select distinct
             childcon.constraint_name,
             childcon.r_constraint_name,
             childcon.table_name as child_table
         from
             user_constraints childcon,
             user_cons_columns parentcol
         where
             childcon.r_constraint_name = parentcol.constraint_name and
             childcon.constraint_type = 'R' and
             parentcol.table_name = upper(:table_name)
         order by child_table
       " {             
        if { [expr (($child_count % 3) == 0)] } {
            append return_string "\n--"
	}
        if { $html_anchor_p == "t" } {
            append return_string " <a href=\"index?table_name=$child_table\">[string tolower $child_table]</a>"
        } else {
            append return_string " [string tolower $child_table]"
	} 
        append return_string "($r_constraint_name)"
        incr child_count
    } if_no_rows {
        append return_string "\n--\t none"   
    }
    
    return $return_string
    
}

ad_proc add_column_constraint { column_list column_constraint } {} {

#
# adds a column constraint to the column list
#
# column_list := list of column_info
# column_constraint := constraint_info ns_set
# 
#

    set i 0
    set found_p "f"

    #
    # iterate through the columns in the list, finding the one with a name that matches the one in the constraint
    #

    while { $i < [llength $column_list] && $found_p != "t" } {
        if  { [ns_set get $column_constraint "constraint_columns"] == [ns_set get [lindex $column_list $i] "column_name"] } {
            set column_info_set [lindex $column_list $i]
            set column_constraint_list [ns_set get $column_info_set "constraint_list"]
            lappend column_constraint_list $column_constraint
            ns_set update $column_info_set "constraint_list" $column_constraint_list
            #set column_list [lreplace $column_list $i $i $column_info_set]
            set found_p "t"
	}
        incr i
    }
    
    return $column_list

}

ad_proc sb_get_indexes { table_name { html_anchors_p "f" } } {} {

    
    set return_string ""
    
    #
    # create statements for non-unique indices
    # 
    
    set prev_index ""

    db_foreach sb_get_indexes_select_1 "
    select
    i.index_name, 
    i.index_type, 
    i.uniqueness,
    c.column_name      
    from
    user_indexes i, user_ind_columns c
    where
    i.index_name = c.index_name and
    i.table_name = upper(:table_name)
    order by
    i.index_name,
    c.column_position" {
        
        if { $uniqueness == "NONUNIQUE" } {
            # unique indices are written out as constraints
            if { $index_name != $prev_index } {
                if { $prev_index != "" } {
                    append return_string ");"
                }
                append return_string "\nCREATE INDEX [string tolower $index_name] ON [string tolower $table_name]\("
            } else {
                append return_string ","
            }
            append return_string "[string tolower $column_name]" 
            set prev_index $index_name
        }
    }
    
    if { $prev_index != "" } {
        append return_string ");"
    }
    
    return $return_string
    
}

ad_proc sb_get_table_description { table_name } {} {

    set html ""
    append html "<pre>"
    append html "\nCREATE TABLE [string tolower $table_name] ("
 
    set column_list [list]
    set column_info_set [ns_set create]
    db_foreach schema_browser_index_get_user_table_data "
        select
            user_tab_columns.column_name,
            data_type,
            data_length,
            user_col_comments.comments as column_comments,
            user_tab_columns.data_default,
            decode(nullable,'N','NOT NULL','') as nullable
        from
            user_tab_columns,
            user_tables,
            user_col_comments
        where
            user_tables.table_name = upper(:table_name) and
            user_tab_columns.table_name = upper(:table_name) and
            user_col_comments.table_name(+) =  upper(:table_name) and
            user_col_comments.column_name(+) = user_tab_columns.column_name
        order by
            column_id
    " -column_set column_info_set {

        lappend column_list [ns_set copy $column_info_set]
    }
    ns_set free $column_info_set

    append html "  -- num of columns = [llength $column_list]"

    #
    # find the column and table constraints
    #
    # table_constraint_list -- a list of constraint_info_sets for all constraints involving more than one column
    set table_constraint_list [list]     
    

    # current_contraint_info -- a constraint_info_set for the constraint being processed in the loop below
    set constraint_info [ns_set new]        

    db_foreach schema_browser_index_get_subselect "
    select  columns.constraint_name,
            columns.column_name,
            columns.constraint_type,
            columns.search_condition,
            columns.r_constraint_name,
            decode(columns.constraint_type,'P',0,'U',1,'R',2,'C',3,4) as constraint_type_ordering,
            parent_columns.table_name as foreign_table_name,
            parent_columns.column_name as foreign_column_name
    from    (   
               select 
                   col.table_name,
                   con.constraint_name, 
                   column_name, 
                   constraint_type, 
                   search_condition, 
                   r_constraint_name,
                   position 
               from
                   user_constraints con,
                   user_cons_columns col
               where
                   con.constraint_name = col.constraint_name
            ) columns, 
            user_cons_columns parent_columns
    where   columns.table_name = upper(:table_name) and
            constraint_type in ('P','U','C','R') and
            columns.r_constraint_name = parent_columns.constraint_name(+) and
            columns.position = parent_columns.position(+)
    order by
            constraint_type_ordering,
            constraint_name,
            columns.position
    " {
	
	if { $constraint_name != [ns_set get $constraint_info  "constraint_name"] } {
	    if { [ns_set get $constraint_info "constraint_name"] != "" } {
		# we've reached a new constraint, so finish processing the old one
		if { [llength [ns_set get $constraint_info "constraint_columns"]] > 1 } {
		    # this is a table constraint -- involves more than one column, so add it to the table constraint list
		    lappend table_constraint_list $constraint_info
		} else {
		    # single-column constraint
		    set column_list [add_column_constraint $column_list $constraint_info]
		}
	    }
	    set constraint_info [ns_set new]
	    ns_set put $constraint_info "constraint_name" $constraint_name
	    ns_set put $constraint_info "constraint_type" $constraint_type
	    ns_set put $constraint_info "constraint_columns" [list $column_name]
	    ns_set put $constraint_info "search_condition" $search_condition
	    ns_set put $constraint_info "foreign_columns" $foreign_column_name
	    ns_set put $constraint_info "foreign_table" $foreign_table_name
	    ns_set put $constraint_info "r_constraint_name" $r_constraint_name
	} else {
	    # same constraint -- add the column to the constraint_column_list
	    set constraint_columns [ns_set get $constraint_info "constraint_columns"]
	    lappend constraint_columns $column_name
	    ns_set update $constraint_info "constraint_columns" $constraint_columns
	    if { $foreign_column_name != "" } {
		set foreign_columns [ns_set get $constraint_info "foreign_columns"] 
		lappend foreign_columns $foreign_column_name
		ns_set put $constraint_info "constraint_columns" $foreign_columns
	    }
	}
    }
    
    # we've run out of rows, but need to flush out the open current_constraint
    if { [ns_set get $constraint_info "constraint_name"] != "" } {
	if { [llength [ns_set get $constraint_info "constraint_columns"]] > 1 } {
	    lappend table_constraint_list $constraint_info
	} else {
	    set column_list [add_column_constraint $column_list $constraint_info]
	}
    }

    #
    # write out the columns with associated constraints
    #
    
    set n_column 0
    set hanging_comment ""

    foreach column $column_list {
	if { $n_column > 0 } {
	    append html ","
	    # flush out a comment on the previous column, if needed
	    # delayed until after the comma
	    if { $hanging_comment != "" } {
		append html " -- $hanging_comment"
		set hanging_comment ""
	    }
	}
	append html "\n"
	set column_comments [ns_set get $column "column_comments"]
	if {$column_comments != ""} {
	    if { [string length $column_comments] > 40 } {
		append html "\t-- [string range $column_comments 0 36]..."
	    } else {
		append html "\t-- $column_comments"
	    }
	}
	append html "\t[string tolower [ns_set get $column "column_name"]]\t [ns_set get $column "data_type"]([ns_set get $column "data_length"])"
	if { [ns_set get $column "data_default"] != "" } {
	    append html " DEFAULT [util_convert_plaintext_to_html [ns_set get $column "data_default"]]"
	}
        if { [ns_set get $column "nullable"] != "" } {
	    append html " [ns_set get $column "nullable"]"
	}
        set constraint_list [ns_set get $column "constraint_list"]
        foreach constraint $constraint_list {
            set constraint_type [ns_set get $constraint "constraint_type"]
            if { $constraint_type == "P" } {
                append html " PRIMARY KEY"
	    } elseif { $constraint_type == "U" } {
                append html " UNIQUE"
	    } elseif { $constraint_type == "R" } {
                set foreign_table [string tolower [ns_set get $constraint "foreign_table"]]
                append html " REFERENCES <a href=\"index?table_name=$foreign_table\">$foreign_table</a>([string tolower [ns_set get $constraint "foreign_columns"]])"
                set hanging_comment [ns_set get $constraint "constraint_name"]
	    } elseif { $constraint_type == "C" } {
                # check constraint  ignore not-null checks
                # because we already handled them
                if { [string first "NOT NULL" [ns_set get $constraint "search_condition"]] == -1 } { 
                    append html "\n\t\tCHECK [ns_set get $constraint "constraint_name"]([ns_set get $constraint "search_condition"])"
                }
            } 
	}
        incr n_column
    }
    if { $hanging_comment != "" } {
        append html " -- $hanging_comment"
        set hanging_comment ""
    }

    #
    # write out the table-level constraints in the table_constraint_list
    #
    
    foreach constraint $table_constraint_list {
        set constraint_type [ns_set get $constraint "constraint_type"]
        set constraint_name [ns_set get $constraint "constraint_name"]
        set constraint_columns [ns_set get $constraint "constraint_columns"]
        set foreign_table [string tolower [ns_set get $constraint "foreign_table"]]
        set foreign_columns [ns_set get $constraint "foreign_columns"]
        if { $constraint_type == "P" } {
            append html ",\n\tPRIMARY KEY [ns_set get $constraint "constraint_name"]("
            append html "[string tolower [join [ns_set get $constraint "constraint_columns"] ","]])"
	} elseif { $constraint_type == "U"} {
            append html ",\n\tUNIQUE [ns_set get $constraint "constraint_name"]("
            append html "[string tolower [join [ns_set get $constraint "constraint_columns"] ","]])"
        } elseif { $constraint_type == "R"} {
            append html ",\n\tFOREIGN KEY $constraint_name ("
            append html "[string tolower [join $constraint_columns ","]])"
            append html " REFERENCES <a href=\"index?table_name=$foreign_table\">[string tolower $foreign_table]</a>("
            append html "[string tolower [join $foreign_columns ","]])"
	}
    }
    
    append html "\n);"
    append html [sb_get_indexes $table_name]
    append html [sb_get_triggers $table_name]
    append html [sb_get_child_tables $table_name "t"]
    append html "</pre>"
    
    return $html
    
}

