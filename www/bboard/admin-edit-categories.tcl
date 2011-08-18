# $Id: admin-edit-categories.tcl,v 3.0 2000/02/06 03:32:49 ron Exp $
set_form_variables_string_trim_DoubleAposQQ
set_form_variables

# topic, topic_id


set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}
 
if  {[bboard_get_topic_info] == -1} {
    return}

if {[bboard_admin_authorization] == -1} {
	return}




# cookie checks out; user is authorized


if [catch {set selection [ns_db 0or1row $db "select unique * from bboard_topics where topic_id=$topic_id"]} errmsg] {
    [bboard_return_cannot_find_topic_page]
    return
}
# we found the data we needed
set_variables_after_query

ReturnHeaders

ns_write "[bboard_header "Edit categories for $topic"]

<h2>Edit Categories for \"$topic\"</h2>

<ul>
"

set selection [ns_db select $db "select cats.rowid, cats.category, sum(decode(b.category,NULL,0,1)) as n_threads
from bboard_q_and_a_categories cats, bboard b
where cats.topic_id=$topic_id
and cats.category = b.category(+)
and cats.topic_id = b.topic_id(+)
and b.refers_to is null
and (b.topic_id is null or b.topic_id = $topic_id)
group by cats.rowid, cats.category
order by cats.category"]

set counter 0
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr counter
    if { $n_threads == 0 } {
	ns_write "<li>$category ($n_threads threads) 
  <a href=\"admin-delete-category.tcl?[export_url_vars topic topic_id category rowid]\">delete</a>\n"
    } else {
	ns_write "<li>$category ($n_threads threads)\n"
    }
}

if { $counter == 0 } {
    ns_write "no categories defined"
}

ns_write "

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
