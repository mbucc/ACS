# $Id: tableinfo-edit.tcl,v 3.0.4.1 2000/04/28 15:09:18 carsten Exp $
#It is slightly complicated which variables we expect from tableinfo
#First, we are getting (for sure) a list_of_cols and table_name
#also, a list_ord_cols, a  user_id and a  base_file_name
#Second, we are definitely getting list_name_plural and list_name_sing
#page_head back_phrase, back_link and back_text.
#Next, primary_key, creation_date, creation_user and row_name
#   whose values are either "none" or one of the columns
#   also there may be a sequence name in seq_name
#Next, for each column in the list of columns, we are getting
#   ${column}_error_action and ${column}_form_type
#   ${column}_prompt_text, ${column}_extra_info
#   maybe also ${column}_ei_two and ${column}_ei_three
#  which may have values "none" or any of a number of options
set_the_usual_form_variables

# I want a list of all the variables I got so I can look at them
set list_all_vars {}
set form [ns_getform]
set form_size [ns_set size $form]
set form_counter_i 0
while {$form_counter_i<$form_size} {
    lappend list_all_vars [ns_set key $form $form_counter_i]
    incr form_counter_i
}
 
ReturnHeaders

ns_write "
[ad_header "Edit a $list_name_sing"]

<h2>Edit a $list_name_sing</h2>

<hr>

<form method=GET action=doctest.html>"

set selectlist [join $list_ord_cols ", "]
set db [ns_db gethandle]
set selection [ns_db 1row $db "select $selectlist from $table_name where $primary_key='[DoubleApos $key_for_object]'"]
set_variables_after_query
#now each column is set to its value in the database

ns_write "<table>\n"
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
  ns_write "[make_edit_form $column $form_type($column) $prompt_text($column) \
    $extra_info($column) $ei_two($column) $ei_three($column) [set $column] \
    $selection]"  
}
ns_write "</table>\n"

######################################################
# Now build the code for the edit page               #

set code_edit "#This file should be called ${base_file_name}-edit.tcl"
append code_edit "\n#Called from ${base_file_name}-list.tcl"
append code_edit "\n#The expected variables are "
append code_edit "key_for_object, the id of the row we wish to edit" "\n"
append code_edit "#Also user_id, the id of the current user.\n"

append code_edit {set_the_usual_form_variables}

append code_edit "\n\nReturnHeaders

ns_write &quot;
&#091;ad_header &quot;Edit a $list_name_sing&quot;&#093;

<h2>Edit a $list_name_sing</h2>

<hr>

<form method=GET action=${base_file_name}-edit-2.tcl>&quot;\n\n"

append code_edit "set db &#091;ns_db gethandle&#093;
set selection &#091;ns_db 1row &#036;db &quot;
    select $selectlist
    from $table_name 
    where $primary_key='&#091;DoubleApos &#036;key_for_object&#093;'&quot;&#093;
set_variables_after_query

#now we have the values from the database. Make the forms:

ns_write &quot;"
foreach column $list_ord_cols {
  append code_edit "[make_form_code $column $form_type($column)\
   $prompt_text($column) $extra_info($column) $ei_two($column)\
   $ei_three($column)]"  
}

#Finish up the page for the mycode_edit to be shown to the user
append code_edit "\n" {[export_form_vars user_id key_for_object]} "\n"

append code_edit "
<p>
<center>
<input type=submit value=\\&quot;Submit\\&quot;>
</center>
</form>
<p>\n"
append code_edit {[ad_footer]&quot;}



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

set code_edit_insert {#This is not done yet! Don't expect it to work!}
set code_edit_insert "#This file should be called ${base_file_name}-edit-2.tcl"
append code_edit_insert "\n#Target for ${base_file_name}-edit.tcl"
append code_edit_insert "\n#The expected variables are "
append code_edit_insert "[join $list_ord_cols ", "]\n"
append code_edit_insert "#and user_id, the id of the user found on add page\n"


if {[info exists seq_name]&&![empty_string_p $seq_name]} {
append code_edit_insert \
    "#And key_for_object, the key of the object we are editing\n"
}

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

    append code_edit_insert "if &#123;&#091;ns_conn form &#093; == "
    append code_edit_insert "&quot;&quot; &#125; &#123;\n"
    append code_edit_insert "    set $list_var &quot;&quot;\n"
    append code_edit_insert "&#125; else &#123;\n    "
    append code_edit_insert "set $list_var &#091;"
    append code_edit_insert "nmc_GetCheckboxValues &#091;ns_conn form"
    append code_edit_insert "&#093; $column&#093;\n" 
    append code_edit_insert "&#125;\n\n"    
}

#echo for code_edit_insert returned to user
append code_edit_insert {set_the_usual_form_variables}

foreach column $list_of_checks {
    append code_edit_insert\
     "\n\n#Now set the checkbutton variable $column to the proper values \n"
    append code_edit_insert "set $column &#036;$list_of($column)\n"
    append code_edit_insert \
        "set QQ$column &#091;DoubleApos &#036;$list_of($column)&#093;\n"
}

