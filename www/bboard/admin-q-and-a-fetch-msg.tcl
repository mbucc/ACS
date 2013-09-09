# /www/bboard/admin-q-and-a-fetch-msg.tcl
ad_page_contract {
    Administrative view of one message

    @param msg_id the ID string of the message

    @cvs-id admin-q-and-a-fetch-msg.tcl,v 3.4.2.6 2000/09/22 01:36:45 kevin Exp
} {
    msg_id:notnull
}

# -----------------------------------------------------------------------------

# make a copy because it is going to get overwritten by 
# some subsequent queries

set this_msg_id $msg_id

if [bboard_file_uploading_enabled_p] {
    set found_msg_p [db_0or1row msg_info_with_file "
select b.posting_time as posting_date,
       b.one_line, 
       b.message,
       b.originating_ip,
       b.epa_region,
       b.usps_abbrev,
       b.fips_county_code,
       b.interest_level,
       b.category,
       b.html_p,
       b.expiration_days,
       bt.topic,
       u.email,
       u.first_names || ' ' || u.last_name as name, 
       buf.bboard_upload_id,
       buf.file_type,
       buf.n_bytes,
       buf.client_filename,
       buf.caption,
       buf.original_width,
       buf.original_height
from   bboard b, 
       bboard_topics bt, 
       users u, 
       bboard_uploaded_files buf
where  bt.topic_id = b.topic_id
and    b.user_id = u.user_id
and    b.msg_id = buf.msg_id(+)
and    b.msg_id = :msg_id"]
} else {
    set found_msg_p [db_0or1row msg_info "
select to_char(posting_time,'YYYY-MM-DD') as posting_date,
       b.one_line, 
       b.message,
       b.originating_ip,
       b.epa_region,
       b.usps_abbrev,
       b.fips_county_code,
       b.interest_level,
       b.category,
       b.html_p,
       b.expiration_days,
       u.first_names || ' ' || u.last_name as name, 
       u.email, 
       bt.topic
from   bboard b, 
       users u, 
       bboard_topics bt
where  u.user_id = b.user_id
and    b.topic_id = bt.topic_id
and    msg_id = :msg_id"]
}

if { $found_msg_p == 0 } {
    # message was probably deleted
    doc_return  200 text/html "Couldn't find message $msg_id.  Probably it was deleted by the forum maintainer."
    return
}

# now we know the topic for this message, make sure the user is
# authorized
 
if  {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
    return
}


set this_one_line $one_line
set this_msg_id $msg_id

# now variables like $message and $topic are defined



if { $originating_ip != "" } {
    set contributed_by "Asked by $name (<a href=\"admin-view-one-email?[export_url_vars topic topic_id]&email=[ns_urlencode $email]\">$email</a>) 
from
<a href=\"admin-view-one-ip?originating_ip=[ns_urlencode $originating_ip]&[export_url_vars topic topic_id]\">$originating_ip</a> on [util_IllustraDatetoPrettyDate $posting_date]."
} else {
    set contributed_by "Asked by $name (<a href=\"admin-view-one-email?[export_url_vars topic topic_id]&email=[ns_urlencode $email]\">$email</a>) on [util_IllustraDatetoPrettyDate $posting_date]."
}

# find out if this is usgeospatial
db_1row presentation_type "
select presentation_type from bboard_topics where topic_id = :topic_id"

append page_content "
[bboard_header $one_line]

<h2>$one_line</h2>

"

if { $presentation_type == "usgeospatial" } {
    append page_content "in the <a href=\"admin-usgeospatial?[export_url_vars topic topic_id]\">$topic $presentation_type forum</a>"
} else {
    append page_content "in the <a href=\"admin-q-and-a?[export_url_vars topic topic_id]\">$topic $presentation_type forum</a>"
}

append page_content "<hr>


<form method=post anction=admin-update-one-line>
<input type=hidden name=msg_id value=\"$msg_id\">
Thread title: <input type=text name=one_line value=\"[philg_quote_double_quotes $one_line]\" size=60>
<input type=submit value=\"Update Thread Title\">
</form>
<p>

"

if { $presentation_type == "usgeospatial" } {
    append page_content "asked in the 
<a href=\"q-and-a?[export_url_vars topic topic_id]\">$topic 
(<a href=usgeospatial-2?[export_url_vars topic topic_id]&epa_region=$epa_region>$epa_region</a> : 
<a href=usgeospatial-one-state?[export_url_vars topic topic_id]&usps_abbrev=$usps_abbrev>$usps_abbrev</a> : 
<a href=usgeospatial-one-county?[export_url_vars topic topic_id]&fips_county_code=$fips_county_code>$fips_county_code</a>) 
$presentation_type Forum</a>
"
} else {
    append page_content "asked in the <a href=\"q-and-a?[export_url_vars topic topic_id]\">$topic $presentation_type Forum</a>
"
}

append page_content "<P>

<ul>

<li><a href=\"delete-msg?msg_id=$msg_id\">DELETE ENTIRE THREAD</a>

"

if { $q_and_a_use_interest_level_p == "t" } {
    append page_content "<form method=post action=admin-update-interest-level>
<input type=hidden name=msg_id value=\"$msg_id\">
<li>Interest Level:
<input type=text name=interest_level size=4 value=\"$interest_level\">
</form>
"

}

append page_content "
<form method=post action=admin-update-expiration-days>
<input type=hidden name=msg_id value=\"$msg_id\">
<li>Expiration Days:
<input type=text name=expiration_days size=4 value=\"$expiration_days\">
</form>
"


if { $q_and_a_categorized_p == "t" } {
    set categories [db_list category_list "
    select distinct category, upper(category) 
    from bboard_q_and_a_categories 
    where topic_id = :topic_id 
    order by 2"]
    lappend categories "Define New Category"
    append page_content "<li><form method=POST action=q-and-a-update-category>
<input type=hidden name=msg_id value=\"$msg_id\">
<select name=category>"
    if { $category == "" } {
	append page_content "<option value=\"\" SELECTED>Uncategorized"
    } else {
	append page_content "<option value=\"\">Uncategorized"
    }
    foreach choice $categories {
	if { $category == $choice } {
	    append page_content "<option SELECTED>$choice"
	} else {
	    append page_content "<option>$choice"
	}
    }

    append page_content "</select><input type=submit value=\"Set Category\"></form>"

}

append page_content "

</ul>

<hr>

<form method=post action=admin-bulk-delete>
<input type=hidden name=msg_id value=\"$msg_id\">

<table>
<tr>
<td>
<blockquote>
"

if { [info exists bboard_upload_id] && [info exists file_type] && ![empty_string_p $bboard_upload_id] && $file_type == "photo" && $n_bytes > 0 } {
    # ok, we have a photo; the question is how big is it 

    regsub -all {[^-_.0-9a-zA-Z]+} $client_filename "_" pretty_filename

    if [empty_string_p $original_width] {
	# we don't know how big it is so it probably wasn't a JPEG or GIF
	append page_content "<center>(undisplayable image: <i>$caption</i> -- <a href=\"download-file/$bboard_upload_id/$pretty_filename\">$client_filename</a>)</center>"
    } elseif { $original_width < 512 } {
	append page_content "<center>\n<img height=$original_height width=$original_width hspace=5 vspace=10 src=\"image.tcl?[export_url_vars bboard_upload_id]\">\n<br><i>$caption</i>\n</center>\n<br>"
    } else {
	append page_content "<center><a href=\"big-image?[export_url_vars bboard_upload_id]\">($caption -- $original_height x $original_width $file_type)</a></center>"
    }
}

append page_content "[util_maybe_convert_to_html $message $html_p]
</blockquote>

$contributed_by
"

if { [info exists bboard_upload_id] && [info exists file_type] && ![empty_string_p $bboard_upload_id] && $file_type != "photo" } {
    regsub -all {[^-_.0-9a-zA-Z]+} $client_filename "_" pretty_filename

    append page_content "<br>Attachment:  <a href=\"download-file/$bboard_upload_id/$pretty_filename\">$client_filename</a>\n"
}

append page_content "<td valign=top>
<a href=\"delete-msg?msg_id=$msg_id\">DELETE</a><br>
<a href=\"admin-edit-msg?msg_id=$msg_id\">EDIT</a>
</tr>
</table>
"

# -----------------------------------------------------------------------------

# Responses

set msg_id_base "$msg_id%"

db_foreach responses "
select decode(email,'$maintainer_email','f','t') as not_maintainer_p, 
       to_char(posting_time,'YYYY-MM-DD') as posting_date,
       b.originating_ip,
       b.one_line,
       b.message,
       b.html_p,
       b.msg_id,
       users.first_names || ' ' || users.last_name as name, 
       users.email
from   bboard b, 
       users
where  b.user_id = users.user_id
and    sort_key like :msg_id_base
and    msg_id <> :msg_id
order by not_maintainer_p, sort_key" {

    if { $email == "" } {
	if { $originating_ip == "" } {
	    set contributed_by "anonymously answered on [util_IllustraDatetoPrettyDate $posting_date]." } else {
	    set contributed_by "anonymously answered 
from <a href=\"admin-view-one-ip?originating_ip=[ns_urlencode $originating_ip]&[export_url_vars topic topic_id]\">$originating_ip</a> 
on [util_IllustraDatetoPrettyDate $posting_date]."
          }
    } else {
	if { $originating_ip == "" } {
	    set contributed_by "Answered by $name (<a href=\"admin-view-one-email?[export_url_vars topic topic_id]&email=[ns_urlencode $email]\">$email</a>) on [util_IllustraDatetoPrettyDate $posting_date]."
	} else {
	    set contributed_by "Answered by $name (<a href=\"admin-view-one-email?[export_url_vars topic topic_id]&email=[ns_urlencode $email]\">$email</a>) 
from <a href=\"admin-view-one-ip?originating_ip=[ns_urlencode $originating_ip]&[export_url_vars topic topic_id]\">$originating_ip</a> 
on [util_IllustraDatetoPrettyDate $posting_date]."
	}
}
    set this_response ""
    if { $one_line != $this_one_line && $one_line != "Response to $this_one_line" } {
	# new subject
	append this_response "<h4>$one_line</h4>\n"
    }
    append this_response "<table>
<tr>
<td>
<blockquote>
[util_maybe_convert_to_html $message $html_p]
</blockquote>
$contributed_by
<td>
<a href=\"delete-msg?msg_id=$msg_id\">DELETE</a><br>
<a href=\"admin-edit-msg?msg_id=$msg_id\">EDIT</a><p>
<input type=checkbox name=deletion_ids value=\"$msg_id\"> bulk delete
</tr>
</table>
"
    lappend responses $this_response
}

if { [info exists responses] } {
    # there were some
    append page_content "<h3>Answers</h3>
[join $responses "<hr width=300>"]
"
}
    

append page_content "

<p>
<table width=100%>
<tr>
<td align=left>
"

if { $presentation_type == "usgeospatial" } {
    append page_content "<a href=\"usgeospatial-post-reply-form?refers_to=$this_msg_id\">Contribute an answer to \"$this_one_line\"</a>
"
} else {
    append page_content "<a href=\"q-and-a-post-reply-form?refers_to=$this_msg_id\">Contribute an answer to \"$this_one_line\"</a>
"
}

append page_content "<td align=right>
<input type=submit value=\"Delete Marked Messages\">
</tr>
</table>
</form>



[bboard_footer]
 
"

doc_return 200 text/html $page_content 
