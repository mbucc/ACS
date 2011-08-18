# File: /admin/general-links/edit-link-2.tcl
# Date: 2/01/2000
# Author: tzumainn@arsdigita.com 
#
# Purpose: 
# Step 2 of 2 in editing a link
#
# $Id: edit-link-2.tcl,v 3.0.4.1 2000/04/28 15:09:05 carsten Exp $
#--------------------------------------------------------

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set admin_id [ad_maybe_redirect_for_registration]

set category_id_list ""
ad_page_variables {link_id link_title url link_description approved_p {return_url "index.tcl"} {category_id_list -multiple-list}}


page_validation {
    if {[empty_string_p $url]} {
	error "Please enter a url."
    }
} {
    if {[empty_string_p $link_title]} { 
	error "Please enter a link title."
    }
}

# user has input something, so continue on

set db [ns_db gethandle]

if [catch { ns_db dml $db "begin transaction"

            #### No audits, yet - Tzu-Mainn Chen
            # insert into the audit table
#            ns_db dml $db "insert into general_comments_audit
#(comment_id, user_id, ip_address, audit_entry_time, modified_date, content)
# select comment_id, $admin_id, '[ns_conn peeraddr]', sysdate, modified_date, content from general_comments where comment_id = $comment_id"

           set current_approval_status [database_to_tcl_string $db "select approved_p from general_links where link_id = $link_id"]

           if { $current_approval_status != $approved_p } {
	       ns_db dml $db "update general_links set approved_p = logical_negation(approved_p), last_approval_change = sysdate where link_id = $link_id"
	   }

           ns_db dml $db "update general_links
           set url = '[DoubleApos $url]',
           link_title = '[DoubleApos $link_title]',
           link_description = '[DoubleApos $link_description]',
           last_modified = sysdate,
	   last_modifying_user = $admin_id
           where link_id = $link_id"

           if { $category_id_list != "{}"} {
             ad_categorize_row -db $db -which_table "general_links" -what_id $link_id -category_id_list $category_id_list -one_line_item_desc "[DoubleApos $link_title]"
            }
            ad_general_link_check $db $link_id

            ns_db dml $db "end transaction" } errmsg] {

	# there was some other error with the link update
	ad_return_error "Error updating link" "We couldn't update your link. Here is what the database returned:
<p>
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>
"
return
}

ad_returnredirect $return_url