#Safeguard against errors caused by unselected radios or selects
if {$list_selectradio != {}} {
    append code_edit_insert\
    "\n\n#Radiobuttons and selects may give us trouble if none are selected"
    append code_edit_insert\
    "\n#The columns that might cause trouble are [join $list_selectradio ", "]"
}

foreach column $list_selectradio {
    append code_edit_insert "\nif !&#091;info exists $column&#093; &#123;\n"
    append code_edit_insert "    set $column &quot;&quot;\n"
    append code_edit_insert "    set QQ$column &quot;&quot;\n"
    append code_edit_insert "&#125;"
}

append code_edit_insert\
 "\n\n#Now check to see if the input is good as directed by the page designer"
append code_edit_insert "\n\n" {set error_flag 0} "\n"
append code_edit_insert {set error_message &quot;&quot;} 

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
        append code_edit_insert "if &#091;catch &#123; ns_dbformvalue &#091ns_conn form&#093; $column date $column &#125; errmsg&#093; &#123;
        incr error_flag
        append error_message &quot;<li>Please enter a valid date for the entry date&quot;
&#125;"
     } else {
     switch [set $action_var] {
     complain {
         #put error-checking information in returned code
         append code_edit_insert\
             "\n\n# we were directed to return an error for $column\n"
         append code_edit_insert  {if} " &#123;"
         append code_edit_insert {!&#091;info exists }
         append code_edit_insert "$column] ||"
         append code_edit_insert {&#091;empty_string_p &#036}
         append code_edit_insert \
             "[set column]]&#125; &#123;\n    incr error_flag\n"
         
         set error_var $column
         append error_var "_error_message"
        if {[info exists $error_var]&&![empty_string_p [set $error_var]]} {
         append code_edit_insert  "    append error_message"
         append code_edit_insert " &quot;"
         append code_edit_insert \
             "[philg_quote_double_quotes [set $error_var]]"
         append code_edit_insert "!<br>&quot;\n" "&#125; "
         } else {
         append code_edit_insert\
             "    append error_message &quot;You did not enter "
                 append code_edit_insert \
             "a value for $column!<br>&quot;\n&#125; "
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
            append code_edit_insert {!&#091;info exists }
            append code_edit_insert "$column&#093; ||"
            append code_edit_insert {&#091;empty_string_p $}
            append code_edit_insert "[set column]&#093;&#125; &#123;\n "
            append code_edit_insert "    set $column &quot;[set $error_var]"
            append code_edit_insert "&quot; \n     set QQ$column "
            append code_edit_insert {&#091;DoubleApos }
            append code_edit_insert "&quot;[set $error_var]&quot;] \n}" 
    } else {
    }
    }
        default {
    }
    }
}
}


#Finish the error-checking entry into code_edit_insert variable
append code_edit_insert "\n\nif" " {" {$error_flag } "> 0} " "{\n"
append code_edit_insert "    ad_return_complaint " {$error_flag $error_message} "\n"
append code_edit_insert "    return\n" "}\n"

append code_edit_insert "\n# So the input is good --"

append code_edit_insert "\n# Now we'll do the update of the $table_name table.\n"

append code_edit_insert {set db [ns_db gethandle]} "\n"

#append code_edit_insert {ns_db dml $db &quot;begin transaction&quot;}
#append code_edit_insert {ns_db dml $db}

#Now build my update statement
set the_sets {}

if {[string compare $creation_date "none"]} {
    lappend the_sets "$creation_date = sysdate"
}                 

if {[string compare $creation_user "none"]} {
    lappend the_sets "$creation_user = &#036;user_id"
}                 

foreach column $list_ord_cols { 
    ## Special date processing. This is terribly ugly, but can't be helped
    set form_var $column
    append form_var "_form_type"
    if ![string compare [set $form_var] "date"] {
    lappend the_sets "$column = to_date('&#036;$column','YYYY-MM-DD')"    
     } else {
    #a normal column; should be user submitted info in column var
     lappend the_sets "$column = '&#036;QQ$column'"
     }   
 }

set set_string [join $the_sets ", \n    "]

append code_edit_insert {if [catch } "{"
append code_edit_insert {ns_db dml $db}
append code_edit_insert " &quot;update $table_name 
      set $set_string
      where $primary_key = '&#036;key_for_object'&quot;"
append code_edit_insert " } errmsg] {\n"
append code_edit_insert "\n# Oracle choked on the update\n"

append code_edit_insert "    " {ad_return_error &quot;Error in update
&quot; &quot;We were unable to do your update in the database.
Here is the error that was returned:
<p>
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>&quot;
    return
&#125;      }

append code_edit_insert "\n\n"
#append code_edit_insert {ns_db dml $db &quot;end transaction&quot;}

append code_edit_insert {ad_returnredirect }
append code_edit_insert "${base_file_name}-edit.tcl?&#091;export_url_vars "
append code_edit_insert "key_for_object user_id&#093;"


# End of code generation for insert (add-2) page     #
######################################################

set mycode_edit [ns_quotehtml $code_edit]
set mycode_edit_insert [ns_quotehtml $code_edit_insert]

ns_write "
<p>
<center>
<input type=submit value=\"Submit\">
</center>
</form>

<p>

<hr>
<address>rfrankel@athena.mit.edu</address>
</body>
</html>
"

