#
# schema-browser/index.tcl
#
# mark@ciccarello.com
#


# constraint descriptor: { constraint_name constraint_type { constraint_columns } search_condition {foreign_columns} foreign_table foreign_constraint }

set CD_CONSTRAINT_NAME 0
set CD_CONSTRAINT_TYPE 1
set CD_CONSTRAINT_COLUMN_LIST 2
set CD_SEARCH_CONDITION 3
set CD_PARENT_COLUMN_LIST 4
set CD_PARENT_TABLE_NAME 5
set CD_PARENT_CONSTRAINT 6


proc sb_get_triggers { db table_name } {

    set selection [ns_db select $db "
        select
            trigger_name,
            trigger_type,
            triggering_event,
            status
        from
            user_triggers
        where
            table_name = '[string toupper $table_name]'"
    ]

    set return_string "\n-- triggers:"
    set count 0
    while { [ns_db getrow $db $selection] } {
        set_variables_after_query
        append return_string "\n--\t<a href=\"trigger.tcl?[export_url_vars trigger_name]\">$trigger_name</a> $triggering_event $trigger_type $status"
    incr count
    }
    if { $count == 0 } {
        append return_string "\n--\tnone"
    }
    return $return_string        
}



proc xx_get_child_tables { db table_name {html_anchor_p "f"} } {


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

     set selection [ns_db select $db "
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
             parentcol.table_name = '[string toupper $table_name]'
       "]

              
    append return_string "\n-- child tables:"

    set child_count 0
    while { [ns_db getrow $db $selection] } {
        if { [expr (($child_count % 3) == 0)] } {
            append return_string "\n--"
	}
        set_variables_after_query
        if { $html_anchor_p == "t" } {
            append return_string " <a href=\"index.tcl?table_name=$child_table\">[string tolower $child_table]</a>"
        } else {
            append return_string " [string tolower $child_table]"
	} 
        append return_string "($r_constraint_name)"
        incr child_count
    }
    if {$child_count == 0} {
        append return_string "\n--\t none"
    }

    return $return_string

}


proc add_column_constraint { column_list column_constraint } {

#
# adds a column constraint to the column list
#
# column_list := list of column_descriptor
# column_constraint := constraint descriptor
# 
#

    set i 0
    set found_p "f"

    while { $i < [llength $column_list] && [lindex $column_constraint 2] != [lindex [lindex $column_list $i] 0] } {
        incr i
    }

    if { $i < [llength $column_list] } {
         set column_descriptor [lindex $column_list $i]
         set column_constraints [lindex $column_descriptor 4]
         lappend column_constraints $column_constraint
         set column_descriptor [lreplace $column_descriptor 4 4 $column_constraints]
         set column_list [lreplace $column_list $i $i $column_descriptor]
    }

    return $column_list


}

proc xx_get_constraints { db table_name column_list {html_anchors_p "f"} } {


}



proc xx_get_indexes { db table_name { html_anchors_p "f" } } {

    set return_string ""


    #
    # create statements for non-unique indices
    # 

    set selection [ns_db select $db "
        select
            i.index_name, 
            i.index_type, 
            i.uniqueness,
            c.column_name      
        from
            user_indexes i, user_ind_columns c
        where
            i.index_name = c.index_name and
            i.table_name = '[string toupper $table_name]'
        order by
            i.index_name,
            c.column_position
        "
    ]

    set prev_index ""

    while { [ns_db getrow $db $selection] } {
        set_variables_after_query
        if { $uniqueness == "NONUNIQUE" } {
            set uniqueness ""
	}
        if { $index_name != $prev_index } {
            if { $prev_index != "" } {
                append return_string ");"
	    }
            append return_string "\nCREATE $uniqueness INDEX [string tolower $index_name] ON [string tolower $table_name]\("
        } else {
            append return_string ","
	}
        append return_string "[string tolower $column_name]" 
        set prev_index $index_name
    }

    if { $prev_index != "" } {
        append return_string ");"
    }


}

set_the_usual_form_variables 0

#
# expected: table_name (optional)
#           n_columns (optional, default 4)
#

if { ![info exists n_columns] } {
    set n_columns 4
}


ReturnHeaders

ns_write "
<h2>ArsDigita Schema Browser</h2>
<hr>
"

set db [ns_db gethandle]

set selected_table_name ""


if { [info exists table_name] && $table_name != "" } {
    set selected_table_name $table_name
    set selection [ns_db select $db "
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
            user_tables.table_name = '[string toupper $selected_table_name]' and
            user_tab_columns.table_name = '[string toupper $selected_table_name]' and
            user_col_comments.table_name(+) = '[string toupper $selected_table_name]' and
            user_col_comments.column_name(+) = user_tab_columns.column_name
        order by
            column_id
    "]
    ns_write "<pre>"
    ns_write "\nCREATE TABLE [string tolower $selected_table_name] ("
 
    set column_list ""
    while { [ns_db getrow $db $selection] } {
        set_variables_after_query
        set column [list $column_name $data_type $data_length $column_comments "" $data_default $nullable]
        lappend column_list $column
    }

    #
    # find the column and table constraints
    #


    set selection [ns_db select $db "
        select
            columns.constraint_name,
            columns.column_name,
            columns.constraint_type,
            columns.search_condition,
            columns.r_constraint_name,
            decode(columns.constraint_type,'P',0,'U',1,'R',2,'C',3,4) as constraint_type_ordering,
            parent_columns.table_name as parent_table_name,
            parent_columns.column_name as parent_column_name
        from
            (   
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
        where
            columns.table_name = '[string toupper $table_name]' and
            constraint_type in ('P','U','C','R') and
            columns.r_constraint_name = parent_columns.constraint_name(+) and
            columns.position = parent_columns.position(+)
        order by
            constraint_type_ordering,
            constraint_name,
            columns.position
        "
    ]


    # table_constraint_list -- a list of constraint descriptors for all constraints involving more than one column
    set table_constraint_list ""     
    

    # current_contraint -- a constraint descriptor for the constraint being processed in the loop below
    set current_constraint ""        

    while { [ns_db getrow $db $selection] } {
        set_variables_after_query
        if { $constraint_name != [lindex $current_constraint $CD_CONSTRAINT_NAME] } {
            if { $current_constraint != "" } {
                # we've reached a new constraint, so finish processing the old one
		if { [llength [lindex $current_constraint $CD_CONSTRAINT_COLUMN_LIST]] > 1 } {
                    # this is a table constraint -- involves more than one column, so add it to the table constraint list
                    lappend table_constraint_list $current_constraint
		} else {
                    set column_list [add_column_constraint $column_list $current_constraint]
	        }
	    }
	    set current_constraint [list $constraint_name $constraint_type $column_name $search_condition $parent_column_name $parent_table_name $r_constraint_name]
	} else {
           # same constraint -- add the column to the descriptor
           set constraint_column_list [lindex $current_constraint $CD_CONSTRAINT_COLUMN_LIST]
           lappend constraint_column_list $column_name
           set current_constraint [lreplace $current_constraint $CD_CONSTRAINT_COLUMN_LIST $CD_CONSTRAINT_COLUMN_LIST $constraint_column_list]
	   if { $parent_column_name != "" } {
               set parent_column_list [lindex $current_constraint $CD_PARENT_COLUMN_LIST] 
               lappend parent_column_list $parent_column_name
               set current_constraint [lreplace $current_constraint $CD_PARENT_COLUMN_LIST $CD_PARENT_COLUMN_LIST $parent_column_list]
	   }
	}
    }

    if { $current_constraint != "" } {
        if { [llength [lindex $current_constraint $CD_CONSTRAINT_COLUMN_LIST]] > 1 } {
  	    lappend table_constraint_list $current_constraint
	} else {
            set column_list [add_column_constraint $column_list $current_constraint]
        }
    }

    #
    # write out the columns with associated constraints
    #


    set n_column 0
    foreach column $column_list {
        if { $n_column > 0 } {
            ns_write ","
	}
        set column_name [lindex $column 0]
        set data_type [lindex $column 1]
        set data_length [lindex $column 2]
        set comments [lindex $column 3]
        set constraint_list [lindex $column 4]
        set data_default [lindex $column 5]
        set nullable [lindex $column 6]
 
        ns_write "\n\t[string tolower $column_name]\t $data_type\($data_length)"
        if { $nullable != "" } {
	    ns_write " $nullable"
	}
        if { $data_default != "" } {
            ns_write " DEFAULT [util_convert_plaintext_to_html $data_default]"
	}
        foreach constraint $constraint_list {
            if { [lindex $constraint $CD_CONSTRAINT_TYPE] == "P" } {
                ns_write " PRIMARY KEY"
	    } elseif { [lindex $constraint $CD_CONSTRAINT_TYPE] == "U" } {
                ns_write " UNIQUE"
	    } elseif { [lindex $constraint $CD_CONSTRAINT_TYPE] == "R" } {
                ns_write " FOREIGN KEY REFERENCES [string tolower [lindex $constraint $CD_PARENT_TABLE_NAME]]([string tolower [lindex $constraint $CD_PARENT_COLUMN_LIST]])"
	    } elseif { [lindex $constraint $CD_CONSTRAINT_TYPE] == "C" } {
                # check constraint  ignore not-null checks
                # because we already handled them
                if { [string first "NOT NULL" [lindex $constraint $CD_SEARCH_CONDITION]] == -1 } { 
                    ns_write "\n\t\tCHECK ([lindex $constraint $CD_SEARCH_CONDITION])"
                }
            } 
	}

        if {$comments != ""} {
            if { [string length $comments] > 40 } {
                ns_write "\t-- [string range $comments 0 36]..."
	    } else {
                ns_write "\t-- $comments"
	    }
	}
        incr n_column
    }


    #
    # write out the table-level constraints in the table_constraint_list
    #

    foreach constraint $table_constraint_list {
        if { [lindex $constraint $CD_CONSTRAINT_TYPE] == "P" } {
            ns_write ",\n\tPRIMARY KEY [lindex $constraint $CD_CONSTRAINT_NAME]("
            ns_write "[string tolower [join [lindex $constraint $CD_CONSTRAINT_COLUMN_LIST] ","]])"
	} elseif { [lindex $constraint $CD_CONSTRAINT_TYPE] == "U"} {
            ns_write ",\n\tUNIQUE [lindex $constraint $CD_CONSTRAINT_NAME]("
            ns_write "[string tolower [join [lindex $constraint $CD_CONSTRAINT_COLUMN_LIST] ","]])"
        } elseif { [lindex $constraint $CD_CONSTRAINT_TYPE] == "R"} {
            ns_write ",\n\tFOREIGN KEY [lindex $constraint $CD_CONSTRAINT_NAME]("
            ns_write "[string tolower [join [lindex $constraint $CD_CONSTRAINT_COLUMN_LIST] ","]])"
            ns_write " REFERENCES [string tolower [lindex $constraint $CD_PARENT_TABLE_NAME]]("
            ns_write "[string tolower [join [lindex $constraint $CD_PARENT_COLUMN_LIST] ","]])"
	}
    }
    
    ns_write "\n);"
    ns_write [xx_get_indexes $db $selected_table_name]
    ns_write [sb_get_triggers $db $selected_table_name]
    ns_write [xx_get_child_tables $db $selected_table_name "t"]
    ns_write "</pre>"

}


ns_write "<h3>Tables:</h3>"
set tables ""
set selection [ns_db select $db "select table_name from user_tables order by table_name"]
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    lappend tables $table_name
}

set n_rows [expr ([llength $tables] - 1) / $n_columns + 1]

ns_write "<table>"
for { set row 0 } { $row < $n_rows } { incr row } {
     ns_write "<tr>"
     for {set column 0} {$column < $n_columns} {incr column} {
         set i_element [expr $n_rows * $column + $row]
         if { $i_element < [llength $tables] } {
             set table_name [lindex $tables $i_element]
             if { $table_name == $selected_table_name } {
                 ns_write "<td><b>[string tolower $table_name]</b></td>"
	     } else {
                 ns_write "<td><a href=\"index.tcl?[export_url_vars table_name]\">[string tolower $table_name]</a></td>"
             }
	 }
          
     }   
     ns_write "</tr>"
}
ns_write "</table>"

  

    
















