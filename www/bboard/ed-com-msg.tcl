# /www/bboard/ed-com-msg.tcl
ad_page_contract {
    Form for the editor to submit commentary

    @param msg_id the ID of the bboard posting

    @cvs-id ed-com-msg.tcl,v 3.1.6.6 2000/09/22 01:36:49 kevin Exp
} {
    msg_id:notnull
    topic:optional
    topic_id:optional
}

# -----------------------------------------------------------------------------

# make a copy because it is going to get overwritten by 
# some subsequent queries

set this_msg_id $msg_id

page_validation {
    if {![db_0or1row msg_info "
    select  to_char(posting_time,'Month dd, yyyy') as posting_date,
	    bb.msg_id,
	    bb.topic_id,
	    bb.one_line,
	    bb.message,
	    bb.html_p,
    	    users.user_id as poster_id,  
    	    users.first_names || ' ' || users.last_name as name
    from    bboard bb, users
    where   bb.user_id = users.user_id
    and     msg_id = :msg_id"] } {
	
	# message was probably deleted
	error "Couldn't find message $msg_id.  Probably it was deleted by the forum maintainer."
    }
}

set this_one_line $one_line

if {![db_0or1row topic_info "
select bt.topic_id, bt.topic, u.email as maintainer_email
from   bboard_topics bt, users u 
where  bt.topic=:topic
and    bt.primary_maintainer_id = u.user_id"]} {
    bboard_return_cannot_find_topic_page
    return
}

append page_content "
[bboard_header "$one_line"]

<h3>$one_line</h3>

by [ad_present_user $poster_id $name] on $posting_date in
<a href=\"q-and-a?[export_url_vars topic topic_id]\">$topic</a>

<hr>"

set msg_id_base "$msg_id%"
set num_responses [db_string n_replies "select count(*) from bboard 
where sort_key like :msg_id_base"]

db_release_unused_handles

append page_content "
<table width=100%>
<tr>
   <td align = right>"
      if { $num_responses != 1 } {
	  append page_content "
         <a href=\"ed-com-response?msg_id=$this_msg_id\">View commentary</a>"
      } else {
	  append page_content "
         <a href=\"q-and-a-post-reply-form?refers_to=$this_msg_id\">Submit your comment</a>"
      }

append page_content "
  </td>
</tr>
</table>

<blockquote>
[util_maybe_convert_to_html $message $html_p]
</blockquote>


<p>

[bboard_footer]"


doc_return  200 text/html $page_content