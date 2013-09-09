# /www/bboard/admin-q-and-a-category-list.tcl
ad_page_contract {
    A list of categories in a bboard topic

    @param topic the name of the bboard topic
    @param topic_id the ID of the bboard topic

    @cvs-id admin-q-and-a-category-list.tcl,v 3.1.6.3 2000/09/22 01:36:45 kevin Exp
} {
    topic
    topic_id:integer,notnull
}

# -----------------------------------------------------------------------------
 
if  {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
    return
}

append page_content "
[bboard_header "Question Categories"]

<h2>Question Categories</h2>

in the <a href=\"admin-q-and-a?[export_url_vars topic topic_id]\">$topic Q&A forum</a>

<hr>

<ul>

"

# may someday need "and category <> ''" 

db_foreach categories "
select category, 
       count(*) as n_threads
from   bboard 
where  refers_to is null
and    topic_id = :topic_id
and    category is not null
and    category <> 'Don''t Know'
group by category 
order by 1" {
    

    append page_cotnent "<li><a href=\"admin-q-and-a-one-category?[export_url_vars topic topic_id category]\">$category</a> ($n_threads)\n"
}

db_release_unused_handles

append page_content "
<p>
<li><a href=\"admin-q-and-a-one-category?[export_url_vars topic topic_id]&category=uncategorized\">Uncategorized</a>
</ul>

[bboard_footer]
"



doc_return  200 text/html $page_content