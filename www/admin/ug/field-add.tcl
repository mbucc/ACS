# $Id: field-add.tcl,v 3.0 2000/02/06 03:28:36 ron Exp $
set_the_usual_form_variables

# group_type, after (optional)

set db [ns_db gethandle]

set selection [ns_db 1row $db "select * 
from user_group_types 
where group_type = '$QQgroup_type'"]

set_variables_after_query

ReturnHeaders 

ns_write "[ad_admin_header "Add a field to $pretty_name"]

<h2>Add a field</h2>

to the <a href=\"group-type.tcl?[export_url_vars group_type]\">$pretty_name</a> group type

<hr>

<form action=\"field-add-2.tcl\" method=POST>
[export_form_vars group_type after]

Column Actual Name:  <input name=column_name type=text size=30>
<br>
<i>no spaces or special characters except underscore</i>

<p>

Column Pretty Name:  <input name=pretty_name type=text size=30>

<p>


Column Type:  [ad_user_group_column_type_widget]
<p>

Column Actual Type:  <input name=column_actual_type type=text size=30>
(used to feed Oracle, e.g., <code>char(1)</code> instead of boolean)


<p>

If you're a database wizard, you might want to add some 
extra SQL, such as \"not null\"<br>
Extra SQL: <input type=text size=30 name=column_extra>

<p>

(note that you can only truly add not null columns when the table is
empty, i.e., before anyone has entered the contest)

<p>

<input type=submit value=\"Add this new column\">

</form>

[ad_admin_footer]
"
