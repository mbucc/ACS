# /admin/bookmarks/index.tcl
#
# administration index page for the bookmarks system
#
# by aure@arsdigita.com and dh@arsdigita.com, June 1999
#
# $Id: index.tcl,v 3.0.4.1 2000/03/15 20:46:56 aure Exp $


set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set title "Bookmarks System Administration"

set db [ns_db gethandle]

set page_content "
[ad_admin_header $title ]

<h2> $title </h2>

[ad_admin_context_bar  $title]

<hr>

<ul>"


# get all the users and their total number of bookmarks.
set selection [ns_db select $db "
    select  first_names||' '||last_name as name,  
            owner_id, 
            count(bookmark_id) as number_of_bookmarks
    from    bm_list, users
    where   owner_id=user_id
    group by first_names, last_name, owner_id
    order by last_name"]    

set user_count 0
set user_list ""
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr user_count            
    append user_list "<li><a href=one-user?[export_url_vars owner_id] >
    $name</a>- $number_of_bookmarks  bookmarks
    <br>"
}

append page_content "
<li><a href=most-popular> List of the most popular hosts and bookmarks</a>
<p>
<li><a href=get-site-info> Check to see if sites are live and if so, get title and meta tags</a>
<p>"

if {$user_count>0} {

    append page_content "
    <li>Choose a user whose bookmarks you would like to view and optionally delete:
    <ul>
    $user_list
    </ul>"

} else {

    append page_content "<li>There are no users in this bookmark system"

}

append page_content "</ul>[ad_admin_footer]"

# release the database handle
ns_db releasehandle $db

# serve the page
ns_return 200 text/html $page_content    




