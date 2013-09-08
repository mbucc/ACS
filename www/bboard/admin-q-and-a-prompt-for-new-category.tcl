# /www/bboard/admin-q-and-a-prompt-for-new-category.tcl
ad_page_contract {
    adds a new category to go with a message

    @param msg_id the message the new category will be associated with

    @cvs-id admin-q-and-a-prompt-for-new-category.tcl,v 3.1.6.4 2000/09/22 01:36:45 kevin Exp
} {
    msg_id:notnull
}

# -----------------------------------------------------------------------------

if { ![db_0or1row msg_info "
select unique t.topic, 
       b.topic_id, 
       b.one_line 
from   bboard b, 
       bboard_topics t 
where  b.topic_id=t.topic_id 
and    b.msg_id = :msg_id"]} {

    # message was probably deleted
    doc_return  200 text/html "Couldn't find message $msg_id.  Probably it was deleted by the forum maintainer."
    return
}

ns_log Notice "--$topic_id $topic $msg_id"

if  {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
    return
}


append page_content "
[bboard_header "Add a new category"]

<h2>Add a new category</h2>

to the <a href=\"admin-home?[export_url_vars topic topic_id]\">$topic</a> forum

<p>
(for $one_line)

<hr>

<form target=admin_sub method=POST action=q-and-a-update-category>
<input type=hidden name=msg_id value=\"$msg_id\">
<input type=hidden name=new_category_p value=t>
New Category Name: <input type=text name=category size=20>
</form>

For reference, here are the existing categories:
<ul>
"

set categories [db_list categories "
select distinct category, upper(category) 
from bboard_q_and_a_categories 
where topic_id = :topic_id 
order by 2"]

foreach choice $categories {
    append page_content "<li>$choice\n"
}

append page_content "</ul>

[bboard_footer]"


doc_return 200 text/html $page_content

