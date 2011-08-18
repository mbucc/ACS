# $Id: prototype-defs.tcl,v 3.0 2000/02/06 03:13:57 ron Exp $
# created by Rebecca Frankel (rfrankel@zurich.ai.mit.edu) in June 1999
# modified by teadams@mit.edu 
# procedures used by the prototype builder in /admin/prototype


proc_doc max_col_length {table col} "Returns the length of the 'col' in table 'table'" {
    set db [ns_db gethandle subquery]

    set sql "select data_length from USER_TAB_COLUMNS where table_name='[string toupper $table]' and column_name = '[string toupper $col]'"
    set table_length [database_to_tcl_string_or_null $db $sql foo]

    ns_db releasehandle $db

    return $table_length

}

# These procs used in tableinfo.tcl
proc_doc column_form_error {column} "Makes the forms to ask about which error-action type the user desires"  {
    set select_html "<tr align=right><th>$column:</th>\n"

    set form_var $column
    append form_var "_error_action"
    append select_html \
     "<td><input name=$form_var value=nothing checked type=radio>Do Nothing</td>\n"  
    append select_html \
     "<td><input name=$form_var value=complain type=radio>Return an Error</td>\n"  
    append select_html \
     "<td><input name=$form_var value=fixit type=radio>Set a Default</td>\n"  
    append select_html "</tr> " 
    return $select_html     
}

proc_doc column_form {column} "Makes the forms to ask which form-type the user desires" {
    set select_html "<tr align=right><th>$column:</th>\n"

    set form_var $column
    append form_var "_form_type"
    append select_html \
     "<td><input name=$form_var value=none checked type=radio>None</td>\n"  
    append select_html \
     "<td><input name=$form_var value=textbox type=radio>Textbox</td>\n"  
    append select_html \
     "<td><input name=$form_var value=textarea type=radio>Textarea</td>\n"  
    append select_html \
     "<td><input name=$form_var value=checkbox type=radio>Checkbox</td>\n"  
    append select_html \
     "<td><input name=$form_var value=radiobutton type=radio>Radio</td>\n"  
    append select_html \
     "<td><input name=$form_var value=select type=radio>Select</td>\n"  
    append select_html \
     "<td><input name=$form_var value=boolean type=radio>Boolean</td>\n"   
    append select_html \
     "<td><input name=$form_var value=date type=radio>Date\n <p></td>"  
    append select_html "</tr> " 
    return $select_html     
}


# The procs are used in tableinfo-2.tcl
# A procedure to see if the column was listed as special:
proc_doc check_special {col_name special_cols} "Checks to see if the column was listed as special, like a column id or pretty name, for example" {
    set special_index [lsearch $special_cols $col_name] 
    if {$special_index == -1} {
        return 0
    } else {
        return [expr $special_index + 1]}
}

proc_doc column_select {columns selectname} "produces a selectbox of all the columns listed in the variable columns" {
    set select_html "<select name=$selectname>\n"
    append select_html "<option value=\"none\">None.\n"
    foreach column $columns {
        append select_html "<option value=$column>$column\n"
    }
    append select_html "</select>\n"
    return $select_html
}


