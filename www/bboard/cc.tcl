# $Id: cc.tcl,v 3.0 2000/02/06 03:33:21 ron Exp $
set_form_variables_string_trim_DoubleAposQQ
set_form_variables

# topic, topic_id, key (category)

set category $key
set QQcategory $QQkey

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}


if [catch {set selection [ns_db 1row $db "select unique * from bboard_topics where topic_id = $topic_id"]} errmsg] {
    bboard_return_cannot_find_topic_page
    return
}
# we found subject_line_suffix at least 
set_variables_after_query

ReturnHeaders

ns_write "<html>
<head>
<title>$category threads in $topic</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

<h2>$category Threads</h2>

in the <a href=\"q-and-a.tcl?[export_url_vars topic topic_id]\">$topic question and answer forum</a>

<hr>


"

if { $category != "uncategorized" } {
    set category_clause "and category = '$QQcategory'"
} else {
    # **** NULL/'' problem, needs " or category = '' "
    set category_clause "and (category is NULL or category = 'Don''t Know')"
}


set sql "select msg_id, one_line, sort_key, email, first_names || ' ' || last_name as name, bboard_uninteresting_p(interest_level) as uninteresting_p
from bboard, users
where topic_id = $topic_id
$category_clause
and refers_to is null
and users.user_id = bboard.user_id
order by uninteresting_p, sort_key $q_and_a_sort_order"

set selection [ns_db select $db $sql]

ns_write "<ul>\n"

set uninteresting_header_written 0
set counter 0
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr counter
    if { $uninteresting_p == "t" && $uninteresting_header_written == 0 } {
	set uninteresting_header_written 1
	ns_write "</ul>
<h3>Uninteresting Threads</h3>

(or at least the forum moderator thought they would only be of interest to rare individuals; truly worthless threads get deleted altogether)
<ul>
"
    }
    set display_string "$one_line"
    if { $subject_line_suffix == "name" && $name != "" } {
	append display_string "  ($name)"
    } elseif { $subject_line_suffix == "email" && $email != "" } {
	append display_string "  ($email)"
    }
    ns_write "<li><a href=\"q-and-a-fetch-msg.tcl?msg_id=$msg_id\">$display_string</a>\n"

}

ns_write "

</ul>

"

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

if { $counter == 0 } {
    ns_write "There hasn't been any discussion yet.

<h3>You can be the one to start the discussion</h3> 

(of $key)

" } else {

    ns_write "<h3>You can ask a new question</h3>

(about $key)

"
}

ns_write "<p>

<form method=post action=\"insert-msg.tcl\" target=\"_top\">

<input type=hidden name=q_and_a_p value=\"t\">
<input type=hidden name=category value=\"[philg_quote_double_quotes $key]\">
[export_form_vars topic topic_id]
<input type=hidden name=refers_to value=NEW>

<table>

<tr><th>Your Email Address<td><input type=text name=email size=30 value=\"$default_email\"></tr>

<tr><th>Your Full Name<td><input type=text name=name size=30 value=\"$default_name\"></tr>

<tr><th>Subject Line<br>(summary of question)<td><input type=text name=one_line size=50></tr>

<tr><th>Notify Me of Responses<br>(via email)
<td><input type=radio name=notify value=t CHECKED> Yes
<input type=radio name=notify value=f> No

<tr><th>Message<br>(full question)<td>enter in box below, then press submit
</tr>

</table>



<textarea name=message rows=10 cols=70 wrap=hard></textarea>

<P>

<center>


<input type=submit value=Submit>

</center>

</form>
"



ns_write "

[bboard_footer]
"

# *** here we want an [ns_conn close] but it didn't make 2.2b2

# let's see if we need to put this into the categories table

if { $counter == 0 && [database_to_tcl_string $db "select count(*) from bboard_q_and_a_categories where topic_id = $topic_id and category = '$QQkey'"] == 0 } {
    # catch to trap the primary key complaint from Oracle
    catch { ns_db dml $db "insert into bboard_q_and_a_categories (topic_id, category)
values
($topic_id,'$QQkey')" }
}
