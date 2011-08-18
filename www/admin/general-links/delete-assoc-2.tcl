# File: /admin/general-links/delete-assoc-2.tcl
# Date: 2/01/2000
# Author: tzumainn@arsdigita.com 
#
# Purpose: 
# Step 2 of 2 in deleting a link association
#
# $Id: delete-assoc-2.tcl,v 3.0.4.1 2000/04/28 15:09:05 carsten Exp $
#--------------------------------------------------------

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

ad_page_variables {map_id {return_url ""}}

set db [ns_db gethandle]
set user_id [ad_get_user_id]

if [catch { ns_db dml $db "begin transaction" 

            ### No audits (yet) - Tzu-Mainn Chen
            # insert into the audit table
            # ns_db dml $db "insert into general_comments_audit
            #   (comment_id, user_id, ip_address, audit_entry_time, modified_date, content)
            #   select comment_id, user_id, '[ns_conn peeraddr]', sysdate, modified_date, content from general_comments where comment_id = $comment_id"

            set link_id [database_to_tcl_string $db "select link_id from site_wide_link_map where map_id = $map_id"]


            ns_db dml $db "delete from site_wide_link_map where map_id = $map_id"
            ns_db dml $db "end transaction" } errmsg] {

	# there was some other error with the link deletion
	ad_return_error "Error deleting link" "We couldn't update your link. Here is what the database returned:
<p>
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>
"
return
}

if {[empty_string_p $return_url]} {
    set return_url "view-associations.tcl?link_id=$link_id"
}

ad_returnredirect $return_url

