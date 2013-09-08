# /www/press/archives.tcl

ad_page_contract {

    Display expired press items

    @author  Ron Henderson (ron@arsdigita.com)
    @created Dec 1999
    @cvs-id  archives.tcl,v 1.1.2.2 2000/09/22 01:39:05 kevin Exp
} {
    {start:integer "0"}
}

set page_content "
[ad_header "Press Archives"]

<h2>Press Archives</h2>

[ad_context_bar_ws_or_index [list "" "Press"] "Archives"]

<hr>
"

# Check for a user_id but don't force registration.  People should be
# able to view the press coverage without being registered.

set user_id [ad_verify_and_get_user_id]

# Grab the press coverage viewable by this person.  We use a pager
# system for display the press items, showing no more than display_max
# items on a page with links to "previous" and "next" if appropriate. 

set count -1
set display_max [press_display_max]
set active_days [press_active_days]

db_foreach press_items {
    select press_id,
           publication_name,
           publication_link,
           publication_date,
           publication_date_desc,
           article_title,
           article_link,
           article_pages,
           abstract,
           important_p,
           template_adp
    from   press p, press_templates t
    where  p.template_id = t.template_id
    and    (important_p = 'f' and (sysdate-publication_date > :active_days))
    and    (scope = 'public' or
           (scope = 'group' and 't' = ad_group_member_p(:user_id,p.group_id)))
    order by publication_date desc
} {
    incr count

    if { $count < $start } {
	# skip over the initial items
	continue
    }

    if { [expr $count - $start] == $display_max } {
	# set the "more items" flag and throw away the rest of the cursor
	set more_items_p 1
	break
    }
    
    if {![empty_string_p $publication_date_desc]} {
	set display_date $publication_date_desc
    } else {
	set display_date [util_AnsiDatetoPrettyDate $publication_date]
    }
    
    append page_content "
    <p><blockquote>
    [press_coverage \
	    $publication_name [ns_urlencode $publication_link] $display_date \
	    $article_title [ns_urlencode $article_link] $article_pages $abstract \
	    $template_adp ]
    </blockquote></p>"
} if_no_rows {
    append page_content "
    <p>There is no press coverage currently available for you to see.</p>"
}

# Set the up optional navigation links 

proc max {x y} {
    return [expr $x > $y ? $x : $y]
}

set nav_links [list]

if { $start > 0 } {
    lappend nav_links "<a href=?start=[max 0 [expr $start-$display_max]]>prev</a>"
}

if [info exists more_items_p] {
    lappend nav_links "<a href=?start=[expr $start + $display_max]>next</a>"
}

append page_content "
<p align=center>[join $nav_links " | "]</p>

[ad_footer]"

doc_return  200 text/html $page_content

