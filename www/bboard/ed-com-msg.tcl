# $Id: ed-com-msg.tcl,v 3.0 2000/02/06 03:33:48 ron Exp $
set_form_variables

# msg_id is the key
# make a copy because it is going to get overwritten by 
# some subsequent queries

set this_msg_id $msg_id

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select to_char(posting_time,'Month dd, yyyy') as posting_date,bboard.*, users.user_id as poster_id,  users.first_names || ' ' || users.last_name as name
from bboard, users
where bboard.user_id = users.user_id
and msg_id = '$msg_id'"]

if { $selection == "" } {
    # message was probably deleted
    ns_return 200 text/html "Couldn't find message $msg_id.  Probably it was deleted by the forum maintainer."
    return
}

set_variables_after_query
set this_one_line $one_line

# now variables like $message and $topic are defined

if [catch {set selection [ns_db 1row $db "select bt.*, u.email as maintainer_email 
from bboard_topics bt, users u 
where bt.topic='[DoubleApos $topic]'
and bt.primary_maintainer_id = u.user_id"]} errmsg] {
    bboard_return_cannot_find_topic_page
    return
}
set_variables_after_query

ReturnHeaders

ns_write "[bboard_header "$one_line"]

<h3>$one_line</h3>

by [ad_present_user $poster_id $name] on $posting_date in
<a href=\"q-and-a.tcl?[export_url_vars topic topic_id]\">$topic</a>

<hr>"


set num_responses [database_to_tcl_string $db "select count(*) from bboard 
where sort_key like '$msg_id%'"]

ns_write "
<table width=100%>
<tr>
   <td align = right>"
      if { $num_responses != 1 } {
         ns_write "
         <a href=\"ed-com-response.tcl?msg_id=$this_msg_id\">View commentary</a>"
      } else {
         ns_write "
         <a href=\"q-and-a-post-reply-form.tcl?refers_to=$this_msg_id\">Submit your comment</a>"
      }
ns_write "
  </td>
</tr>
</table>"

ns_write "
<blockquote>
[util_maybe_convert_to_html $message $html_p]
</blockquote>


<p>

[bboard_footer]"