#
proc_doc solicit_info {column form_type} "A procedure to get more info about a given form given a column and form-type. Most of the trouble is just going through all the forms types." {
    set form_html "<h4>For $column:</h4>\n"
    append form_html "Please enter the prompt text for entry into your $form_type:<br>\n"
    set prompt_var $column
    append prompt_var "_prompt_text"
    append form_html "<input type=text size=55 name=$prompt_var><br>\n"
    set ei_var $column
    append ei_var "_extra_info"
    set eitwo_var $column
    append eitwo_var "_ei_two"
    set eithree_var $column
    append eithree_var "_ei_three"
    switch $form_type {
        textbox {
            append form_html "How big a textbox do you want?<br> \
                <input name=$ei_var value=small type=radio>&nbsp;Small \n"  
            append form_html \
                "<input name=$ei_var value=medium type=radio>&nbsp;Medium \n"  
            append form_html \
                "<input name=$ei_var value=large type=radio>&nbsp;Large   \n"  
            append form_html \
                "<input name=$ei_var value=spec type=radio> Specify size: \n"
            append form_html \
                  "<input type=text size=3 name=$eitwo_var>\n<br>"}
        textarea {
            append form_html "How big a textarea do you want?<br>\
                <input name=$ei_var value=small type=radio> Small \n"  
            append form_html \
                "<input name=$ei_var value=medium type=radio> Medium \n"  
            append form_html \
                "<input name=$ei_var value=large type=radio> Large \n<br>"  
            append form_html \
                "<input name=$ei_var value=spec type=radio> Specify \n"
            append form_html \
                "Rows: <input type=text size=3 name=$eitwo_var>\n"
            append form_html \
                "Columns: <input type=text size=3 name=$eithree_var>\n<br>"}
        radiobutton -
        checkbox -
        select {
            append form_html \
                "Please input a tcl list of values to fill in your ${form_type}s:<br>"
            append form_html "<input type=text size=55 name=$ei_var><br>\n"}
        boolean {
            append form_html "What kind of boolean do you want?\n<input name=$ei_var value=yn type=radio> Yes/No \n"  
            append form_html \
                "<input name=$ei_var value=tf type=radio> True/False<br>\n"}  
        date {}
        default {}
    }
    return $form_html
}

proc_doc solicit_error_info {column error_type form_type} "A procedure to 
find out what kind of error action a user desires for a given column" {
    set form_html ""
    switch $error_type {
        nothing {}
        complain {
            append form_html "If the user fails to enter input, what error message do you desire?<br>\n"
            set error_var $column
            append error_var "_error_message"
            append form_html "<input type=text size=55 name=$error_var><br>\n"}
        fixit {
            append form_html "What value do you wish to set as the default?<br>\n"
            set error_var $column
            append error_var "_default"
            if [string compare $form_type "date"] {
                append form_html "<input type=text size=55 name=$error_var><br>\n"
            } else {
                append form_html \
                    "<input name=$error_var checked value=now type=radio> Now \n"  
                append form_html \
                    "<input name=$error_var value=spec type=radio> Specify: \n"
                append form_html \
                    "[philg_dateentrywidget_default_to_today $error_var]"
            }
        }
        default {}
    }
    append form_html "<p>"
    return $form_html
}

#Procs from tableinfo-3
#Part One: procs for the add page 

proc_doc my_export_url_vars {alist} "A little helper proc to be able to export a list (a very slight varient of a proc from utilities.tcl)" {
    set params {} 
    foreach var $alist  { 
        if [eval uplevel {info exists $var}] { 
            upvar $var value 
            lappend params "$var=[ns_urlencode $value]" 
        } 
    } 
    return [join $params "&"] 
}            

proc_doc make_form {column form_type prompt eione eitwo eithree value} "The top-level procedure to make a form for the add page. Goes through the form types and calls helper proc handle-{form-types} for each form_type" {
    set form_html "<tr><th valign=top align=right>$prompt</th>\n"
    upvar table_name table_name
    switch $form_type {
        textbox {append form_html \
                  [handle_textbox $column $eione $eitwo $value] "</tr>\n\n"}
        textarea {append form_html [handle_textarea \
                        $column $eione $eitwo $eithree $value] "</tr>\n\n"}
        radiobutton {append form_html\
                   [handle_radio $column $eione $eione $value] "</tr>\n\n"}
        checkbox {append form_html \
                   [handle_checkbox $column $eione $eione $value] "</tr>\n\n"}
        select {append form_html \
                    [handle_select $column $eione $eione $value] "</tr>\n\n"}
        boolean {
            if [string compare $eione "tf"] {
                append form_html [handle_radio $column {t f} {Yes No} $value] "</tr>\n\n"
            } else {
                append form_html [handle_radio $column {t f} {True False} $value] "</tr>\n\n"
            }
        }
        date {append form_html \
                   [handle_date $column $eione $eione $value] "</tr>\n\n"}
        default {
            append form_html "<input type=text size=50 name=$column><p>\n"}
    }
    return $form_html
}

