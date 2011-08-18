# $Id: ed-com-response.tcl,v 3.0 2000/02/06 03:33:50 ron Exp $
set_form_variables

# msg_id is the key
# make a copy because it is going to get overwritten by 
# some subsequent queries

# maybe, viewing_msg_id, which is either the msg_id for the message that
# will be expanded or all, which means they all will be expanded

# we are going to get responses to this message
set this_msg_id $msg_id
set db [ns_db gethandle]

if ![info exists viewing_msg_id] {
    set viewing_msg_id ""
}

set selection [ns_db 0or1row $db "select bboard.one_line, bboard.topic
from bboard
where msg_id = '$msg_id'"]

if { $selection == "" } {
    # message was probably deleted
    ns_return 200 text/html "Couldn't find message $msg_id.  Probably it was deleted by the forum maintainer."
    return
}

set_variables_after_query
set this_one_line $one_line

# now variable $topic is defined
set QQtopic [DoubleApos $topic]
if {[bboard_get_topic_info] == -1} {
    return
}


# number of responses to the original editorial

set num_responses [database_to_tcl_string $db "select count(*) from bboard 
where sort_key like '$msg_id%'"]


set max_expand_response_num 3

# compute the expand/contract link

set change_view ""

if { $viewing_msg_id == "all" && $num_responses > $max_expand_response_num } {
    set change_view "<a href=\"ed-com-response.tcl?msg_id=$this_msg_id\">Contract responses</a><p>"
} elseif {$num_responses > $max_expand_response_num} {
    set change_view "<a href=\"ed-com-response.tcl?msg_id=$this_msg_id&viewing_msg_id=all\">Expand all responses</a><p>"
}

ReturnHeaders

ns_write "[bboard_header "Commentary on $one_line"]
<table width=95% cellpadding=0 border=0 cellspacing=0> 
  <tr>
     <td>
        <h3>Commentary</h3>
        on <a href=\"ed-com-msg.tcl?msg_id=$msg_id\">$one_line</a> in <a href=\"q-and-a.tcl?[export_url_vars topic topic_id]\">$topic</a>
     </td>
     <td width=40% align=right>$change_view
     </td>
  </tr>
</table>

<hr>

"


# get all the info about the responses

set selection [ns_db select $db "select decode(email,'$maintainer_email','f','t') as not_maintainer_p, to_char(posting_time,'Month dd, yyyy') as posting_date, bboard.*, 
users.user_id as replyer_user_id,
users.first_names || ' ' || users.last_name as name, users.email 
from bboard, users
where users.user_id = bboard.user_id
and sort_key like '$msg_id%'
and msg_id <> '$msg_id'
order by not_maintainer_p, sort_key"]

# flag to determine if the output should be in a list or not

set list_output_p ""

while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    # if there are 3 or less responses or viewing_msg_id is all, print the full text
    if { $num_responses <= $max_expand_response_num  || $viewing_msg_id == "all"} {
	set this_response ""
	if { $one_line != $this_one_line && $one_line != "Response to $this_one_line" } {
	    # new subject
	    append this_response "<h4>$one_line</h4>\n"
	}
	append this_response "<blockquote>
[util_maybe_convert_to_html $message $html_p]
<br>
<br>
-- [ad_present_user $replyer_user_id $name], $posting_date
</blockquote>
"
	append responses $this_response

    } elseif { $viewing_msg_id != $msg_id } {

	# if there are more than 3 responses and viewing_msg_id is not all,
	# give an itemized list of reponses, with the message with a msg_id
	# of viewing_msg_id expanded
	set list_output_p "t"
	set this_response "<li>"
	if { $one_line != $this_one_line && $one_line != "Response to $this_one_line" } {
	    # new subject
	    append this_response "<a href=\"ed-com-response.tcl?viewing_msg_id=$msg_id&msg_id=$this_msg_id\">$one_line</a> "
	} else {
	    append this_response "<a href=\"ed-com-response.tcl?viewing_msg_id=$msg_id&msg_id=$this_msg_id\">Contribution</a> "
	}

	append this_response " by <a href=\"contributions.tcl?user_id=$replyer_user_id\">$name</a> ($posting_date). <br>"
	append responses $this_response
    } else {
	# viewing_msg_id = msg_id, so print the whole response
	set this_response "<p>"
	set contributed_by "Contributed by <a href=\"contributions.tcl?user_id=$replyer_user_id\">$name</a> on $posting_date."


	if { $one_line != $this_one_line && $one_line != "Response to $this_one_line" } {
	    # new subject
	    append this_response "<h4>$one_line</h4>\n"
	}
	append this_response "<blockquote>
	$message
	</blockquote>
	$contributed_by"
	append responses $this_response
	append responses "<p>"
    }
}


if { [info exists responses] } {
    # there were some
    if {$list_output_p == "t" } {
	ns_write "<h3>Responses</h3>
<ul>
$responses 
</ul>
<p>"
   } else {
 	ns_write "<h3>Contributions</h3>
$responses 
<p>"
   }
}

ns_write "
<a href=\"q-and-a-post-reply-form.tcl?refers_to=$this_msg_id\">Respond to \"$this_one_line\"</a> 

[bboard_footer]
"
