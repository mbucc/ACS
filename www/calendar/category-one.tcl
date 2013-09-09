# www/calendar/one-category.tcl
ad_page_contract {
    Lists all approved, upcoming calendar items within a category

    @author Caroline Meeks (Caroline@arsdigita.com)
    @creation-date 2000-01-??
    @cvs-id category-one.tcl,v 1.1.2.3 2000/09/22 01:37:04 kevin Exp
    @last-modified 2000-07-12
    @last-modified-by Michael Shurpik (mshurpik@arsdigita.com)
} {
    category_id:integer
}

## This page, having been written afterwards, is suspiciously lacking 
## in use of the various scope procedures -MJS 7/13

## Yep, this page has no security, other than that you are forced to register.
## You can look at other people's private categories. -MJS 7/14


#Written by Caroline@arsdigita.com Jan 2000.
#for some reason this page was called but did not exist.
#prints out all items for a category.

set query_unused "select category from calendar_categories where category_id=:category_id"

## Get the category name so we can proceed.
## If the category_id is invalid, print an error message
if {![catch {set category [db_string unused $query_unused]} catch_error]} {

    set page_title "$category"
    set category_found_p 1

} else {
    
    set page_title "Category not found"
    set category "Not Found"
    set category_found_p 0
    
}

set page_content "[ad_header $page_title]

[ad_context_bar_ws_or_index [list "index.tcl" [ad_parameter SystemName calendar "Calendar"]] "$category"]

<h2>$page_title</h2>
<hr>
<ul>

"

if {$category_found_p} {
    
    set query_select_items "select 
    calendar_id,
    title,
    to_char(start_date,'Month DD, YYYY') as pretty_start_date,
    to_char(start_date,'J') as j_start_date 
    from calendar c
    where sysdate < expiration_date
    and category_id=:category_id
    and approved_p = 't'
    order by start_date, creation_date
    "
    
    
    set counter 0
    
    db_foreach select_items $query_select_items {
	
	incr counter
	append page_content "<li><a href=\"/calendar/item?calendar_id=$calendar_id\">$title</a> ($pretty_start_date)\n"
	
    } 
	
    db_release_unused_handles
    	

    if { $counter == 0 } {
	    
    ## Is this </table> tag here for a reason? -MJS 7/12/00
    append page_content "</table>there are no upcoming events"

    }

}  
## END if {$category_found_p}



if { [ad_parameter ApprovalPolicy calendar] == "open"} {
    
    append page_content "<p>\n<li><a href=\"post-new\">post an item</a>\n"

} elseif { [ad_parameter ApprovalPolicy calendar] == "wait"} {
    
    append page_content "<p>\n<li><a href=\"post-new\">suggest an item</a>\n"
    
}


if { [db_string unused "select count(*) from calendar where sysdate > expiration_date"] > 0 } {

    append page_content "<li>To dig up information on an event that you missed, check 
    <a href=\"archives\">the archives</a>."    

}


append page_content "
</ul>
[calendar_footer]
"

doc_return  200 text/html $page_content

## END FILE one-category.tcl






