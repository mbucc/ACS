# File: /general-links/link-add-without-assoc-4.tcl
# Date: 2/01/2000
# Author: tzumainn@arsdigita.com 
#
# Purpose: 
#  Step 4 of 4 in adding link WITHOUT association
#
# $Id: link-add-without-assoc-4.tcl,v 3.1.2.2 2000/04/28 15:10:39 carsten Exp $
#--------------------------------------------------------

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

ad_page_variables {return_url link_id link_title url rating {category_id_list -multiple-list} {link_description ""}}

# user has input something, so continue on

set category_id_list_hack [lindex $category_id_list 0]

# assign necessary data for insert
set user_id [ad_maybe_redirect_for_registration]

set originating_ip [ns_conn peeraddr]

set db [ns_db gethandle]

# Get the default approval policy for the site
set approval_policy [ad_parameter DefaultLinkApprovalPolicy]

if {$approval_policy == "open"} {
    set approved_p "t"
} else {
     set approved_p ""
}

if [catch {
    ns_db dml $db "begin transaction"
    ad_general_link_add $db $link_id $url $link_title $link_description $user_id $originating_ip $approved_p

    if {$category_id_list_hack != "{}"} {
	ad_categorize_row -db $db -which_table "general_links" -what_id $link_id -category_id_list $category_id_list_hack -one_line_item_desc "[DoubleApos $link_title]"
    }

    ad_general_link_check $db $link_id
    ns_db dml $db "insert into general_link_user_ratings (user_id, link_id, rating)
    values
    ($user_id, $link_id, $rating)
    "
    ns_db dml $db "end transaction"
} errmsg] {
    # Oracle choked on the insert
    ns_db dml $db "abort transaction"
    if { [database_to_tcl_string $db "select count(*) from general_links where link_id = $link_id"] == 0 } {
	# there was an error with link insert other than a duplication

	ad_return_error "Error in inserting link" "We were unable to insert your link in the database.  Here is the error that was returned:
	<p>
	<blockquote>
	<pre>
	$errmsg
	</pre>
	</blockquote>"
        return
     } else { 
	 ad_returnredirect $return_url
     }
 }

ad_returnredirect $return_url
