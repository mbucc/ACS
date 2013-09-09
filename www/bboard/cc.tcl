# /www/bboard/cc.tcl
ad_page_contract {
    Displays threads for one category

    @param topic the name of the bboard topic
    @param topic_id the ID of the bboard topic
    @param key a bboard category

    @cvs-id cc.tcl,v 3.1.6.5 2000/09/22 01:36:48 kevin Exp
} {
    topic:notnull
    topic_id:notnull,integer
    key
}

# -----------------------------------------------------------------------------

set category $key

if {![db_0or1row bboard_topics "
select unique * from bboard_topics where topic_id = :topic_id"]} {
    bboard_return_cannot_find_topic_page
    return
}
# we found subject_line_suffix at least 


append page_content "
[bboard_header "$category threads in $topic"]

<h2>$category Threads</h2>

in the <a href=\"q-and-a?[export_url_vars topic topic_id]\">$topic question and answer forum</a>

<hr>


"

if { $category != "uncategorized" } {
    set category_clause "and category = :category"
} else {
    # **** NULL/'' problem, needs " or category = '' "
    set category_clause "and (category is NULL or category = 'Don''t Know')"
}


append page_content "<ul>\n"

set uninteresting_header_written 0
set counter 0

db_foreach category_messages "
select msg_id, 
       one_line, 
       sort_key, 
       email, 
       first_names || ' ' || last_name as name, 
       bboard_uninteresting_p(interest_level) as uninteresting_p
from   bboard, 
       users
where  topic_id = :topic_id
$category_clause
and    refers_to is null
and    users.user_id = bboard.user_id
order by uninteresting_p, sort_key $q_and_a_sort_order" {

    incr counter
    if { $uninteresting_p == "t" && $uninteresting_header_written == 0 } {
	set uninteresting_header_written 1
	append page_content "</ul>
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
    append page_content "<li><a href=\"q-and-a-fetch-msg?msg_id=$msg_id\">$display_string</a>\n"

}

append page_content "

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
    append page_content "There hasn't been any discussion yet.

<h3>You can be the one to start the discussion</h3> 

(of $key)

" } else {

    append page_content "<h3>You can ask a new question</h3>

(about $key)

"
}

append page_content "<p>

<form method=post action=\"insert-msg\" target=\"_top\">

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

[bboard_footer]
"

doc_return  200 text/html $page_content


# *** here we want an [ns_conn close] but it didn't make 2.2b2

# let's see if we need to put this into the categories table

if { $counter == 0 && [db_string category_check "
select count(*) from bboard_q_and_a_categories 
where topic_id = :topic_id and category = :key"] == 0 } {
    # catch to trap the primary key complaint from Oracle
    catch { db_dml category_insert "
    insert into bboard_q_and_a_categories (topic_id, category)
    values
    (:topic_id,:key)" }
}

