# $Id: tableinfo-2.tcl,v 3.0 2000/02/06 03:27:30 ron Exp $
#It is slightly complicated which variables we expect from tableinfo
#First, we are getting (for sure) a list_of_cols and table_name
#Second, we are definitely getting list_name_plural and list_name_sing
#base_file_name and base_dir_name
#page_head back_phrase, back_link and back_text.
#Next, primary_key, creation_date, creation_user and row_name
#   whose values are either "none" or one of the columns
#   also there may be a sequence name in seq_name
#Next, for each column in the list of columns, we are getting
#   ${column}_error_action and ${column}_form_type
#  which may have values "none" or any of a number of options
set_the_usual_form_variables

#list_of_cols, table_name, list_name_plural, list_name_sing, base_file_name, base_dir_name, page_head, back_phrase, back_link, back_text, primary_key, creation_date, creation_user, row_name, ${column}_error_action, ${column}_form_type for each column in list_of_cols

ReturnHeaders

ns_write "
[ad_header \"Finish\"]

<h2>Finish Building the Page</h2>

<hr>

<form method=POST action=tableinfo-3.tcl>"

set html_uk [column_select $list_of_cols "unique_key"]
set html_vr [column_select $list_of_cols "visible_row"]
if {![string compare $primary_key "none"]||\
           ![string compare $row_name "none"]} {
       set list_for_select [concat "none" $list_of_cols]
       ns_write "<h3>We need some more information about the columns:</h3>"
       if {![string compare $primary_key "none"]} {
       ns_write "You did not identify an integer primary key.<br> We must have
       a column that uniqely identifies a row.<br> 
           (but it doesn't necessarily have to be an integer).<p> 
       Please enter an identifying column: &nbsp;$html_uk<p>"    
       }
       if {![string compare $row_name "none"]} {
       ns_write "You did not identify a column that contains the 
          name of the object.<br> We must have a column we will use to       
           list all the rows in the table.<p> 
     Please enter a column that can represent the rows: &nbsp;$html_vr<p>"
       }
}

ns_write "<h3>Refine the Information about each Column:</h3>"

# First we need to go through all our columns and separate
# them into three categories: the special ones, which get passed on
# the ones about which we need more information, and the ones we ignore
# The ones we need more info will be put in list_ord_cols.
# Also make an array of form_types for all the ordinary columns to
# be used later. Same for error_action.

set list_ord_cols {}
foreach column $list_of_cols {
    set special_list "$primary_key $creation_date $creation_user" 
    set index [check_special $column $special_list]
    if {$index == 0} {
    set form_var $column
    append form_var "_form_type"
        set form_type($column) [set $form_var]
    set error_var $column
    append error_var "_error_action"
        set error_action($column) [set $error_var]
    if [string compare [set $form_var] "none"] {
        lappend list_ord_cols $column
        ns_write "[export_form_vars $form_var $error_var]"
       }    
    } 
}

foreach column $list_ord_cols {
    ns_write "[solicit_info $column $form_type($column)]"
    ns_write "[solicit_error_info \
                 $column $error_action($column) $form_type($column)]"
 }

ns_write "
[export_form_vars list_of_cols list_ord_cols table_name user_id ]
[export_form_vars page_head back_phrase back_link back_text]
[export_form_vars row_name list_name_plural list_name_sing]
[export_form_vars primary_key creation_date creation_user seq_name]
[export_form_vars base_file_name base_dir_name]
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


