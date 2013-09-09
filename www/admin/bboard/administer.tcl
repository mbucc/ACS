# /www/admin/bboard/administer.tcl
ad_page_contract {
    The page to do high level administration for one bboard topic

    @param topic the name of the bboard topic
    @param topic_id the ID of the bboard topic

    @cvs-id administer.tcl,v 3.2.2.3 2000/09/22 01:34:21 kevin Exp
} {
    topic:optional
    topic_id:integer,optional
}

# -----------------------------------------------------------------------------

if { ![db_0or1row topic_info "
select bt.*,u.password as admin_password
from bboard_topics bt, users u
where bt.topic= :topic
and bt.primary_maintainer_id = u.user_id"]} {
    [bboard_return_cannot_find_topic_page]
    return
}

# we found the data we needed

append page_content "
[ad_admin_header "Hyper-Admin for $topic"]

<h2>Hyper-Administration for \"$topic\"</h2>

[ad_admin_context_bar [list "index.tcl" "BBoard Hyper-Administration"] "One Bboard"]

<hr>

This page is for unusual actions by the [bboard_system_name]
administrator, e.g., deleting entire discussion groups.  Ordinary
diurnal operations, such as deleting particular threads, should 
be handled from
<a href=\"/bboard/admin-home?topic=[ns_urlencode $topic]\">the regular $topic administration page</a>.

<p>

Here are the things that you can do to the $topic forum from here:

<ul>
<li><a href=\"topic-administrators?[export_url_vars topic topic_id]\">maintain administrators</a>

<p>

<li><a href=\"delete-all-messages?[export_url_vars topic topic_id]\">delete all messages</a> 

(clear out a forum so that it can be reused, e.g., good for a class
discussion system when a new semester starts)

</ul>

[ad_admin_footer]
"



doc_return  200 text/html $page_content
