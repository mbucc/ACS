# /wp/users.tcl

ad_page_contract {

    Displays a list of all users and the number of presentations they have.

    @creation-date  18 Nov 1999
    @author  Jon Salz <jsalz@mit.edu>
    @param starts_with is a string for user name search
    @param bulk_copy
    @cvs-id users.tcl,v 3.2.6.10 2000/09/22 01:39:37 kevin Exp
} {
    starts_with:html,optional
    bulk_copy:naturalnum,optional
}

if { [info exists starts_with] } {
    set pretty_starts_with "[string toupper [string range $starts_with 0 0]][string tolower [string range $starts_with 1 end]]"
    set title "Authors ($pretty_starts_with)"
    set condition "and lower(u.last_name) like '[string tolower $starts_with]%'"
} else {
    set title "All Authors"
    set condition ""
}

set page_output "[wp_header [list "?[export_ns_set_vars url starts_with]" "WimpyPoint"] $title]

Select an author from this list of users who have created presentations
(number of slides created shown in parentheses):

<ul> "

set out ""

set seen_real_user_p 0
set written_fake_user_heading_p 0

db_foreach users_select "
    select u.user_id, u.last_name, u.first_names, u.email, sum(v.n_slides) n_slides,
           wp_real_user_p(sum(v.n_slides)) real_user_p
    from
    (
        -- slide count for presentations that the user owns
        select wp.creation_user user_id, count(ws.slide_id) n_slides
        from   wp_presentations wp, wp_slides ws
        where  wp.public_p = 't'
        and    ws.max_checkpoint is null
        and    wp.presentation_id = ws.presentation_id(+)
        group by wp.creation_user
      union
        -- slide count for presentations that the user is a collaborator on but doesn't own
        select m.user_id user_id, count(ws.slide_id) n_slides
        from   wp_presentations wp, wp_slides ws, user_group_map m
        where  wp.group_id = m.group_id
        and    wp.public_p = 't'
        and    wp.presentation_id = ws.presentation_id(+)
        and    m.role in ('write','admin')
        and    m.user_id <> wp.creation_user
        group by m.user_id
    ) v, users u
    where u.user_id = v.user_id
    group by u.user_id, u.last_name, u.first_names, u.email
    having sum(v.n_slides) > 0 $condition
    order by 6 desc, upper(u.last_name), upper(u.first_names)
" {
    if { !$seen_real_user_p && $real_user_p == "t" } {
	set seen_real_user_p 1
    }
    if { $real_user_p == "f" && $seen_real_user_p && !$written_fake_user_heading_p } {
	set written_fake_user_heading_p 1
	append out "<h4>users with only a handful of slides</h4>\n"
    }
    if { [info exists bulk_copy] } {
	set href "one-user.tcl?user_id=$user_id&bulk_copy=$bulk_copy"
    } else {
	set href "one-user.tcl?user_id=$user_id"
    }
    append out "<li><a href=\"$href\">$last_name, $first_names</a>,  $email ($n_slides)\n"
} if_no_rows {
    append out "<li>There are no authors"
    if { [info exists starts_with] } {
	append out " with last names starting with $pretty_starts_with"
    }
    append out ".\n"
}

db_release_unused_handles

append page_output "$out
</ul>

Note: this is not a complete list of the users.
Users who are collaborators on
presentations owned by others are excluded.  Users who have created
only private presentations are excluded.

[wp_footer]
"

doc_return  200 "text/html" $page_output
