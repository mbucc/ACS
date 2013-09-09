# /www/admin/admin-update-topics-table.tcl
ad_page_contract {

    @cvs-id admin-update-topics-table.tcl,v 3.3.2.5 2000/09/22 01:36:46 kevin Exp
} {
    topic
    topic_id:notnull,integer
}

# -----------------------------------------------------------------------------

if {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
    return
}

db_1row maintainer_info "
select  u.email as maintainer_email, 
        u.first_names || ' ' || u.last_name as maintainer_name
from    bboard_topics t, users u
where   topic_id = :topic_id
and     t.primary_maintainer_id = u.user_id"

# cookie checks out; user is authorized

# we have to treat the textarea stuff specially (some browsers give us a blank line or two)

# This should be done away with, but it's just to horrible to deal
# with

set sql_and_bind_vars [util_prepare_update bboard_topics "topic_id" $topic_id [ns_conn form]]
set sql [lindex $sql_and_bind_vars 0]
set bind_vars [lindex $sql_and_bind_vars 1]

if [catch {db_dml topic_update $sql -bind $bind_vars} errmsg] {
    doc_return  200 text/html "<html>
<head>
<title>Topic Not Updated</title>
</head>

<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>
<h2>Topic Not Updated</h2>

<hr>

The database rejected the update of discussion topic \"$topic\".  Here was
the error message:

<pre>
$errmsg
</pre>

[bboard_footer]"
return 0 

}

# the database insert went OK

db_1row topic_info "
select unique topic from bboard_topics where topic_id = :topic_id"

doc_return 200 text/html "
[bboard_header "Topic Updated"]

<h2>Topic Updated</h2>

\"$topic\" updated in 
<a href=\"index\">[bboard_system_name]</a>

<hr>

If you've read <a href=\"http://photo.net/wtr/dead-trees/\">Philip
Greenspun's book on Web publishing</a> then you'll appreciate the SQL:

<blockquote><pre>
$sql
</pre></blockquote>

<p>

Remember to link to <a href=\"q-and-a?[export_url_vars topic topic_id]\">the user Q&A page</a> from your public pages and bookmark
<a href=\"admin-home?[export_url_vars topic topic_id]\">the
admin page</a> after you return there.

[bboard_footer]"
