# /www/bboard/admin-edit-categories.tcl
ad_page_contract {
    Form to edit categories

    @param topic the name of the bboard topic
    @param topic_id the ID of the bboard topic
    
    @cvs-id admin-edit-categories.tcl,v 3.2.2.3 2000/09/22 01:36:43 kevin Exp
} {
    topic
    topic_id:notnull,integer
}

# -----------------------------------------------------------------------------
 
if  {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
    return
}

# cookie checks out; user is authorized

if { ![db_0or1row topic_info "
select unique * from bboard_topics 
where topic_id = :topic_id"]} {
    [bboard_return_cannot_find_topic_page]
    return
}


append page_content "[bboard_header "Edit categories for $topic"]

<h2>Edit Categories for \"$topic\"</h2>

<ul>
"

db_foreach cat_info "
select cats.rowid, 
       cats.category, 
       sum(decode(b.category,NULL,0,1)) as n_threads
from   bboard_q_and_a_categories cats, bboard b
where  cats.topic_id=:topic_id
and    cats.category = b.category(+)
and    cats.topic_id = b.topic_id(+)
and    b.refers_to is null
and    (b.topic_id is null or b.topic_id = :topic_id)
group by cats.rowid, cats.category
order by cats.category" {

    if { $n_threads == 0 } {
	append page_content "<li>$category ($n_threads threads) 
  <a href=\"admin-delete-category?[export_url_vars topic topic_id category rowid]\">delete</a>\n"
    } else {
	append page_content "<li>$category ($n_threads threads)\n"
    }

} if_no_rows {

    append page_content "no categories defined"
}

append page_content "

</ul>

Note: Categories with 1 or more threads are presented on the top level
Q&A page.  Categories with 0 threads are presented to users posting
new questions (if you've enabled solicitation of categories from
users).  They are presented on the top level page only for
category-centric bboards.

<p>

Right now, I think I'm only going to let you delete categories with
zero threads.  If you want to kill off a category, please delete or
recategorize the threads that are underneath it.  Someday when I'm
feeling smarter, I'll add an option to rename a category and all the
threads underneath.

[bboard_footer]"

doc_return  200 text/html $page_content