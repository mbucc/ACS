# /www/admin/manuals/index.tcl
ad_page_contract {
    Presents a list of all the manuals and gives the option to add a new
    manual.

    @author Kevin Scaldeferri (kevin@caltech.edu)
    @creation-date Jan 2000
    @cvs-id index.tcl,v 1.6.2.2 2000/07/21 03:57:33 ron Exp
} {}

# -----------------------------------------------------------------------------

db_foreach all_manual "
select   m.manual_id,
         m.title,
         (select count(*) from manual_sections s
            where m.manual_id = s.manual_id) as number_of_pages,
         (select count(*) from manual_figures f
            where m.manual_id = f.manual_id) as number_of_figures
from     manuals m
order by m.title" {

    append manual_list "
    <li><a href=manual-edit?manual_id=$manual_id>$title</a> 
    ($number_of_pages pages, $number_of_figures figures)\n"

} if_no_rows {
    set manual_list "There are no manuals in the database."
}

db_release_unused_handles

# -----------------------------------------------------------------------------

doc_set_property title "Admin: Manuals"
doc_set_property navbar [list "Manuals"]

doc_body_append "

Documentation: <a href=/doc/manuals>/doc/manuals.html</a><br>
User pages: <a href=/manuals/>/manuals</a>

<p>

<ul>
$manual_list

<p>
<li><a href=manual-add>Add a new manual</a>
</ul>
"