proc_doc handle_textbox {column size customsize value} "Helper proc to make-form that makes a textbox for an add page" {
    set form_html ""
    upvar table_name table_name
    set maxlength [max_col_length $table_name $column]
    switch $size {
    small {
       append form_html "<td><input type=text size=10 name=$column MAXLENGTH=$maxlength></td>"}
    medium {
        append form_html "<td><input type=text size=40 name=$column MAXLENGTH=$maxlength></td>"}
    large {
        append form_html "<td><input type=text size=70 name=$column MAXLENGTH=$maxlength></td>"}
    spec {
        append form_html "<td><input type=text size=$customsize name=$column MAXLENGTH=$maxlength></td>"}
    default {
        append form_html "<td><input type=text size=40 name=$column MAXLENGTH=$maxlength></td>"}
    }
    return $form_html
}

proc_doc handle_textarea {column size rows cols value} "Helper proc to make-form that makes a textarea for an add page" {
    set form_html ""
    switch $size {
        small {
            append form_html "<td><textarea name=$column cols=40 rows=3 wrap=soft>[ns_quotehtml $value]</textarea></td>"}
        medium {
            append form_html "<td><textarea name=$column cols=40 rows=8 wrap=soft>[ns_quotehtml $value]</textarea></td>"}
        large {
            append form_html "<td><textarea name=$column cols=40 rows=15 wrap=soft>[ns_quotehtml $value]</textarea></td>"}
        spec {
            append form_html "<td><textarea name=$column cols=$cols rows=$rows wrap=soft>[ns_quotehtml $value]</textarea></td>"}
        default {
            append form_html "<td><textarea name=$column cols=40 rows=8 wrap=soft>[ns_quotehtml $value]</textarea></td>"}
    }
    return $form_html
}

proc_doc handle_radio {column list_of_vals items defaults} "Helper proc to make-form that makes a radiobutton for an add page" {
    set form_html "<td>"
    set count 0
    foreach val $list_of_vals {
        if {[lsearch -exact $defaults $val] != -1} {
            append form_html " <input name=$column checked \
                value=\\\"$val\\\" type=radio> [lindex $items $count]\n"  
        } else {
            append form_html " <input name=$column \
               value=\\\"$val\\\" type=radio> [lindex $items $count] \n"
        }
        incr count 
    } 
    append form_html "</td>\n" 
    return $form_html
}

proc_doc handle_checkbox {column list_of_vals items defaults} "Helper proc to make-form that makes a checkbox for an add page"  {
    set form_html "<td>"
    set count 0
    foreach val $list_of_vals {
        if {[lsearch -exact $defaults $val] != -1} {
            append form_html \
            "<input name=$column checked value=\\\"$val\\\" type=checkbox>[lindex $items $count] \n"  
        } else {
            append form_html "<input name=$column value=\\\"$val\\\" type=checkbox>[lindex $items $count] \n"    
        }
        incr count 
    } 
    append form_html "</td>\n" 
    return $form_html
}

proc_doc handle_select {column list_of_vals items defaults} "Helper proc to make-form that makes a select for an add page" {
    set form_html "<td><select name=$column>\n"
    set count 0
    foreach val $list_of_vals {
        if {[lsearch -exact $defaults $val] != -1} {
            append form_html "<option selected value=\\\"$val\\\"> [lindex $items $count]  \n"
        } else {
            append form_html "<option value=\\\"$val\\\"> [lindex $items $count]  \n"
        }
        incr count 
    } 
    append form_html "</select></td></tr>\n\n"
    return $form_html
}

proc_doc handle_date {column list_of_vals items defaults} "Helper proc to make-form that makes a date for an add page" {
    append form_html "[philg_dateentrywidget_default_to_today $column]"
    return $form_html
}

######################################################
#Now  do utitities for making a view pages

