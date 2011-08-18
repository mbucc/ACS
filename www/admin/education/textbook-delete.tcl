#
# /www/admin/education/textbook-delete.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page allows admin to select books to delete from the system.
#

ad_page_variables {
    textbook_id
}

set db [ns_db gethandle]

set selection [ns_db select $db "select m.class_id, c.class_name 
from edu_classes c, edu_classes_to_textbooks_map m
where m.textbook_id = $textbook_id
and m.class_id = c.class_id"] 

set return_string "
[ad_header "Textbooks @ [ad_system_name]"]

<h2>Confirm Textbook Deletion</h2>

[ad_context_bar_ws [list "/admin/" "Admin Home"] [list "" "[ad_system_name] Administration"] [list "textbook.tcl?textbook_id=$textbook_id" "Textbook Information"] Delete]

<hr>
<blockquote>
<font color=red><b>Warning!</b></font> Deleting this textbook will affect all classes
that are currently using it: 
<ul>"

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append return_string "
    <li>$class_name"
}

append return_string "
</ul>
<p>Do you wish to continue?</p>

<form method=post action=\"textbook-delete-2.tcl\">

[export_form_vars textbook_id]

<input type=submit value=Confirm>

</form>
</blockquote>
[ad_admin_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string












