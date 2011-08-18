# $Id: search-subject.tcl,v 3.0 2000/02/06 03:34:37 ron Exp $
set_form_variables
set_form_variables_string_trim_DoubleAposQQ

# query_string, topic

if { ![info exists query_string] || $query_string == "" } {
    # probably using MSIE
    ns_return 200 text/html "[bboard_header "Missing Query"]

<h2>Missing Query</h2>

<hr>

Either you didn't type a query string or you're using a quality Web
browser like Microsoft Internet Explorer 3.x (which neglects to 
pass user input up the server).

[bboard_footer]
"
    return
}

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}


if {[bboard_get_topic_info] == -1} {
    return
}



# we ask for all the top level messages

ReturnHeaders

ns_write "<html>
<head>
<title>Search Results</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

<b>Messages matching \"$query_string\"</b>

<pre>
"

regsub -all {,+} [string trim $QQquery_string] " " final_query_string

if [catch {set selection [ns_db select $db "select /*+ INDEX(bboard bboard_for_one_category) */ bboard_contains(email, first_names || last_name, one_line, message,'$final_query_string') as the_score, bboard.*
from bboard, users
where bboard_contains(email, first_names || last_name, one_line, message,'$final_query_string') > 0
and bboard.user_id = users.user_id
and topic_id = $topic_id
order by 1 desc"]} errmsg] {

    ns_write "There aren't any results because something about
your query string has made Oracle Context unhappy:

$errmsg

In general, ConText does not like special characters.  It does not like
to see common words such as \"AND\" or \"a\" or \"the\".  
I haven't completely figured this beast out.

Back up and try again!

</pre>
[bboard_footer]"
    return

}

set counter 0

while {[ns_db getrow $db $selection]} {
    incr counter

    set_variables_after_query
    if { [string first "." $sort_key] == -1 } {
	# there is no period in the sort key so this is the start of a thread
	set thread_start_msg_id $sort_key
    } else {
	# strip off the stuff before the period
	regexp {(.*)\..*} $sort_key match thread_start_msg_id
    }
    ns_write "<a target=main href=\"fetch-msg.tcl?msg_id=$msg_id\">$one_line</a> <a target=\"_top\" href=\"main-frame.tcl?[export_url_vars topic topic_id]&feature_msg_id=$msg_id&start_msg_id=$thread_start_msg_id\">(view entire thread)</a>\n"
}

ns_write "
</pre>
</body>
</html>
"
