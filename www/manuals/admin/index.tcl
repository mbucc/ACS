# /www/manuals/admin/index.tcl
ad_page_contract {
    Display the list of editable manuals

    @author Kevin Scaldeferri (kevin@caltech.edu)
    @author Ron Henderson (ron@arsdigita.com)
    @author Aure Prochazka (aure@arsdigita.com)
    @creation-date Feb 2000
    @cvs-id index.tcl,v 1.4.2.3 2000/07/21 04:02:51 ron Exp
} {}
   
# -----------------------------------------------------------------------------

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration


# get the list of manuals this users is authorized to edit

if [ad_administrator_p $user_id] {
    # this user is a site-wide administrator and can maintain any
    # manual
    set restrictions ""

    set site_wide_admin_link "
    <li>Site-wide admin directory: <a href=/admin/manuals/>/admin/manuals/</a>"
} else {
    # this user isn't a site-wide admin
    set restrictions "
    where manual_id in (select a.submodule
                        from   administration_info a,
                               user_group_map ugm
                        where  ugm.user_id  = :user_id
                        and    ugm.group_id = a.group_id)"

    set site_wide_admin_link ""
}

# Build the list of current manuals that this person can edit

set active_manual_list   [list]
set inactive_manual_list [list]

db_foreach allowed_manuals "
select m.manual_id,
       m.title,
       m.active_p,
       (select count(*) from manual_sections s
          where m.manual_id = s.manual_id) as number_of_pages,
       (select count(*) from manual_figures f
          where m.manual_id = f.manual_id) as number_of_figures
from   manuals m
$restrictions
order by m.title" {

    set item "<a href=manual-view?manual_id=$manual_id>$title</a> 
    ($number_of_pages pages, $number_of_figures figures)"

    if {$active_p == "t"} {
	lappend active_manual_list $item
    } else {
	lappend inactive_manual_list $item
    }
}

set page_content ""

if {[llength $active_manual_list] > 0} {
    append page_content "Active Manuals: <ul><li>[join $active_manual_list "\n<li>"]</ul>"
} else {
    append page_content "Active Manuals: <ul><li>None</li></ul>"
}

if {[llength $inactive_manual_list] > 0} {
    append page_content "Inactive Manuals: <ul><li>[join $inactive_manual_list "\n<li>"]</ul>"
}

# -----------------------------------------------------------------------------

doc_set_property title "Manual Administration"
doc_set_property navbar [list [list "../" [manual_system_name]] "Admin"]

doc_body_append "
<ul>
$site_wide_admin_link
<li>User pages: <a href=/manuals>/manuals/</a>
<li>Documentation: <a href=/doc/manuals>/doc/manuals.html</a>
</ul>

<p>You may edit content for the following:</p>

$page_content

"


