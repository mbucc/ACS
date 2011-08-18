# $Id: admin-delete-category.tcl,v 3.0 2000/02/06 03:32:48 ron Exp $
set_form_variables_string_trim_DoubleAposQQ
set_form_variables

# topic, category, rowid

if { ![bboard_check_cookie $topic 1] } {
    ns_returnredirect "admin-challenge.tcl?[export_url_vars topic topic_id]"
    return
}

# cookie checks out; user is authorized

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}


set exception_text ""
set exception_count 0

if { [database_to_tcl_string $db "select count(*) from bboard where topic_id=$topic_id and category = '$QQcategory'"] != 0 } {
    append exception_text "<li>You can't delete categories with live threads!"
    incr exception_count
}


if { $exception_count> 0 } {
    if { $exception_count == 1 } {
	set problem_string "a problem"
	set please_correct "it"
    } else {
	set problem_string "some problems"
	set please_correct "them"
    }
    ns_return 200 text/html "[bboard_header "Problem Deleting Category"]

<h2>Problem Deleting Category</h2>

<hr>

We had $problem_string deleting $category:

<ul> 

$exception_text

</ul>

Please back up using your browser, correct $please_correct, 
and resubmit your form.

<p>

Thank you.

[bboard_footer]"

return 0

}

set sql "delete from bboard_q_and_a_categories where topic_id=$topic_id and rowid = '$QQrowid'"

if [catch {ns_db dml $db $sql} errmsg] {
    ns_return 500 text/html "[bboard_header "Category Not Deleted"]

<h2>Category Not Deleted</h2>

<hr>

The database rejected the deletion of (\"$topic\",\"$category\").  Here was
the error message:

<pre>
$errmsg
</pre>

[bboard_footer]"

return 0 

}

# the database operation went OK

ns_return 200 text/html "[bboard_header "$category Deleted"]

<h2>$category Deleted</h2>

from \"$topic\" in 
<a href=\"index.tcl\">[bboard_system_name]</a>

<hr>

If you've read <a href=\"http://photo.net/wtr/dead-trees/\">Philip
Greenspun's book on Web publishing</a> then you'll appreciate the SQL:

<blockquote><pre>
$sql
</pre></blockquote>

If you're just trying to get some work done, you'll probably want to 
<a href=\"admin-edit-categories.tcl?[export_url_vars topic topic_id]\">return to the edit categories page</a>.


[bboard_footer]"

