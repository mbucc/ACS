# /press/index.tcl
# 
# Author: ron@arsdigita.com, December 1999
#
# Gateway for the press module
# 
# $Id: index.tcl,v 3.0 2000/02/06 03:53:13 ron Exp $
# -----------------------------------------------------------------------------

set page_title "Press"

# Check for a user_id but don't force registration.  People should be
# able to view the press coverage without being registered.

set user_id [ad_verify_and_get_user_id]

set db [ns_db gethandle]

# Provide administrators with a link to the local admin pages

if {[press_admin_any_group_p $db $user_id]} {
    # user is an admin for at least one group and therefore 
    # MIGHT want to administer some stuff
    set press_admin_notice [list "admin" "Administer"]
} else {
    set press_admin_notice ""
}

# Grab the press coverage viewable by this person

set selection [ns_db select $db "
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
and    (important_p = 't' or (sysdate-creation_date <= [press_active_days]))
and    (scope = 'public' or
        (scope = 'group' and 't' = ad_group_member_p($user_id,p.group_id)))
order by publication_date desc"]

set press_count 0
set press_list  ""
set display_max [press_display_max]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr press_count

    if { $press_count > $display_max } {
	# throw away the rest of the cursor
	ns_db flush $db
	break
    }

    if {![empty_string_p $publication_date_desc]} {
	set display_date $publication_date_desc
    } else {
	set display_date [util_AnsiDatetoPrettyDate $publication_date]
    }

    append press_list "
    <p><blockquote>
    [press_coverage \
	    $publication_name $publication_link $display_date \
	    $article_title $article_link $article_pages $abstract \
	    $template_adp ]
    </blockquote></p>"
}

ns_db releasehandle $db

if {$press_count == 0} {
    set press_list "<p>There is no press coverage currently available
    for you to see.</p>"
}

# -----------------------------------------------------------------------------
# Ship it out...

ns_return 200 text/html "
[ad_header "Press"]

<h2>Press</h2>

[ad_context_bar_ws_or_index "Press"]

<hr>
[help_upper_right_menu $press_admin_notice]

$press_list

[ad_footer]"



