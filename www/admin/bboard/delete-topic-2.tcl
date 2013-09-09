# /www/admin/bboard/delete-topic-2.tcl
ad_page_contract {
    Deletes the specified topic from the bboard system

    @param topic the name of the bboard topic to delete

    @cvs-id delete-topic-2.tcl,v 3.1.6.4 2000/09/22 01:34:21 kevin Exp
} {
    topic:notnull
}

# -----------------------------------------------------------------------------

set option_text "I guess you can return to the <a href=index>Hyper Administration page</a>"

if { [bboard_use_ns_perm_authorization_p] == 1 } {
    set ns_perm_group_added_for_this_forum [db_string group_perm "
    select ns_perm_group_added_for_this_forum from bboard_topics 
    where topic= :topic"]

    if { $ns_perm_group_added_for_this_forum != "" } {
	set option_text "The \"$ns_perm_group_added_for_this_forum\" AOLserver permissions group was created
when the $topic forum was created.  Unless you are using this permissions 
group for authenticating users in another forum or for static files, 
you probably want to
<a href=\"delete-ns-perm-group?group_name=[ns_urlencode $ns_perm_group_added_for_this_forum]\">delete the ns_perm group now</a>.

<p>

Alternatively, you can return to the <a href=index>Hyper Administration page</a>"
    }

}

# the order here is important because of the integrity constraint on
# the topic column of bboard 

db_transaction {
    db_dml bboard_delete "
    delete from bboard where topic= :topic"
    db_dml category_delete "
    delete from bboard_q_and_a_categories where topic= :topic"
    db_dml topic_delete "
    delete from bboard_topics where topic= :topic"
}

doc_return  200 text/html "<html>
<head>
<title>Deletion Accomplished</title>
</head>

<body bgcolor=#ffffff text=#000000>
<h2>Deletion Accomplished</h2>

of \"$topic\"

<hr>

$option_text

[ad_admin_footer]
</body>
</html>
"
