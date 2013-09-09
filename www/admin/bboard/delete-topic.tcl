# /www/admin/bboard/delete-topic.tcl
ad_page_contract {
    Deletes a topic area from the bboard system
    
    @param topic the name of the bboard topic

    @cvs-id delete-topic.tcl,v 3.1.6.4 2000/09/22 01:34:22 kevin Exp
} {
    topic:notnull
}

# -----------------------------------------------------------------------------

if { ![db_0or1row bboard_topic_info "
select unique * from bboard_topics where topic= :topic"]} {
    [bboard_return_cannot_find_topic_page]
    return
}

# we found the data we needed

set n_messages [db_string n_messages "
select count(*) from bboard where topic= :topic"]

doc_return  200 text/html "<html>
<head>
<title>Confirm</title>
</head>

<body bgcolor=#ffffff text=#000000>
<h2>Confirm</h2>

deletion of \"$topic\"

<hr>

Are you absolutely sure that you want to remove \"$topic\" and
its $n_messages postings from the [bboard_system_name] system?

<p>
<form method=post action=delete-topic-2>
<input type=hidden name=topic value=\"$topic\">

<input type=submit value=\"Yes, I am absolutely sure\">
</form>

[ad_admin_footer]
</body>
</html>
"
