# /www/admin/bookmarks/index.tcl

ad_page_contract {
    administration index page for the bookmarks system
    @author David Hill (dh@arsdigita.com)
    @author Aurelius Prochazka (aure@arsdigita.com)
    @creation-date June 1999  
    @cvs-id index.tcl,v 3.2.2.4 2000/09/22 01:34:24 kevin Exp
} {} 

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set title "Bookmarks System Administration"

set page_content "
[ad_admin_header $title ]

<h2> $title </h2>

[ad_admin_context_bar  $title]

<hr>

<ul>"

# get all the users and their total number of bookmarks.
set user_count 0
set user_list ""

db_foreach bookmark {
    select  first_names||' '||last_name as name,  
            owner_id, 
            count(bookmark_id) as number_of_bookmarks
    from    bm_list, users
    where   owner_id = user_id
    group by first_names, last_name, owner_id
    order by last_name
} {
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

if { $user_count>0 } {

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
db_release_unused_handles

# serve the page
doc_return  200 text/html $page_content    

