# $Id: delete-topic.tcl,v 3.0 2000/02/06 02:49:18 ron Exp $
set_form_variables_string_trim_DoubleAposQQ
set_form_variables

# topic

set db [bboard_db_gethandle]
if [catch {set selection [ns_db 0or1row $db "select unique * from bboard_topics where topic='$QQtopic'"]} errmsg] {
    [bboard_return_cannot_find_topic_page]
    return
}
# we found the data we needed
set_variables_after_query

set n_messages [database_to_tcl_string $db "select count(*) from bboard where topic='$QQtopic'"]

ns_return 200 text/html "<html>
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
<form method=post action=delete-topic-2.tcl>
<input type=hidden name=topic value=\"$topic\">

<input type=submit value=\"Yes, I am absolutely sure\">
</form>

[ad_admin_footer]
</body>
</html>
"
