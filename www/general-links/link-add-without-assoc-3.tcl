# File: /general-links/link-add-without-assoc-3.tcl
# Date: 2/01/2000
# Author: tzumainn@arsdigita.com 
#
# Purpose: 
#  
#
# link-add-without-assoc-3.tcl,v 3.2.6.6 2001/01/10 21:08:19 khy Exp
#--------------------------------------------------------
ad_page_contract {
    Step 3 of 4 in adding link WITHOUT association.

    @param return_url the url to go back to 
    @param link_id the generated ID of the link
    @param link_title the title of the link
    @param url the URL
    @param link_description a description of the link defaults to blank
    @param category_id_list the list of associated categories

    @author  tzumainn@arsdigita.com
    @creation-date 1 February 2000
    @cvs-id link-add-without-assoc-3.tcl,v 3.2.6.6 2001/01/10 21:08:19 khy Exp

} {
    return_url:notnull
    link_id:notnull,naturalnum,verify
    link_title:notnull
    url:notnull
    {link_description ""} 
    category_id_list:multiple
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}


set page_content "
[ad_header "Confirm Link (Step 3 of 3)"]

<h2>Confirm Link (Step 3 of 3)</h2>

[ad_context_bar_ws [list $return_url "General Links"] "Confirm Link (Step 3 of 3)"]

<hr>
"



set category_list "<ul>"
set n_categories 0

if ![empty_string_p [lindex $category_id_list 0]] {
    set category_name_list [db_list select_category_name_list "select category from categories where category_id in ([join $category_id_list ", "]) order by category"]

    foreach category_name $category_name_list {
	incr n_categories
	if ![empty_string_p $category_name] {
	    append category_list "<li> $category_name"
	}
    }
}

db_release_unused_handles

if { $n_categories == 0 } {
    append category_list "<li><i>None</i>"
}
append category_list "</ul>"

set approval_policy [ad_parameter DefaultLinkApprovalPolicy]
if { $approval_policy != "open" } {
    set approval_text "<p><i>Your link must be approved by an administrator before it becomes visible to users.</i>"
} else {
    set approval_text ""
}

set rating_html "<select name=rating>"
set current_rating 0
while { $current_rating <= 10 } {
    append rating_html "<option type=radio name=rating value=\"$current_rating\">$current_rating "
    
    incr current_rating
}
append rating_html "</select>"

append page_content "
Here is how your link will appear:

<blockquote>
<a href=\"$url\"><b>$link_title</b></a> - <b>No ratings</b> - more (<i>This will link to additional features about the link</i>)

<p>It will be associated with the following categories:
$category_list
$approval_text
<form action=\"link-add-without-assoc-4\" method=post>
[export_form_vars return_url link_title url link_description category_id_list]
[export_form_vars -sign link_id]
Please rate this link:
$rating_html
</blockquote>
<p>
<center>
<input type=submit name=submit value=\"Confirm Link Addition\">
</center>
</form>

[ad_footer]
"

doc_return  200 text/html $page_content


