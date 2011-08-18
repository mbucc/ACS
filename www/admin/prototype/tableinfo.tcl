# $Id: tableinfo.tcl,v 3.0 2000/02/06 03:27:34 ron Exp $
# comes from index.tcl
set_the_usual_form_variables

#table_name, Table, base_file_name, base_dir_name 

set db [ns_db gethandle]
# verify entry (is this bad? AOL server docs warn against "table exists"
# in any case, check first that any input at all has been given.
# also, if no input in the text entry, look for entry in the select box
set error_flag 0
set error_message ""

if [empty_string_p $table_name] {
 if ![info exists Table] {
     incr error_flag
     set error_message "You did not enter a table name"
 } else {
     set table_name $Table
 }
} 

if {![info exists base_file_name]||[empty_string_p $base_file_name]} {
     incr error_flag
     set error_message "You did not enter a filename"
} 

if {$error_flag>0} {
    ad_return_complaint $error_flag $error_message
    return
}

if ![ns_table exists $db $table_name] {
    incr error_flag
 set error_message "The table named $table_name does not exist in the database"
}

if {$error_flag>0} {
    ad_return_complaint $error_flag $error_message
    return
}

# Find a list of the names of the columns
set num_cols [ns_column count $db $table_name]
set counter 0
set list_of_cols {}
set list_of_types {}
while {$counter <  $num_cols} {
    set col_name [ns_column name $db $table_name  $counter ]
    set col_type  [ns_column typebyindex $db $table_name  $counter]
    lappend list_of_cols $col_name
    lappend list_of_types $col_type
    incr counter
}

set var_list [join $list_of_cols]
set html_pk [column_select $list_of_cols \"primary_key\"]
set html_na [column_select $list_of_cols \"row_name\"]
set html_cu [column_select $list_of_cols \"creation_user\"]
set html_cd [column_select $list_of_cols \"creation_date\"]

ReturnHeaders

ns_write "
[ad_header "Specify Information About the Desired Pages"]

<h2>Build A Page (first of two pages)</h2>

<hr>
<form method=POST action=\"tableinfo-2.tcl\">
<h2>Specify Information About the Desired  Page:</h2>
<h3>General Information:</h3>

Do you want to specify a title for your main page?<br>
<input type=text size=55 name=page_head><p>

Please fill in these phrases for the list page:<br>
All the <input type=text size=30 name=list_name_plural>:
<ul><li>Add a <input type=text size=30 name=list_name_sing>.<br></ul>

Please fill in element for the Yahoo-style navbar:

<P><B>Your workspace</B>: <input type=hidden name=back_phrase SIZE=15 value=\"\">
&lt;a href=&quot;<input type=text size=15 name=back_link value=\"${base_file_name}-list.tcl\">&quot;&gt;<input type=text size=20 name=back_text>&lt;/a&gt;

<h3>Pick Special Columns:</h3>

Is one of your columns a integer primary key? $html_pk
<ul><li>If so, is there an associated sequence name? 
<input type=text size=30 name=seq_name></ul>
<p>

Does one of your columns specify a pretty name for this row? $html_na
<p>

Does one of your columns specify a creation date of this row? $html_cd
<p>

Does one of your columns specify the user who created this row? $html_cu
<p>

<h3>Specify Data About Column Entry Forms:</h3>
What kind of form do you want to use to input into each column?
<p>
<table cellpadding=5 cellspacing=2>
<tr><td align=center colspan=1><b>Column</b></td><td align=center colspan = 8><b>Type of Form</b></tr>"

foreach column $list_of_cols {
  set column_html [column_form $column]   
  ns_write "$column_html"
  }

ns_write "
</table>

<h3>Specify Data about Error Messages</h3>
What should be done if the user fails to input any data?

<p>
<table cellpadding=3>
<tr><td align=center colspan=1><b>Column</b></td><td align=center colspan = 3><b>Action to take upon failing to recieve form data.</b></tr>"

foreach column $list_of_cols {
  set column_html [column_form_error $column]   
  ns_write "$column_html"
  }

ns_write "
</table>

[export_form_vars list_of_cols table_name base_dir_name base_file_name]

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


#   set prompt_var $column
#   append prompt_var "_prompt_text"
#   append select_html ""
#   append select_html ""
#   append select_html ""

#Do you want to specify a title for your list page?<br>
#<input type=text size=70 name=page_head_list><p>

#Do you want to specify a title for your add page?<br>
#<input type=text size=70 name=page_head_add><p>

#Do you want to specify a title for your edit page?<br>
#<input type=text size=70 name=page_head_edit><p>
