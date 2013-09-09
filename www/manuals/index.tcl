# /www/manuals/index.tcl
ad_page_contract {
    Display the list of manuals.  If ther is only one manual in the system,
    we redirect directly to its TOC.

    @author Kevin Scaldeferri (kevin@caltech.edu)
    @creation-date Jan 2000
    @cvs-id index.tcl,v 1.7.2.4 2000/07/21 04:02:42 ron Exp
} {}

# -----------------------------------------------------------------------------

set manual_list [list]

set no_manuals 0
db_foreach select_active "
select manual_id, title from manuals where active_p = 't'" {
    lappend manual_list "<a href=manual-view.tcl?manual_id=$manual_id>$title</a>"
} if_no_rows {
    lappend manual_list "No active manuals."
    set no_manuals 1
}

# if there is only one manual in the system, redirect
if {[llength $manual_list] == 1 && ! $no_manuals} {
    ad_returnredirect "manual-view.tcl?manual_id=$manual_id"
    return
}

db_release_unused_handles

# -----------------------------------------------------------------------------

doc_set_property title [manual_system_name]
doc_set_property navbar [list [manual_system_name]]

doc_body_append "

<ul>
<li>[join $manual_list "\n<li>"]
</ul>
"