proc_doc make_report {column form_type prompt eione eitwo eithree} "Make entries for the report page." {
    set form_html "<tr><th valign=top align=right>$prompt</th>\n"
    switch $form_type {
        textbox {append form_html "<td> \$$column </td></tr>\n\n"}
        textarea  {append form_html "<td> \$$column </td></tr>\n\n"}
        radiobutton  {append form_html "<td> \$$column </td></tr>\n\n"}
        checkbox  {append form_html "<td> \$$column </td></tr>\n\n"}
        select {append form_html "<td> \$$column </td></tr>\n\n"}
        boolean {
            if [string compare $eione "tf"] {
                append form_html "<td>"
                switch \$$column {
                    t {ns_write \" Yes \"}
                    f {ns_write \" No \"}
                }
                ns_write "</td></tr>\n\n"
            } else {
                append form_html "<td>" 
                switch \$$column {
                    t {ns_write \"True \"}
                    f {ns_write \" False \"}
                }
                ns_write "</td></tr>\n\n"
            }   
        }
        date {
            append form_html "\"\n"
            append form_html "if \[empty_string_p \$$column\] \{"
            append form_html "\n    ns_write \"<td> No date has been entered. </td></tr>\""
            append form_html "\n\} else \{\n    ns_write \""
            append form_html "<td>\[util_AnsiDatetoPrettyDate \$$column\]</td></tr>\""
            append form_html "\n\}\n\nns_write \""
        }
        default {append form_html "<td> \$$column </td></tr>\n\n"}
    }
    return $form_html
}

# End of utilities for view page                     #
######################################################

######################################################
#Now  do utitities for making a edit pages

proc_doc make_form_code {column form_type prompt eione eitwo eithree} "The top-level procedure to make a form for the edit page code. Goes through the form types and calls helper proc handle-{form-types} for each form_type" {
    upvar table_name table_name
    set form_html "<tr><th valign=top align=right>$prompt</th>\n"
    switch $form_type {
        textbox {append form_html [code_for_textbox $column $eione $eitwo] }
        textarea {append form_html [code_for_textarea $column $eione $eitwo $eithree] }
        radiobutton {append form_html [code_for_radio $column $eione $eione] "</tr>\n\n"}
        checkbox {append form_html [code_for_checkbox $column $eione $eione] "</tr>\n\n"}
        select {append form_html [code_for_select $column $eione $eione] "</tr>\n\n"}
        boolean {
            if [string compare $eione "tf"] {
                append form_html [code_for_radio $column {t f} {Yes No}] "</tr>\n\n"
            } else {
                append form_html [code_for_radio $column {t f} {True False}] "</tr>\n\n"
            }   
        }
        date {
            append form_html "\"\n"
            append form_html "if \[empty_string_p \$$column\] \{"
            append form_html "\n    ns_write \"<td>No date in the database. Set a date: &nbsp;"
            append form_html "\n    \[philg_dateentrywidget_default_to_today $column\]</td></tr>\n\n"
            append form_html "\"\n\} else \{\n    ns_write \""
            append form_html "<td>\[philg_dateentrywidget $column \$$column\]</td></tr>\n\n"
            append form_html "\"\n\}\n\nns_write \""
        }
        default {
            append form_html "<input type=text size=50 name=$column><p>\n"
        }
    }
    return $form_html
}

proc_doc code_for_textbox {column size customsize} "Helper proc to make-form that makes a textbox for edit page code" {
    set form_html ""
    upvar table_name table_name
    set maxlength [max_col_length $table_name $column]
    switch $size {
        small {
            append form_html "<TD><input type=text size=10 MAXLENGTH=$maxlength name=$column \[export_form_value $column\]></TD></TR>\n\n"}
        medium {
            append form_html "<td><input type=text size=40 MAXLENGTH=$maxlength name=$column \[export_form_value $column\]></td></tr>\n\n"}
        large {
            append form_html "<td><input type=text size=70 MAXLENGTH=$maxlength name=$column \[export_form_value $column\]></td></tr>\n\n"}
        spec {
            append form_html "<td><input type=text size=$customsize  MAXLENGTH=$maxlength name=$column \[export_form_value $column\]></td></tr>\n\n"}
        default {
            append form_html "<td><input type=text size=40 name=$column MAXLENGTH=$maxlength \[export_form_value $column\]></td></tr>\n\n"}
    }
    return $form_html
}

proc_doc code_for_textarea {column size rows cols} "Helper proc to make-form that makes a textarea for edit page code" {
    set form_html ""
    switch $size {
    small {
        append form_html "<td><textarea name=$column cols=40 rows=3 wrap=soft>\[ns_quotehtml \$$column\]</textarea></td></tr>\n\n"}
    medium {
        append form_html "<td><textarea name=$column cols=40 rows=8 wrap=soft>\[ns_quotehtml \$$column\]</textarea></td></tr>\n\n"}
    large {
        append form_html "<td><textarea name=$column cols=40 rows=15 wrap=soft>\[ns_quotehtml \$$column\]</textarea></td></tr>\n\n"}
    spec {
        append form_html "<td><textarea name=$column cols=$cols rows=$rows wrap=soft>\[ns_quotehtml \$$column\]</textarea></td></tr>\n\n"}
    default {
        append form_html "<td><textarea name=$column cols=40 rows=8 wrap=soft>\[ns_quotehtml \$$column\]</textarea></td></tr>\n\n"}
    }
    return $form_html
}

proc_doc code_for_radio {column list_of_vals items} "Helper proc to make-form that makes a radiobutton for edit page code" {
    set form_html "<td>"
    set count 0
    foreach val $list_of_vals {
        append form_html "\n<input name=$column value=\\\"$val\\\" type=radio> [lindex $items $count] "  
        incr count 
    } 
    append form_html "</td>\n" 
    set merged_html "\[bt_mergepiece \"$form_html\" \$selection\]\n"
    return $merged_html
}

proc_doc code_for_checkbox {column list_of_vals items} "Helper proc to make-form that makes a checkbox for edit page code" {
    set form_html "<td>"
    set count 0
    foreach val $list_of_vals {
        append form_html "\n<input name=$column value=\\\"$val\\\" type=checkbox>[lindex $items $count] "  
        incr count 
    } 
    append form_html "</td>\n" 
    set merged_html "\[bt_mergepiece \"$form_html\" \$selection\]\n"
    return $merged_html
}

proc_doc code_for_select {column list_of_vals items} "Helper proc to make-form that makes a selectbox for edit page code" {
    #An annoying problem: if my list_of_vals or items contains quotes,
    #they will cause troubles for the ns_writes. They need backslashes
    #(Actually I'm not sure I need this, so I commented out this bit)
    #regsub -all "\"" $list_of_vals "\\\"" fixed_list
    #regsub -all "\"" $items "\\\"" fixed_items
    #In any case the quote_double_quotes is definitely needed.

    set form_html "<td><select name=$column>\n"
    append form_html "\[ad_generic_optionlist \\\n    \{ $list_of_vals\} \\\n    \{$items\} \\\n    \$$column\]"
    append form_html "\n</select></td>\n"
    set merged_html "\[bt_mergepiece \"$form_html\" \$selection\]\n"
    return $merged_html
}

#Now code from tableinfo-edit.tcl

proc_doc make_edit_form {column form_type prompt eione eitwo eithree value select} "The top-level procedure to make a form for the edit page. Goes through the form types and calls helper proc handle_edit_{form-types} for each form_type" {
    set form_html "<tr><th valign=top align=right>$prompt</th>\n"
    switch $form_type {
        textbox {append form_html [handle_edit_textbox $column $eione $eitwo $value] "</tr>\n\n"}
        textarea {append form_html [handle_edit_textarea $column $eione $eitwo $eithree $value] "</tr>\n\n"}
        radiobutton {append form_html [handle_edit_radio $column $eione $eione $value $select] "</tr>\n\n"}
        checkbox {append form_html [handle_edit_checkbox $column $eione $eione $value $select] "</tr>\n\n"}
        select {append form_html [handle_edit_select $column $eione $eione $value] "</tr>\n\n"}
        boolean {
            if [string compare $eione "tf"] {
                append form_html [handle_edit_radio $column {t f} {Yes No} $value $select] "</tr>\n\n"
            } else {
                append form_html [handle_edit_radio $column {t f} {True False} $value $select] "</tr>\n\n"
            }   
        }
        date {
            if [empty_string_p $value] {
                append form_html "<td>No date in the database. Set a date: &nbsp; "
                append form_html "[philg_dateentrywidget_default_to_today $column]</td></tr>\n\n"
            } else {
                append form_html "<td>[philg_dateentrywidget $column $value]</td></tr>\n\n"
            }
        }
        default {
            append form_html "<input type=text size=50 name=$column><p>\n"}
    }
    return $form_html
}

proc_doc handle_edit_textbox {column size customsize value} "Helper proc to make_edit_form that makes a textbox for an edit page" {
    set form_html ""
    switch $size {
        small {
            append form_html "<td><input type=text size=10 name=$column [export_form_value value]></td>"}
        medium {
            append form_html "<td><input type=text size=40 name=$column [export_form_value value]></td>"}
        large {
            append form_html "<td><input type=text size=70 name=$column [export_form_value value]></td>"}
        spec {
            append form_html "<td><input type=text size=$customsize name=$column [export_form_value value]></td>"}
        default {
            append form_html "<td><input type=text size=40 name=$column [export_form_value value]></td>"}
    }
    return $form_html
}

proc_doc handle_edit_textarea {column size rows cols value} "Helper proc to make_edit_form that makes a textarea for an edit page" {
    set form_html ""
    switch $size {
    small {
        append form_html "<td><textarea name=$column cols=40 rows=3 wrap=soft>[ns_quotehtml $value]</textarea></td>"}
    medium {
        append form_html "<td><textarea name=$column cols=40 rows=8 wrap=soft>[ns_quotehtml $value]</textarea></td>"}
    large {
        append form_html "<td><textarea name=$column cols=40 rows=15 wrap=soft>[ns_quotehtml $value]</textarea></td>"}
    spec {
        append form_html "<td><textarea name=$column cols=$cols rows=$rows wrap=soft>[ns_quotehtml $value]</textarea></td>"}
    default {
        append form_html "<td><textarea name=$column cols=40 rows=8 wrap=soft>[ns_quotehtml $value]</textarea></td>"}
    }
    return $form_html
}

proc_doc handle_edit_radio {column list_of_vals items defaults select} "Helper proc to make_edit_form that makes a radiobutton for an edit page" {
    set form_html "<td>"
    set count 0
    foreach val $list_of_vals {
        if {[lsearch -exact $defaults $val] != -1} {
            append form_html " <input name=$column checked value=\\\"$val\\\" type=radio> [lindex $items $count]\n"  
        } else {
            append form_html " <input name=$column value=\\\"$val\\\" type=radio> [lindex $items $count] \n"
        }
        incr count 
    } 
    append form_html "</td>\n" 
    set merged_html "[bt_mergepiece $form_html $select]"
    return $merged_html
}

proc_doc handle_edit_checkbox {column list_of_vals items defaults select} "Helper proc to make_edit_form that makes a checkbox for an edit page" {
    set form_html "<td>"
    set count 0
    foreach val $list_of_vals {
        if {[lsearch -exact $defaults $val] != -1} {
            append form_html "<td><input name=$column checked value=\\\"$val\\\" type=checkbox>[lindex $items $count]</td> \n"  
        } else {
            append form_html "<td><input name=$column value=\\\"$val\\\" type=checkbox>[lindex $items $count]</td> \n"    
        }
        incr count 
    } 
    #append form_html "</td>\n" 
    set merged_html "[bt_mergepiece $form_html $select]"
    return $merged_html
}

proc_doc handle_edit_select {column list_of_vals items defaults} "Helper proc to make_edit_form that makes a select for an edit page" {
    set form_html "<td><select name=$column>\n"
    append form_html "[ad_generic_optionlist $list_of_vals $items $defaults]"
    append form_html "</select></td>\n"
    return $form_html
}
