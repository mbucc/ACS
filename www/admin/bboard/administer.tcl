# $Id: administer.tcl,v 3.0 2000/02/06 02:49:17 ron Exp $
set_the_usual_form_variables

# topic, topic_id

set db [bboard_db_gethandle]
if [catch {set selection [ns_db 0or1row $db "select bt.*,u.password as admin_password
from bboard_topics bt, users u
where bt.topic='$QQtopic'
and bt.primary_maintainer_id = u.user_id"]} errmsg] {
    [bboard_return_cannot_find_topic_page]
    return
}
# we found the data we needed
set_variables_after_query

ReturnHeaders

ns_write "[ad_admin_header "Hyper-Admin for $topic"]

<h2>Hyper-Administration for \"$topic\"</h2>

[ad_admin_context_bar [list "index.tcl" "BBoard Hyper-Administration"] "One Bboard"]


<hr>

This page is for unusual actions by the [bboard_system_name]
administrator, e.g., deleting entire discussion groups.  Ordinary
diurnal operations, such as deleting particular threads, should 
be handled from
<a href=\"/bboard/admin-home.tcl?topic=[ns_urlencode $topic]\">the regular $topic administration page</a>.

<p>

Here are the things that you can do to the $topic forum from here:

<ul>
<li><a href=\"topic-administrators.tcl?[export_url_vars topic topic_id]\">maintain administrators</a>

<p>

<li><a href=\"delete-all-messages.tcl?[export_url_vars topic topic_id]\">delete all messages</a> 

(clear out a forum so that it can be reused, e.g., good for a class
discussion system when a new semester starts)


</ul>

[ad_admin_footer]
"
