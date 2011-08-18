# $Id: admin-q-and-a-fetch-msg.tcl,v 3.0 2000/02/06 03:32:59 ron Exp $
set_form_variables

# msg_id is the key
# make a copy because it is going to get overwritten by 
# some subsequent queries

set this_msg_id $msg_id

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}


if [bboard_file_uploading_enabled_p] {
    set selection [ns_db 0or1row $db "select 
 posting_time as posting_date,
 bboard.*,
 bboard_topics.topic,
 users.email,
 users.first_names || ' ' || users.last_name as name, 
 buf.bboard_upload_id,
 buf.file_type,
 buf.n_bytes,
 buf.client_filename,
 buf.caption,
 buf.original_width,
 buf.original_height
from bboard, bboard_topics, users, bboard_uploaded_files buf
where bboard_topics.topic_id = bboard.topic_id
and bboard.user_id = users.user_id
and bboard.msg_id = buf.msg_id(+)
and bboard.msg_id = '$msg_id'"]
} else {
    set selection [ns_db 0or1row $db "select to_char(posting_time,'YYYY-MM-DD') as posting_date,bboard.*, users.first_names || ' ' || users.last_name as name, users.email, bboard_topics.topic
from bboard, users, bboard_topics
where users.user_id = bboard.user_id
and bboard.topic_id = bboard_topics.topic_id
and msg_id = '$msg_id'"]
}

if { $selection == "" } {
    # message was probably deleted
    ns_return 200 text/html "Couldn't find message $msg_id.  Probably it was deleted by the forum maintainer."
    return
}

set_variables_after_query
# now we know the topic for this message, make sure the user is
# authorized


set QQtopic [DoubleApos $topic]


 
if  {[bboard_get_topic_info] == -1} {
    return}

if {[bboard_admin_authorization] == -1} {
	return}




set this_one_line $one_line

# now variables like $message and $topic are defined



if { $originating_ip != "" } {
    set contributed_by "Asked by $name (<a href=\"admin-view-one-email.tcl?[export_url_vars topic topic_id]&email=[ns_urlencode $email]\">$email</a>) 
from
<a href=\"admin-view-one-ip.tcl?originating_ip=[ns_urlencode $originating_ip]&[export_url_vars topic topic_id]\">$originating_ip</a> on [util_IllustraDatetoPrettyDate $posting_date]."
} else {
    set contributed_by "Asked by $name (<a href=\"admin-view-one-email.tcl?[export_url_vars topic topic_id]&email=[ns_urlencode $email]\">$email</a>) on [util_IllustraDatetoPrettyDate $posting_date]."
}

# find out if this is usgeospatial
set presentation_type [database_to_tcl_string $db "select presentation_type from bboard_topics where topic_id = $topic_id"]

ReturnHeaders

ns_write "<html>
<head>
<title>$one_line</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>


<h2>$one_line</h2>

"

if { $presentation_type == "usgeospatial" } {
    ns_write "in the <a href=\"admin-usgeospatial.tcl?[export_url_vars topic topic_id]\">$topic $presentation_type forum</a>"
} else {
    ns_write "in the <a href=\"admin-q-and-a.tcl?[export_url_vars topic topic_id]\">$topic $presentation_type forum</a>"
}

ns_write "<hr>


<form method=post action=admin-update-one-line.tcl>
<input type=hidden name=msg_id value=\"$msg_id\">
Thread title: <input type=text name=one_line value=\"[philg_quote_double_quotes $one_line]\" size=60>
<input type=submit value=\"Update Thread Title\">
</form>
<p>

"

if { $presentation_type == "usgeospatial" } {
    ns_write "asked in the <a href=\"q-and-a.tcl?[export_url_vars topic topic_id]\">$topic (<a href=usgeospatial-2.tcl?[export_url_vars topic topic_id]&epa_region=$epa_region>$epa_region</a> : <a href=usgeospatial-one-state.tcl?[export_url_vars topic topic_id]&usps_abbrev=$usps_abbrev>$usps_abbrev</a> : <a href=usgeospatial-one-county.tcl?[export_url_vars topic topic_id]&fips_county_code=$fips_county_code>$fips_county_code</a> : $tri_id) $presentation_type Forum</a>
"
} else {
    ns_write "asked in the <a href=\"q-and-a.tcl?[export_url_vars topic topic_id]\">$topic $presentation_type Forum</a>
"
}

ns_write "<P>

<ul>

<li><a href=\"delete-msg.tcl?msg_id=$msg_id\">DELETE ENTIRE THREAD</a>

"

if { $q_and_a_use_interest_level_p == "t" } {
    ns_write "<form method=post action=admin-update-interest-level.tcl>
<input type=hidden name=msg_id value=\"$msg_id\">
<li>Interest Level:
<input type=text name=interest_level size=4 value=\"$interest_level\">
</form>
"

}

ns_write "
<form method=post action=admin-update-expiration-days.tcl>
<input type=hidden name=msg_id value=\"$msg_id\">
<li>Expiration Days:
<input type=text name=expiration_days size=4 value=\"$expiration_days\">
</form>
"


if { $q_and_a_categorized_p == "t" } {
    set categories [database_to_tcl_list $db "select distinct category, upper(category) from bboard_q_and_a_categories where topic_id = $topic_id order by 2"]
    lappend categories "Define New Category"
    ns_write "<li><form method=POST action=q-and-a-update-category.tcl>
<input type=hidden name=msg_id value=\"$msg_id\">
<select name=category>"
    if { $category == "" } {
	ns_write "<option value=\"\" SELECTED>Uncategorized"
    } else {
	ns_write "<option value=\"\">Uncategorized"
    }
    foreach choice $categories {
	if { $category == $choice } {
	    ns_write "<option SELECTED>$choice"
	} else {
	    ns_write "<option>$choice"
	}
    }

    ns_write "</select><input type=submit value=\"Set Category\"></form>"

}

ns_write "

</ul>

<hr>

<form method=post action=admin-bulk-delete.tcl>
<input type=hidden name=msg_id value=\"$msg_id\">

<table>
<tr>
<td>
<blockquote>
"

if { [info exists bboard_upload_id] && [info exists file_type] && ![empty_string_p $bboard_upload_id] && $file_type == "photo" && $n_bytes > 0 } {
    # ok, we have a photo; the question is how big is it 
    if [empty_string_p $original_width] {
	# we don't know how big it is so it probably wasn't a JPEG or GIF
	ns_write "<center>(undisplayable image: <i>$caption</i> -- <a href=\"uploaded-file.tcl?[export_url_vars bboard_upload_id]\">$client_filename</a>)</center>"
    } elseif { $original_width < 512 } {
	ns_write "<center>\n<img height=$original_height width=$original_width hspace=5 vspace=10 src=\"image.tcl?[export_url_vars bboard_upload_id]\">\n<br><i>$caption</i>\n</center>\n<br>"
    } else {
	ns_write "<center><a href=\"big-image.tcl?[export_url_vars bboard_upload_id]\">($caption -- $original_height x $original_width $file_type)</a></center>"
    }
}

ns_write "[util_maybe_convert_to_html $message $html_p]
</blockquote>

$contributed_by
"

if { [info exists bboard_upload_id] && [info exists file_type] && ![empty_string_p $bboard_upload_id] && $file_type != "photo" } {
    ns_write "<br>Attachment:  <a href=\"uploaded-file.tcl?[export_url_vars bboard_upload_id]\">$client_filename</a>\n"
}

ns_write "<td valign=top>
<a href=\"delete-msg.tcl?msg_id=$msg_id\">DELETE</a><br>
<a href=\"admin-edit-msg.tcl?msg_id=$msg_id\">EDIT</a>
</tr>
</table>
"


set selection [ns_db select $db "select decode(email,'$maintainer_email','f','t') as not_maintainer_p, to_char(posting_time,'YYYY-MM-DD') as posting_date,bboard.*, users.first_names || ' ' || users.last_name as name, users.email
from bboard, users
where bboard.user_id = users.user_id
and  sort_key like '$msg_id%'
and msg_id <> '$msg_id'
order by not_maintainer_p, sort_key"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    if { $email == "" } {
	if { $originating_ip == "" } {
	    set contributed_by "anonymously answered on [util_IllustraDatetoPrettyDate $posting_date]." } else {
	    set contributed_by "anonymously answered 
from <a href=\"admin-view-one-ip.tcl?originating_ip=[ns_urlencode $originating_ip]&[export_url_vars topic topic_id]\">$originating_ip</a> 
on [util_IllustraDatetoPrettyDate $posting_date]."
          }
    } else {
	if { $originating_ip == "" } {
	    set contributed_by "Answered by $name (<a href=\"admin-view-one-email.tcl?[export_url_vars topic topic_id]&email=[ns_urlencode $email]\">$email</a>) on [util_IllustraDatetoPrettyDate $posting_date]."
	} else {
	    set contributed_by "Answered by $name (<a href=\"admin-view-one-email.tcl?[export_url_vars topic topic_id]&email=[ns_urlencode $email]\">$email</a>) 
from <a href=\"admin-view-one-ip.tcl?originating_ip=[ns_urlencode $originating_ip]&[export_url_vars topic topic_id]\">$originating_ip</a> 
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
<a href=\"delete-msg.tcl?msg_id=$msg_id\">DELETE</a><br>
<a href=\"admin-edit-msg.tcl?msg_id=$msg_id\">EDIT</a><p>
<input type=checkbox name=deletion_ids value=\"$msg_id\"> bulk delete
</tr>
</table>
"
    lappend responses $this_response
}

if { [info exists responses] } {
    # there were some
    ns_write "<h3>Answers</h3>
[join $responses "<hr width=300>"]
"
}
    

ns_write "

<p>
<table width=100%>
<tr>
<td align=left>
"

if { $presentation_type == "usgeospatial" } {
    ns_write "<a href=\"usgeospatial-post-reply-form.tcl?refers_to=$this_msg_id\">Contribute an answer to \"$this_one_line\"</a>
"
} else {
    ns_write "<a href=\"q-and-a-post-reply-form.tcl?refers_to=$this_msg_id\">Contribute an answer to \"$this_one_line\"</a>
"
}

ns_write "<td align=right>
<input type=submit value=\"Delete Marked Messages\">
</tr>
</table>
</form>



[bboard_footer]

"

