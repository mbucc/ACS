# $Id: custom-q-and-a-fetch.tcl,v 3.0 2000/02/06 03:33:43 ron Exp $
set_the_usual_form_variables

# key, topic, topic_id

# custom_sort_key is defined to be unique

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}

set selection [ns_db 0or1row $db "select to_char(posting_time,'Month dd, yyyy') as posting_date,bboard.*, users.user_id as poster_id,  users.first_names || ' ' || users.last_name as name
from bboard, users
where bboard.user_id = users.user_id
and msg_id = '$msg_id'"]

if { $selection == "" } {
    # *** this needs to be patched to look at ad_get_user_id
    # there ain't no message like this
    if [catch {set selection [ns_db 1row $db "select unique * from bboard_topics where topic_id=$topic_id"]} errmsg] {
	bboard_return_cannot_find_topic_page
	return
    }
    set_variables_after_query
    set headers [ns_conn headers]
    if { $headers == "" || ![regexp {LusenetEmail=([^;]*).*$} [ns_set get $headers Cookie] {} LusenetEmail] } {
	set default_email ""
    } else {
	set default_email $LusenetEmail 
    }
    if { $headers == "" || ![regexp {LusenetName=([^;]*).*$} [ns_set get $headers Cookie] {} LusenetName] } {
	set default_name ""
    } else {
	set default_name $LusenetName
    }

    ReturnHeaders
    ns_write "[bboard_header "No Discussion Yet"]

<h2>No Discussion Yet</h2>

of $key in the <a href=\"q-and-a.tcl?[export_url_vars topic topic_id]\">$topic Q&A Forum</a>

<hr>

$custom_sort_not_found_text

<hr width=300>

<h3>You can be the one to start the discussion</h3> 

<form method=post action=\"insert-msg.tcl\" target=\"_top\">

<input type=hidden name=q_and_a_p value=\"t\">
<input type=hidden name=custom_sort_key value=\"[philg_quote_double_quotes $key]\">
<input type=hidden name=topic value=\"$topic\">
<input type=hidden name=topic_id value=\"$topic_id\">
<input type=hidden name=refers_to value=NEW>

<table>

<tr><th>Your Email Address<td><input type=text name=email size=30 value=\"$default_email\"></tr>

<tr><th>Your Full Name<td><input type=text name=name size=30 value=\"$default_name\"></tr>

<tr><th>Subject Line<br>(summary of question)<td><input type=text name=one_line size=50></tr>

"

# think about writing a category SELECT 

    if { $q_and_a_categorized_p == "t" && $q_and_a_solicit_category_p == "t" } {
	set categories [database_to_tcl_list $db "select distinct category, upper(category) from bboard_q_and_a_categories where topic_id = $topic_id order by 2"]
	set html_select "<select name=category>
<option value=\"\" SELECTED>Don't Know</a>
"
        append html_select "<option>" [join $categories "<option>\n"]
        append html_select "</select>"
        ns_write "<tr><th>Category<td>\n$html_select\n(this helps build the FAQ archives)</tr>\n"
}

ns_write "

<tr><th>Notify Me of Responses<br>(via email)
<td><input type=radio name=notify value=t CHECKED> Yes
<input type=radio name=notify value=f> No

<tr><th>Message<br>(full question)<td>enter in textarea below, then press submit
</tr>

</table>



<textarea name=message rows=10 cols=70 wrap=physical></textarea>

<P>

<center>


<input type=submit value=Submit>

</center>

</form>


<hr>

<address><a href=\"mailto:$maintainer_email\">$maintainer_email</a></address>

</body>
</html>
"
    return
}

set_variables_after_query
set this_msg_id $msg_id
set this_one_line $one_line

# now variables like $message and $topic are defined

if [catch {set selection [ns_db 1row $db "select unique * from bboard_topics where topic=$topic_id"]} errmsg] {
    bboard_return_cannot_find_topic_page
    return
}
set_variables_after_query


set contributed_by "Asked by $name (<a href=\"mailto:$email\">$email</a>) on [util_IllustraDatetoPrettyDate $posting_date]."

ReturnHeaders

ns_write "<html>
<head>
<title>$one_line</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

<h3>$one_line</h3>

asked in the <a href=\"q-and-a.tcl?[export_url_vars topic topic_id]\">$topic Q&A Forum</a>

<hr>

<blockquote>
$message
</blockquote>

$contributed_by
"


set selection [ns_db select $db "select decode(email,'$maintainer_email','f','t') as not_maintainer_p, to_char(posting_time,'YYYY-MM-DD') as posting_date,bboard.* 
from bboard
where sort_key like '$msg_id%'
and msg_id <> '$msg_id'
order by not_maintainer_p, sort_key"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    if { $email == "" } {
	set contributed_by "anonymously answered on [util_IllustraDatetoPrettyDate $posting_date]."
    } else {
	set contributed_by "Answered by $name (<a href=\"mailto:$email\">$email</a>) on [util_IllustraDatetoPrettyDate $posting_date]."
}
    set this_response ""
    if { $one_line != $this_one_line && $one_line != "Response to $this_one_line" } {
	# new subject
	append this_response "<h4>$one_line</h4>\n"
    }
    append this_response "<blockquote>
$message
</blockquote>
$contributed_by"
    lappend responses $this_response
}

if { [info exists responses] } {
    # there were some
    ns_write "<h3>Answers</h3>
[join $responses "<hr width=300>"]
"
}
    

ns_write "

<hr>
<a href=\"q-and-a-post-reply-form.tcl?refers_to=$this_msg_id\">Contribute an answer to \"$this_one_line\"</a>

[bboard_footer]
"

