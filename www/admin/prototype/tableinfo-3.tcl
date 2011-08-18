# $Id: tableinfo-3.tcl,v 3.0.4.1 2000/04/28 15:09:17 carsten Exp $
set_the_usual_form_variables

#list_of_cols, table_name, list_ord_cols, base_file_name, list_name_plural,list_name_sing, base_file_name, base_dir_name, page_head, back_phrase, back_link, back_text, primary_key, creation_date, creation user, row_name, seq_name, unique_key, visible_row, ${column}_error_action, ${column}_form_type,${column}_prompt_text, ${column}_extra_info, ${column}_ei_two, ${column}_ei_three

#It is slightly complicated which variables we expect from tableinfo-2
#First, we are getting (for sure) a list_of_cols and table_name
#also, a list_ord_cols, and a  base_file_name
#Second, we are definitely getting list_name_plural and list_name_sing
#base_file_name and base_dir_name
#page_head back_phrase, back_link and back_text.
#Next, primary_key, creation_date, creation_user and row_name
#   whose values are either "none" or one of the columns
#   also there may be a sequence name in seq_name
# Or if no primary key, we should get unique_key
# Similarly, if no row_name, we should get visible_row
#Next, for each column in the list of columns, we are getting
#   ${column}_error_action and ${column}_form_type
#   ${column}_prompt_text, ${column}_extra_info 
#   maybe also ${column}_ei_two and ${column}_ei_three
#  which may have values "none" or any of a number of options


# I want a list of all the variables I got so I can export them again
set list_all_vars {}
set form [ns_getform]
set form_size [ns_set size $form]
set form_counter_i 0
while {$form_counter_i<$form_size} {
    lappend list_all_vars [ns_set key $form $form_counter_i]
    incr form_counter_i
}

#set up the variables that will contain the code for the return
#pages. 
set code_list ""
set code_add ""
set code_add_insert ""
set code_edit ""
set code_edit_insert ""

#Check whether we got a primary key or row name. Correct if not.
set exception_count 0
set exception_text ""
set primary_key_not_integer_flag 0
set row_name_not_official 0
if {![string compare $primary_key "none"]} {
    if {![string compare $unique_key "none"]} {
       #Problem -- neither primary key nor unique key
    incr exception_count
    append exception_text "We must have a unique key for our row!<br>"
    } else {
    set primary_key $unique_key
        set primary_key_not_integer_flag 1
    } 
}

if {![string compare $row_name "none"]} {
    if {![string compare $visible_row "none"]} {
       #Problem -- neither primary key nor unique key
    incr exception_count
    append exception_text "We must have a column we can display!<br>"
    } else {
    set row_name $visible_row
        set row_name_not_official 1
    } 
}

if {$exception_count>0} {
    ad_return_complaint $exception_count $exception_text
    return
}


ReturnHeaders

ns_write "

