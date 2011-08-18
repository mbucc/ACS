# $Id: delete-topic-2.tcl,v 3.0 2000/02/06 02:49:17 ron Exp $
set_form_variables_string_trim_DoubleAposQQ
set_form_variables

# topic

set db [bboard_db_gethandle]

set option_text "I guess you can return to the <a href=index.tcl>Hyper Administration page</a>"

if { [bboard_use_ns_perm_authorization_p] == 1 } {
    set ns_perm_group_added_for_this_forum [database_to_tcl_string $db "select ns_perm_group_added_for_this_forum from bboard_topics where topic='$QQtopic'"]
    if { $ns_perm_group_added_for_this_forum != "" } {
	set option_text "The \"$ns_perm_group_added_for_this_forum\" AOLserver permissions group was created
when the $topic forum was created.  Unless you are using this permissions 
group for authenticating users in another forum or for static files, 
you probably want to
<a href=\"delete-ns-perm-group.tcl?group_name=[ns_urlencode $ns_perm_group_added_for_this_forum]\">delete the ns_perm group now</a>.

<p>

Alternatively, you can return to the <a href=index.tcl>Hyper Administration page</a>"
    }

}

# the order here is important because of the integrity constraint on
# the topic column of bboard 

ns_db dml $db "delete from bboard where topic='$QQtopic'"
ns_db dml $db "delete from bboard_q_and_a_categories where topic='$QQtopic'"
ns_db dml $db "delete from bboard_topics where topic='$QQtopic'"

ns_return 200 text/html "<html>
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
