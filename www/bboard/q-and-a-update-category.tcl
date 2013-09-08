# /www/bboard/q-and-a-update-category.tcl
ad_page_contract {
    Change the category for a posting

    @param msg_id the ID for the message
    @param category the category to put it in
    @param new_category_p is this a new category?

    @cvs-id q-and-a-update-category.tcl,v 3.1.6.5 2000/09/22 01:36:53 kevin Exp
} {
    msg_id:notnull
    category:notnull
    new_category_p:optional
}

# -----------------------------------------------------------------------------

db_1row topic_for_msg "select unique topic_id from bboard where msg_id = :msg_id"


if  {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
    return
}



# cookie checks out; user is authorized

if { $category == "Define New Category" } {
    ad_returnredirect "admin-q-and-a-prompt-for-new-category.tcl?msg_id=$msg_id"
    return 
}

if { [info exists new_category_p] && $new_category_p == "t" } {
    if [catch {db_dml category_insert "
    insert into bboard_q_and_a_categories 
    (topic_id, category) 
    values 
    (:topic_id,:category)"} errmsg] {
	# something went wrong
	doc_return  200 text/html "
[bboard_header "New Category Not Updated"]

<h2>New Category Not Updated</h2>

<hr>

The database rejected the addition of the new category \"$category\".
Here was the error message:

<pre>
$errmsg
</pre>

If you see \"integrity constraint\" somewhere in the message, it
probably means that topic_id $topic already has a category called \"$category\"
and you did not need to add it.

[bboard_footer]"
    return
}
}

# if we got here, it means the new category was added successfully
# and/or there was no need to add a category

if [catch {db_dml update_category "
update bboard set category = :category where msg_id = :msg_id "} errmsg] {
    # something went wrong
    doc_return 500 text/html "
[bboard_header "Update Failed"]

<h2>Update Failed</h2>

<hr>

The database rejected the categorization of msg $msg_id.
Here was the error message:

<pre>
$errmsg
</pre>

This is probably some kind of bug in this software.

[bboard_footer]"
       return
}
# if we got here, it means that we did everything right


doc_return 200 text/html "
[bboard_header "Done"]

<h2>Done</h2>

<hr>

Message $msg_id categorized.

[bboard_footer]"