[ad_header \"$page_head\"]

<h2>Generated Code</h2>

by the <A HREF=index.tcl>Prototype tool</A>

<HR>
"
#<h3>All the $list_name_plural</h3><ul>


set count 0
set db [ns_db gethandle]
set list_of_names [database_to_tcl_list_list $db \
                      "select $row_name, $primary_key from $table_name"]
set list_for_export [lappend list_all_vars name_of_object key_for_object]
foreach pair $list_of_names {
  incr count
  set name_of_object [lindex $pair 0]
  set key_for_object [lindex $pair 1]
#  ns_write "<li><a href=\"tableinfo-edit.tcl?[my_export_url_vars $list_for_export]\">$name_of_object</a><br>\n"
#  if {$count>50} {
#      ns_write "<br><li>We are only listing the first fifty values here."
#      break 
#  } 
}
#ns_write "</ul><h3>Add a $list_name_sing</h3>"
#
#ns_write "
#
#<form method=POST action=doctest.html>"
#
set my_html "<table>\n"
#ns_write "<table>\n"
foreach column $list_ord_cols {
    set form_var $column
    append form_var "_form_type"
    set form_type($column) [set $form_var]
    set prompt_var $column
    append prompt_var "_prompt_text"
    set prompt_text($column) [set $prompt_var]
    set eione_var $column
    append eione_var "_extra_info"
    if ![info exists $eione_var] {set $eione_var ""}
    set extra_info($column) [set $eione_var]
    set eitwo_var $column
    append eitwo_var "_ei_two"
    if ![info exists $eitwo_var] {set $eitwo_var ""}
    set ei_two($column) [set $eitwo_var]
    set eithree_var $column
    append eithree_var "_ei_three"
    if ![info exists $eithree_var] {set $eithree_var ""}
    set ei_three($column) [set $eithree_var]
    set error_var $column
    append error_var "_default"

    ## Special date processing. This is terribly ugly, but can't be helped
    if ![string compare [set $form_var] "date"] {
    #we are of type date. This requires special processing
#    ns_write "<tr><th valign=top align=right>[set $prompt_var]</th>\n"
       append my_html "<tr><th valign=top align=right>[set $prompt_var]</th>\n"
#        #nasty awful cluge. This sets default to now if none specified.
    if ![info exists $error_var] {set $error_var "now"}
    if ![string compare [set $error_var] "now"] {
#        ns_write "<td>[philg_dateentrywidget_default_to_today $column]</td></tr>\n\n"
            append my_html {<td>[philg_dateentrywidget_default_to_today }
            append my_html "$column\]</td></tr>\n\n"
        } else {
        # We have to set a default value for the date. 
        set  exception_count 0
        set  exception_text ""
     if [catch { ns_dbformvalue \
                   [ns_conn form] $error_var date entry_date } errmsg] {
              incr exception_count
              append exception_text "
                    <li>Please enter a valid date for the entry date"
         }
         #ns_write "Entry Date:$entry_date<br>"
         #ns_write "Error Message:$errmsg<br>"
         if { $exception_count > 0 } {
             ad_return_complaint $exception_count $exception_text
             return
         }

#    ns_write "<td>[philg_dateentrywidget [set $error_var] $entry_date]</td></tr>\n\n"
     append my_html {<td>[philg_dateentrywidget }
     append my_html "$column $entry_date\]</td></tr>\n\n"
     }
   } else {

    if ![info exists $error_var] {set $error_var ""}
#    ns_write "[make_form $column [set $form_var] [set $prompt_var] [set $eione_var] [set $eitwo_var]  [set $eithree_var] [set $error_var]]"   
    append my_html "[make_form $column [set $form_var] [set $prompt_var] [set $eione_var] [set $eitwo_var]  [set $eithree_var] [set $error_var]]"   

   }
}
#ns_write "</table>\n"
append my_html "</table>\n"

######################################################
# Now echo this for returning as code to a list page #

append code_list "#Code for ${base_file_name}-list.tcl\n\n"

#append code_list {set user_id [ad_verify_and_get_user_id]
#if } "{" {[string compare $user_id 0] == 0 } "} "
#append code_list "{\n     ad_returnredirect \n    "
#append code_list {/register/index.tcl?return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]}
#append code_list "\" \n}"
#append code_list "\n\n"

append code_list "ReturnHeaders\n"

append code_list "ns_write \""
append code_list {[ad_header} " \"$page_head\" " {]}

append code_list "\n<h2>$page_head</h2>\n

\[ad_context_bar_ws \[list \"$back_link\" \"$back_text\"\] \"List $list_name_plural\"\]

<hr>\n
<h3>All the $list_name_plural</h3>\n<ul>\"\n"

append code_list "
set db \[ns_db gethandle\]
set sql_query  \"select $row_name, $primary_key from $table_name\"
set selection \[ns_db select \$db \$sql_query\] 

set counter 0
while \{ \[ns_db getrow \$db \$selection\] \} \{
    set_variables_after_query
    incr counter
    ns_write \"<li><a href=\\\"${base_file_name}-view.tcl?\[export_url_vars $primary_key\]\\\">\$$row_name</a><br>\"
\}

if \{ \$counter == 0 \} \{
    ns_write \"<li>There are no $list_name_plural in the database right now.<p>\"
\}

ns_write \"<p><li><a href=\\\"${base_file_name}-add.tcl\\\">Add a $list_name_sing</a></ul><p>\n"

append code_list "\[ad_footer\]\""

# End of code generation for list page               #
######################################################

######################################################
# Now echo this for returning as code to add    page #

#Page to get data from user for insert into $table_name 
#This file should be called ${base_file_name}-add.tcl\n\n"
set code_add "#Code for ${base_file_name}-add.tcl\n\n"

#append code_add {set user_id [ad_verify_and_get_user_id]
#if } "{" {[string compare $user_id 0] == 0 } "} "
#append code_add "{\n    " {ad_returnredirect \"} "\n"
#append code_add {/register/index.tcl?return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]}
#append code_add "\" \n}"
#append code_add "\n\n"

append code_add "ad_maybe_redirect_for_registration\n"

append code_add {set db [ns_db gethandle]}
#now echo for my record 
append code_add "\nReturnHeaders \n

ns_write \"
\[ad_header \"Add a $list_name_sing\"\]

<h2>Add a $list_name_sing</h2>

\[ad_context_bar_ws \[list \"$back_link\" \"$back_text\"\] \"Add a $list_name_sing\"\]

<hr>

<form method=POST action=\\\"${base_file_name}-add-2.tcl\\\"> \n\n"

append code_add "$my_html"

#Finish up the page for the mycode_add to be shown to the user
#append code_add "\n" {[export_form_vars user_id]} "\n"

if {[info exists seq_name]&&![empty_string_p $seq_name]} {
    append code_add "<input type=hidden name=$primary_key value=\\\""
    append code_add {[database_to_tcl_string $db "}
    append code_add "\nselect ${seq_name}.nextval from dual\"]\\\">"
} else { 
    if {!$primary_key_not_integer_flag } {
    #The primary key is an integer but we don't have a sequence.
    #Should I do something here?
    } else {
    #In this case we don't even have an integer primary key
    #Is there anything we can do to provide double-click protection?
  }
}


append code_add "
<p>
<center>
<input type=submit value=\\\"Add the $list_name_sing\\\">
</center>
</form>
<p>\n"
append code_add {[ad_footer]"}


# End of code generation for add page                #
######################################################

######################################################
# Now build the code for the insert page             #

# Some information I need to know to build code
set list_of_checks {}
set list_selectradio {}
foreach column $list_ord_cols {
    switch $form_type($column) {
    checkbox { 
        lappend list_of_checks $column
    }
        radiobutton { 
        lappend list_selectradio $column
    }
        select {
        lappend list_selectradio $column
    }
        boolean {
        lappend list_selectradio $column
    }
        default  {}
    }
}

set code_add_insert {#This is not done yet! Don't expect it to work!}
set code_add_insert "#This file should be called ${base_file_name}-add-2.tcl\n"
#append code_add_insert "\n#Target for ${base_file_name}-add.tcl"
#append code_add_insert "\n#The expected variables are "
#append code_add_insert "[join $list_ord_cols ", "]\n"
#append code_add_insert "#Also user_id, the id of the user found on add page\n"


#if {[info exists seq_name]&&![empty_string_p $seq_name]} {
#append code_add_insert "#And $primary_key, the sequence value generated on add page\n"
#}


if {$list_of_checks != {}} {
append code_add_insert\
 "\n#Special processing for checkbuttons."
}

foreach column $list_of_checks {
    append code_add_insert\
        "\n#The expected variable here is $column\n"
    set list_var "list_of_"
    append list_var $column "s"
    set list_of($column) $list_var

    append code_add_insert "if \{\[ns_conn form \] == "
    append code_add_insert "\"\" \} \{\n"
    append code_add_insert "    set $list_var \"\"\n"
    append code_add_insert "\} else \{\n    "
    append code_add_insert "set $list_var \["
    append code_add_insert "nmc_GetCheckboxValues \[ns_conn form"
    append code_add_insert "\] $column\]\n" 
    append code_add_insert "\}\n\n"    
}

#echo for code_add_insert returned to user
append code_add_insert {set_the_usual_form_variables}


append code_add_insert "\n\n# [join $list_ord_cols ", "]" 

if {[info exists seq_name]&&![empty_string_p $seq_name]} {
append code_add_insert ", $primary_key\n"
} else {
append code_add_insert "\n"
}
 
append code_add_insert "set user_id \[ad_get_user_id\]\n" 
foreach column $list_of_checks {
    append code_add_insert\
     "\n\n#Now set the checkbutton variable $column to the proper values \n"
    append code_add_insert "set $column \$$list_of($column)\n"
    append code_add_insert \
        "set QQ$column \[DoubleApos \$$list_of($column)\]\n"
}

#Safeguard against errors caused by unselected radios or selects
if {$list_selectradio != {}} {
    append code_add_insert\
    "\n#Radiobuttons and selects may give us trouble if none are selected"
    append code_add_insert\
    "\n#The columns that might cause trouble are [join $list_selectradio ", "]"
}

foreach column $list_selectradio {
    append code_add_insert "\nif !\[info exists $column\] \{\n"
    append code_add_insert "    set $column \"\"\n"
    append code_add_insert "    set QQ$column \"\"\n"
    append code_add_insert "\}"
}

append code_add_insert\
 "\n\n#Now check to see if the input is good as directed by the page designer"
append code_add_insert "\n\n" {set exception_count 0} "\n"
append code_add_insert "set exception_text \"\"\n"

foreach column $list_ord_cols {
    set action_var $column
    append action_var "_error_action"
    
    ## Special date processing. This is terribly ugly, but can't be helped
    set form_var $column
    append form_var "_form_type"
    if ![string compare [set $form_var] "date"] {
        #we always need to check and complain when getting dates
    append code_add_insert\
          "\n\n# it doesn't matter what instructions we got,\n"
    append code_add_insert\
          "#  since $column is of type date and thus must be checked.\n"
        append code_add_insert "if \[catch \{ ns_dbformvalue \[ns_conn form\] $column date $column \} errmsg\] \{
        incr exception_count
        append exception_text \"<li>Please enter a valid date for the entry date.\"
\}"
     } else {
     switch [set $action_var] {
     complain {
         #put error-checking information in returned code
         append code_add_insert\
             "\n\n# we were directed to return an error for $column\n"
         append code_add_insert  {if} " \{"
         append code_add_insert {![info exists }
         append code_add_insert "$column] || "
         append code_add_insert {[empty_string_p $}
         append code_add_insert \
             "[set column]]\} \{\n    incr exception_count\n"
         
         set error_var $column
         append error_var "_exception_text"
        if {[info exists $error_var]&&![empty_string_p [set $error_var]]} {
         append code_add_insert  "    append exception_text"
         append code_add_insert " \""
         append code_add_insert \
             "<li>[philg_quote_double_quotes [set $error_var]]"
         append code_add_insert "<br>\"\n" "\} "
         } else {
         append code_add_insert\
             "    append exception_text \"<li>You did not enter "
                 append code_add_insert \
             "a value for $column.<br>\"\n\} "
         }
       
    }
        fixit  {
    set error_var $column
    append error_var "_default"
    if {[info exists $error_var]&&![empty_string_p [set $error_var]]} {
        #put error-checking information in returned code
            append code_add_insert\
            "\n\n# we were directed to set a default for $column\n"
            append code_add_insert  {if} " {"
            append code_add_insert {![info exists }
            append code_add_insert "$column\] ||"
            append code_add_insert {[empty_string_p $}
            append code_add_insert "[set column]\]\} \{\n "
            append code_add_insert "    set $column [set $error_var]"
            append code_add_insert " \n     set QQ$column "
            append code_add_insert {[DoubleApos }
            append code_add_insert "[set $error_var]] \n}" 
    } else {
    }
    }
        default {
    }
    }
}
}

# The code that checks if all the variables are shorter 
# than the max length of the column


foreach element $list_ord_cols {
    set max_length [max_col_length $table_name $element]
    if {$max_length > 200} {
        append code_add_insert "
if \{\[string length \$$element\] > $max_length\} \{
    incr exception_count
    append exception_text \"<LI>\\\"$element\\\" is too long\\n\"
\}
"
}
}

#Finish the error-checking entry into code_add_insert variable
append code_add_insert "\nif" " {" {$exception_count } "> 0} " "{\n"
append code_add_insert "    ad_return_complaint " {$exception_count $exception_text} "\n"
append code_add_insert "    return\n" "}\n"

append code_add_insert "\n# So the input is good --"

append code_add_insert "\n# Now we'll do the insertion in the $table_name table.\n"

append code_add_insert {set db [ns_db gethandle]} "\n"

#append code_add_insert {ns_db dml $db \"begin transaction\"}
#append code_add_insert {ns_db dml $db}

#Now build my update statement
set insert_list {}
set insert_val_list {}


if {[info exists seq_name]&&![empty_string_p $seq_name]} {
    lappend insert_list $primary_key
    lappend insert_val_list "\$$primary_key"  
}


if {[string compare $creation_date "none"]} {
    lappend insert_list $creation_date
    lappend insert_val_list sysdate
}                 

if {[string compare $creation_user "none"]} {
    lappend insert_list "$creation_user"
    lappend insert_val_list "\$user_id"  
}                 

foreach column $list_ord_cols { 
    ## Special date processing. This is terribly ugly, but can't be helped
    set form_var $column
    append form_var "_form_type"
    if ![string compare [set $form_var] "date"] {
    lappend insert_list $column
    lappend insert_val_list "to_date('\$$column','YYYY-MM-DD')"    
     } else {
    #a normal column; should be user submitted info in column var
     lappend insert_list $column
     lappend insert_val_list "'\$QQ$column'"    
     }   
 }

set insert_string [join $insert_list ", "]
set insert_val_string [join $insert_val_list ", "]


append code_add_insert {if [catch } "{"
append code_add_insert {ns_db dml $db}
append code_add_insert " \"insert into $table_name
      ($insert_string)
      values
      ($insert_val_string)\""
append code_add_insert " } errmsg] {\n"
append code_add_insert "\n    # Oracle choked on the insert"

if {[info exists seq_name]&&![empty_string_p $seq_name]} {
   
    append code_add_insert "\n" {    if } "\{ " {[}
    append code_add_insert { database_to_tcl_string $db "select count(*) from }
    append code_add_insert "$table_name where $primary_key = "
    append code_add_insert  "\$$primary_key\"\] == 0"
    append code_add_insert " \} \{ \n\n    "
    append code_add_insert {# there was an error with the insert other than a duplication} "\n"

    }

append code_add_insert "    " {ad_return_error "Error in insert" "We were unable to do your insert in the database. 
Here is the error that was returned:
<p>
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>"
    return
    }      }

if {[info exists seq_name]&&![empty_string_p $seq_name]} {
    append code_add_insert "\n\} "
}

append code_add_insert "\n"
#append code_add_insert {ns_db dml $db \"end transaction\"}

append code_add_insert {ad_returnredirect }
append code_add_insert "${base_file_name}-list.tcl"


# End of code generation for insert (add-2) page     #
######################################################

######################################################
# Now build the code for the view page               #
set selectlist [join $list_ord_cols ", "]

set code_view "#This file should be called ${base_file_name}-view.tcl"
append code_view "\n#Called from ${base_file_name}-list.tcl\n"
#append code_view "\n#The expected variables are "
#append code_view "$primary_key, the id of the row we wish to view" "\n"
#append code_view "#Also user_id, the id of the current user.\n"

append code_view {set_the_usual_form_variables} "\n\n"

append code_view "# $primary_key\n\n"

append code_view "set db \[ns_db gethandle\]
set selection \[ns_db 1row \$db \"
    select $selectlist
    from $table_name 
    where $primary_key='\[DoubleApos \$$primary_key\]'\"\]
set_variables_after_query

#now we have the values from the database."

append code_view "\n\nReturnHeaders

ns_write \"
\[ad_header \"View the entry for \$$row_name\"\]

<h2>View the entry for \$$row_name</h2>

\[ad_context_bar_ws \[list \"$back_link\" \"$back_text\"\] \"View a $list_name_sing\"\]

<hr>\n\n"

# Make the report:

# I think this was a bug -- dvr
# ns_write \""

append code_view "<table>\n"
foreach column $list_ord_cols {
  append code_view "[make_report $column $form_type($column)\
   $prompt_text($column) $extra_info($column) $ei_two($column)\
   $ei_three($column)]"  
}

append code_view "</table>"

#Finish up the page for the mycode_view to be shown to the user

append code_view "
<ul>
<li><a href=\\\"${base_file_name}-edit.tcl?\[export_url_vars $primary_key\]\\\">Edit the data for \$$row_name</a><br>
</ul>
<p>\n"
append code_view "\[ad_footer\]\""


# End of code generation for view page               #
######################################################

set selectlist [join $list_ord_cols ", "]

######################################################
# Now build the code for the edit page               #

set code_edit "#This file should be called ${base_file_name}-edit.tcl"
append code_edit "\n#Called from ${base_file_name}-list.tcl\n"
#append code_edit "\n#The expected variables are "
#append code_edit "$primary_key, the id of the row we wish to edit" "\n"
#append code_edit "#Also user_id, the id of the current user.\n"

append code_edit {set_the_usual_form_variables} "\n\n"

append code_edit "# $primary_key\n\n"

append code_edit "ad_maybe_redirect_for_registration\n"
append code_edit "set db \[ns_db gethandle\]
if {\[catch \{set selection \[ns_db 1row \$db \"
    select $selectlist
    from $table_name 
    where $primary_key=\$$primary_key\"\]} errmsg\]} {
    ad_return_error \"Error in finding the data\" \"We encountered an error in querying the database for your object.
Here is the error that was returned:
<p>
<blockquote>
<pre>
\$errmsg
</pre>
</blockquote>\"
    return
} 


set_variables_after_query

#now we have the values from the database."

append code_edit "\n\nReturnHeaders

ns_write \"
\[ad_header \"Edit the entry for \$$row_name\"\]

<h2>Edit the entry for \$$row_name</h2>

\[ad_context_bar_ws \[list \"$back_link\" \"$back_text\"\] \"Edit a $list_name_sing\"\]

<hr>

<form method=POST action=${base_file_name}-edit-2.tcl>
\[export_form_vars $primary_key\]\" 

# Make the forms:

ns_write \""
append code_edit "<table>\n"
foreach column $list_ord_cols {
  append code_edit "[make_form_code $column $form_type($column)\
   $prompt_text($column) $extra_info($column) $ei_two($column)\
   $ei_three($column)]"  
}
append code_edit "</table>"

#Finish up the page for the mycode_edit to be shown to the user

append code_edit "
<p>
<center>
<input type=submit value=\\\"Edit \$$row_name\\\">
</center>
</form>
<p>\n"
append code_edit "\[ad_footer\]\""


# End of code generation for edit page               #
######################################################

######################################################
# Now build the code for the insert page             #

# Some information I need to know to build code
set list_of_checks {}
set list_selectradio {}
foreach column $list_ord_cols {
    switch $form_type($column) {
    checkbox { 
        lappend list_of_checks $column
    }
        radiobutton { 
        lappend list_selectradio $column
    }
        select {
        lappend list_selectradio $column
    }
        boolean {
        lappend list_selectradio $column
    }
        default  {}
    }
}


set code_edit_insert "#This file should be called ${base_file_name}-edit-2.tcl\n"
#append code_edit_insert "\n#Target for ${base_file_name}-edit.tcl"
#append code_edit_insert "\n#The expected variables are "
#append code_edit_insert "[join $list_ord_cols ", "]\n"
#append code_edit_insert "#and user_id, the id of the user found on add page\n"


#if {[info exists seq_name]&&![empty_string_p $seq_name]} {
#append code_edit_insert \
#    "#And $primary_key, the key of the object we are editing\n"
#}



if {$list_of_checks != {}} {
append code_edit_insert\
 "\n\n#Special processing for checkbuttons."
}

foreach column $list_of_checks {
    append code_edit_insert\
        "\n#The expected variable here is $column\n"
    set list_var "list_of_"
    append list_var $column "s"
    set list_of($column) $list_var

    append code_edit_insert "if \{\[ns_conn form \] == "
    append code_edit_insert "\"\" \} \{\n"
    append code_edit_insert "    set $list_var \"\"\n"
    append code_edit_insert "\} else \{\n    "
    append code_edit_insert "set $list_var \["
    append code_edit_insert "nmc_GetCheckboxValues \[ns_conn form"
    append code_edit_insert "\] $column\]\n" 
    append code_edit_insert "\}\n\n"    
}

#echo for code_edit_insert returned to user
append code_edit_insert {set_the_usual_form_variables}

append code_edit_insert "\n\n# [join $list_ord_cols ", "]" 

if {[info exists seq_name]&&![empty_string_p $seq_name]} {
append code_edit_insert ", $primary_key\n"
} else {
append code_edit_insert "\n"
}
append code_edit_insert "set user_id \[ad_get_user_id\]\n" 

foreach column $list_of_checks {
    append code_edit_insert\
     "\n\n#Now set the checkbutton variable $column to the proper values \n"
    append code_edit_insert "set $column \$$list_of($column)\n"
    append code_edit_insert \
        "set QQ$column \[DoubleApos \$$list_of($column)\]\n"
}

#Safeguard against errors caused by unselected radios or selects
if {$list_selectradio != {}} {
    append code_edit_insert\
    "\n#Radiobuttons and selects may give us trouble if none are selected"
    append code_edit_insert\
    "\n#The columns that might cause trouble are [join $list_selectradio ", "]"
}

foreach column $list_selectradio {
    append code_edit_insert "\nif !\[info exists $column\] \{\n"
    append code_edit_insert "    set $column \"\"\n"
    append code_edit_insert "    set QQ$column \"\"\n"
    append code_edit_insert "\}"
}

append code_edit_insert\
 "\n\n#Now check to see if the input is good as directed by the page designer"
append code_edit_insert "\n\n" {set exception_count 0} "\n"
append code_edit_insert "set exception_text \"\"" 

foreach column $list_ord_cols {
    set action_var $column
    append action_var "_error_action"
    
    ## Special date processing. This is terribly ugly, but can't be helped
    set form_var $column
    append form_var "_form_type"
    if ![string compare [set $form_var] "date"] {
        #we always need to check and complain when getting dates
    append code_edit_insert\
          "\n\n# it doesn't matter what instructions we got,\n"
    append code_edit_insert\
          "#  since $column is of type date and thus must be checked.\n"
        append code_edit_insert "if \[catch \{ ns_dbformvalue \[ns_conn form\] $column date $column \} errmsg\] \{
        incr exception_count
        append exception_text \"<li>Please enter a valid date for the entry date.\"
\}"
     } else {
     switch [set $action_var] {
     complain {
         #put error-checking information in returned code
         append code_edit_insert\
             "\n\n# we were directed to return an error for $column\n"
         append code_edit_insert  {if} " \{"
         append code_edit_insert {![info exists }
         append code_edit_insert "$column] ||"
         append code_edit_insert {[empty_string_p $}
         append code_edit_insert \
             "[set column]]\} \{\n    incr exception_count\n"
         
         set error_var $column
         append error_var "_exception_text"
        if {[info exists $error_var]&&![empty_string_p [set $error_var]]} {
         append code_edit_insert  "    append exception_text"
         append code_edit_insert " \""
         append code_edit_insert \
             "<li>[philg_quote_double_quotes [set $error_var]]"
         append code_edit_insert "<br>\"\n" "\} "
         } else {
         append code_edit_insert\
             "    append exception_text \"<li>You did not enter "
                 append code_edit_insert \
             "a value for $column.<br>\"\n\} "
         }
       
    }
        fixit  {
    set error_var $column
    append error_var "_default"
    if {[info exists $error_var]&&![empty_string_p [set $error_var]]} {
        #put error-checking information in returned code
            append code_edit_insert\
            "\n\n# we were directed to set a default for $column\n"
            append code_edit_insert  {if} " {"
            append code_edit_insert {![info exists }
            append code_edit_insert "$column] ||"
            append code_edit_insert {[empty_string_p $}
            append code_edit_insert "[set column]]\} \{\n "
            append code_edit_insert "    set $column \"[set $error_var]"
            append code_edit_insert "\" \n     set QQ$column "
            append code_edit_insert {[DoubleApos }
            append code_edit_insert "\"[set $error_var]\"] \n}" 
    } else {
    }
    }
        default {
    }
    }
}
}

# The code that checks if all the variables are shorter 
# than the max length of the column

foreach element $list_ord_cols {
    set max_length [max_col_length $table_name $element]
    if {$max_length > 200} {
        append code_edit_insert "
if \{\[string length \$$element\] > $max_length\} \{
    incr exception_count
    append exception_text \"<LI>\\\"$element\\\" is too long\\n\"
\}
"
}
}


#Finish the error-checking entry into code_edit_insert variable
append code_edit_insert "\nif" " {" {$exception_count } "> 0} " "{\n"
append code_edit_insert "    ad_return_complaint " {$exception_count $exception_text} "\n"
append code_edit_insert "    return\n" "}\n"

append code_edit_insert "\n# So the input is good --"

append code_edit_insert "\n# Now we'll do the update of the $table_name table.\n"

append code_edit_insert {set db [ns_db gethandle]} "\n"

#append code_edit_insert {ns_db dml $db \"begin transaction\"}
#append code_edit_insert {ns_db dml $db}

#Now build my update statement
set the_sets {}

if {[string compare $creation_date "none"]} {
    lappend the_sets "$creation_date = sysdate"
}                 

if {[string compare $creation_user "none"]} {
    lappend the_sets "$creation_user = \$user_id"
}                 

foreach column $list_ord_cols { 
    ## Special date processing. This is terribly ugly, but can't be helped
    set form_var $column
    append form_var "_form_type"
    if ![string compare [set $form_var] "date"] {
    lappend the_sets "$column = to_date('\$$column','YYYY-MM-DD')"    
     } else {
    #a normal column; should be user submitted info in column var
     lappend the_sets "$column = '\$QQ$column'"
     }   
 }

set set_string [join $the_sets ", "]

append code_edit_insert {if [catch } "{"
append code_edit_insert {ns_db dml $db}
append code_edit_insert " \"update $table_name 
      set $set_string
      where $primary_key = '\$$primary_key'\""
append code_edit_insert " } errmsg] {\n"
append code_edit_insert "\n# Oracle choked on the update\n"

append code_edit_insert "    " {ad_return_error "Error in update" 
"We were unable to do your update in the database. Here is the error that was returned:
<p>
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>"
    return
}      }

append code_edit_insert "\n\n"
#append code_edit_insert {ns_db dml $db \"end transaction\"}

append code_edit_insert {ad_returnredirect }
append code_edit_insert "${base_file_name}-list.tcl"


# End of code generation for insert (add-2) page     #
######################################################

set mycode_list [philg_quote_double_quotes $code_list]
set mycode_add [philg_quote_double_quotes $code_add]
set mycode_add_insert [philg_quote_double_quotes $code_add_insert]
set mycode_view [philg_quote_double_quotes $code_view]
set mycode_edit [philg_quote_double_quotes $code_edit]
set mycode_edit_insert [philg_quote_double_quotes $code_edit_insert]

#ns_write "
#<p>
#<center>
#<input type=submit value=\"Submit\">
#</center>
#</form>
#
#<p>
#<hr>
#<h2>Retrieve code for These Pages</h2>"

set dirlen [string length $base_dir_name]
ns_write "Code will be saved under the webroot
 (that is, [ns_info pageroot])<br>
 in the directory and file shown below.
You may edit the directory name if you wish.
<form method=POST action=returncode.tcl>"
set base_name ${base_file_name}-list.tcl
ns_write "<input type=text size=$dirlen name=base_dir_name [export_form_value base_dir_name]>/$base_name: &nbsp; &nbsp;
<input type=submit name=whattodo value=\"View code\"> &nbsp;
<input type=submit name=whattodo value=\"Save code\"> &nbsp;
<input name=mycode type=hidden value=\"$mycode_list\">
[export_form_vars base_name]
</form>
<form method=POST action=returncode.tcl>"
set base_name ${base_file_name}-add.tcl
ns_write "<input type=text size=$dirlen name=base_dir_name [export_form_value base_dir_name]>/$base_name: &nbsp; &nbsp;
<input type=submit name=whattodo value=\"View code\"> &nbsp;
<input type=submit name=whattodo value=\"Save code\"> &nbsp;
<input name=mycode type=hidden value=\"$mycode_add\">
[export_form_vars base_name]
</form>
<form method=POST action=returncode.tcl>"
set base_name ${base_file_name}-add-2.tcl
ns_write "<input type=text size=$dirlen name=base_dir_name [export_form_value base_dir_name]>/$base_name:
<input type=submit name=whattodo value=\"View code\"> &nbsp;
<input type=submit name=whattodo value=\"Save code\"> &nbsp;
<input name=mycode type=hidden value=\"$mycode_add_insert\">
[export_form_vars base_name]
</form>
<form method=POST action=returncode.tcl>"
set base_name ${base_file_name}-view.tcl
ns_write "<input type=text size=$dirlen name=base_dir_name [export_form_value base_dir_name]>/$base_name: &nbsp; &nbsp;
<input type=submit name=whattodo value=\"View code\"> &nbsp;
<input type=submit name=whattodo value=\"Save code\"> &nbsp;
<input name=mycode type=hidden value=\"$mycode_view\">
[export_form_vars base_name]
</form>
<form method=POST action=returncode.tcl>"
set base_name ${base_file_name}-edit.tcl
ns_write "<input type=text size=$dirlen name=base_dir_name [export_form_value base_dir_name]>/$base_name: &nbsp; &nbsp;
<input type=submit name=whattodo value=\"View code\"> &nbsp;
<input type=submit name=whattodo value=\"Save code\"> &nbsp;
<input name=mycode type=hidden value=\"$mycode_edit\">
[export_form_vars base_name]
</form>
<form method=POST action=returncode.tcl>"
set base_name ${base_file_name}-edit-2.tcl
ns_write "<input type=text size=$dirlen name=base_dir_name [export_form_value base_dir_name]>/$base_name: 
<input type=submit name=whattodo value=\"View code\"> &nbsp;
<input type=submit name=whattodo value=\"Save code\"> &nbsp;
<input name=mycode type=hidden value=\"$mycode_edit_insert\">
[export_form_vars base_name]
</form>
<form method=POST action=returncodeall.tcl>"
ns_write "Or save all the code in <input type=text size=$dirlen name=base_dir_name [export_form_value base_dir_name]>: &nbsp;
<input type=submit name=whattodo value=\"Save code\"> &nbsp;
<input name=mycode_list type=hidden value=\"$mycode_list\">
<input name=mycode_add type=hidden value=\"$mycode_add\">
<input name=mycode_add_insert type=hidden value=\"$mycode_add_insert\">
<input name=mycode_view type=hidden value=\"$mycode_view\">
<input name=mycode_edit type=hidden value=\"$mycode_edit\">
<input name=mycode_edit_insert type=hidden value=\"$mycode_edit_insert\">
[export_form_vars base_file_name]
</form>
After saving, you may go to the <a href=\"/$base_dir_name/${base_file_name}-list.tcl\">front 
page</a> of the new module.
<p>


<hr>
<address>rfrankel@athena.mit.edu</address>
</body>
</html>
"

