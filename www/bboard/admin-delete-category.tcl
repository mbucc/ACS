# /www/bboard/admin-delete-category.tcl
ad_page_contract {
    Deletes a category from a bbaord topic

    @param topic_id the ID for the bboard topic
    @param category the name of the category
    @param rowid the Oracle rowid for the category

    @cvs-id admin-delete-category.tcl,v 3.3.2.5 2000/09/22 01:36:43 kevin Exp
} {
    topic_id:integer,notnull
    category:notnull
    rowid:notnull
}

# -----------------------------------------------------------------------------

if {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
    return
}


# cookie checks out; user is authorized

page_validation {
    if { [db_string live_threads "
    select count(*) 
    from   bboard 
    where  topic_id = :topic_id 
    and    category = :category"] != 0 } {
	error "You can't delete categories with live threads!"
    }    
}

# rowid is a reserved word

set row_id $rowid

set sql "
delete from bboard_q_and_a_categories 
where topic_id = :topic_id and rowid = :row_id"

if [catch {db_dml category_delete $sql} errmsg] {
    ad_return_error "Category Not Deleted" "

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



doc_return  200 text/html "[bboard_header "$category Deleted"]

<h2>$category Deleted</h2>

from \"$topic\" in 
<a href=\"index\">[bboard_system_name]</a>

<hr>

If you've read <a href=\"http://photo.net/wtr/dead-trees/\">Philip
Greenspun's book on Web publishing</a> then you'll appreciate the SQL:

<blockquote><pre>
$sql
</pre></blockquote>

If you're just trying to get some work done, you'll probably want to 
<a href=\"admin-edit-categories?[export_url_vars topic topic_id]\">return to the edit categories page</a>.

[bboard_footer]"






