# /www/bboard/admin-bozo-pattern.tcl
ad_page_contract {
    Displays infomation about one bozo pattern
    
    @param topic_id the ID of the topic to register the bozo pattern with
    @param topic the name of the bboard topic
    @param the_regexp a regular expression to filter on

    @cvs-id admin-bozo-pattern.tcl,v 3.2.2.4 2000/09/22 01:36:42 kevin Exp
} {
    topic_id:integer,notnull
    topic:notnull
    the_regexp:allhtml
}

# -----------------------------------------------------------------------------
 
if  {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
	return
}

# cookie checks out; user is authorized

if { ![db_0or1row maintainer_info "
select bt.*,u.email as maintainer_email, 
u.first_names || ' ' || u.last_name as maintainer_name, 
presentation_type
from bboard_topics bt, users u
where bt.topic_id=:topic_id
and bt.primary_maintainer_id = u.user_id"]} {
    [bboard_return_cannot_find_topic_page]
    return
}

db_1row bozo_pattern "
select bbp.*, first_names, last_name
from   bboard_bozo_patterns bbp, users
where  bbp.creation_user = users.user_id
and    topic_id = :topic_id
and    the_regexp = :the_regexp"


append page_content "
[ad_admin_header "Bozo Pattern in $topic:  $the_regexp"]

<h2>$the_regexp</h2>

a bozo pattern
for <a href=\"admin-home?[export_url_vars topic]\">$topic</a>

<hr>

<ul>
<li>Regular Expression:  \"$the_regexp\"
<li>Where we look:  $scope
<li>What we say to users who run afoul of this regexp:
<blockquote>
$message_to_user
</blockquote>
<li>Why this was created:
<blockquote>
$creation_comment
<br>
<br>
-- <a href=\"/shared/community-member?user_id=$creation_user\">$first_names $last_name</a>, [util_AnsiDatetoPrettyDate $creation_date]
</blockquote>

</ul>

If you don't like this bozo pattern, you can 

<ul>
<li><a href=\"admin-bozo-pattern-delete?[export_url_vars topic topic_id the_regexp]\">delete it</a>

<p>

<li><a href=\"admin-bozo-pattern-edit?[export_url_vars topic topic_id the_regexp]\">edit it</a>

</ul>

[bboard_footer]
"

doc_return  200 text/html $page_content
