# /www/bboard/q-and-a-post-new.tcl
ad_page_contract {
    Form to post a new question to a bboard

    @param topic the name of the bboard topic
    @param topic_id the ID of the bboard topic

    @author philg@arsdigita.com
    @author hqm@arsdigita.com
    @creation-date 1995
    @cvs-id q-and-a-post-new.tcl,v 3.4.2.5 2000/10/25 23:05:38 kevin Exp
} {
    topic_id:integer,notnull
    topic:notnull
}

# -----------------------------------------------------------------------------

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

if {[bboard_get_topic_info] == -1} {
    return
}

#check for the user cookie

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

# we know who this is

if { ![empty_string_p $policy_statement] } {
    set policy_link "<li><a href=\"policy?[export_url_vars topic_id topic]\">read the forum policy</a>\n"
} else {
    set policy_link ""
}

if { [bboard_pls_blade_installed_p] } {
    set search_server [ad_parameter BounceQueriesTo site-wide-search ""]
    set search_option "Before you post a new question, you might want to 

<ul>
$policy_link
<li><form method=GET action=\"$search_server/bboard/q-and-a-search\" target=\"_top\">
<input type=hidden name=topic value=\"$topic\">
<input type=hidden name=topic_id value=\"$topic_id\">
search to see if it has been asked and answered:  <input type=text name=query_string size=20>
[submit_button_if_msie_p]
</form>
</ul>

$pre_post_caveat

<hr>
"
} else {
    if ![empty_string_p $policy_link] {
	set search_option "Before you post a new question, you might want to 

<ul>
$policy_link
</ul>
$pre_post_caveat
" 
    } else {
	set search_option "$pre_post_caveat"
    }
}

append page_content "
[bboard_header "Post New Message"]

<h3>Post a New Message</h3>

[ad_context_bar_ws_or_index [list "index.tcl" [bboard_system_name]] [list [bboard_raw_backlink $topic_id $topic $presentation_type 0] $topic] "Start New Thread"]

<hr>

$search_option

<form method=post action=\"confirm\" target=\"_top\">
[philg_hidden_input q_and_a_p t]
[philg_hidden_input topic $topic]
[philg_hidden_input topic_id $topic_id]
[philg_hidden_input refers_to NEW]

<table>

<tr><th align=left>Subject Line<br>(summary of question)<td><input type=text name=one_line size=50></tr>

"

# think about writing a category SELECT 

if { $q_and_a_categorized_p == "t" && $q_and_a_solicit_category_p == "t" } {
    set categories [db_list categoried "
    select distinct category, upper(category) 
    from bboard_q_and_a_categories 
    where topic_id = :topic_id order by 2"]
    set html_select "<select name=category>
    <option value=\"\" SELECTED>Don't Know
    "
    append html_select "<option>" [join $categories "\n<option>"]
    append html_select "\n</select>"
    append page_content "<tr><th>Category<td>\n$html_select\n(this helps build the FAQ archives)</tr>\n"
}

if { $custom_sort_key_p == "t" && $custom_sort_solicit_p == "t" } {
    append page_content "<tr><td colspan=2>This is a special bulletin board where the top level page presents messages according to a custom sort key:  \"$custom_sort_key_name\"</tr>
<tr><th>$custom_sort_key_name<td>"
    # need to put in a widget
    if { $custom_sort_key_type == "date" } {
	append page_content [_ns_dateentrywidget custom_sort_key]
    } else {
	append page_content "<input type=text name=custom_sort_key size=20>"
    }
    append page_content "</tr>\n"
    if { $custom_sort_solicit_pretty_p == "t" } {
	append page_content "<tr><th>$custom_sort_pretty_name<td><input type=text name=custom_sort_key_pretty size=20> $custom_sort_pretty_explanation </tr>" 
    }
}

append page_content "

<tr><th>Notify Me of Responses
<td><input type=radio name=notify value=t CHECKED> Yes
<input type=radio name=notify value=f> No

<tr><th align=left>Message<td></td>
</tr>
<tr><td colspan=2>
<textarea name=message rows=10 cols=70 wrap=physical></textarea>
</td></tr>
<tr><th align=left>Text above is:
<td><select name=html_p><option value=f>Plain Text<option value=t>HTML</select></td>
</tr>
</table>

<P>

<center>

<input type=submit value=Post>

</center>

</form>

[bboard_footer]
"

doc_return  200 text/html $page_content