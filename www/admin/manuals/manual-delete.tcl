# /www/admin/manual/delete.tcl
ad_page_contract {
    Confirmation page for deleting a manual

    @param manual_id the ID of the manual to delete

    @author Ron Henderson (ron@arsdigita.com)
    @creation-date Feb 2000
    @cvs-id manual-delete.tcl,v 1.6.2.2 2000/07/21 03:57:34 ron Exp
} {
    manual_id:integer,notnull
}

# -----------------------------------------------------------------------------

db_1row manual_info "
select   m.title,
         count(s.section_id) as number_of_pages,
         count(f.figure_id) as number_of_figures
from     manuals m, manual_sections s, manual_figures f
where    m.manual_id = :manual_id
and      m.manual_id = s.manual_id(+)
and      m.manual_id = f.manual_id(+)
group by m.title"


doc_set_property title "Manuals: Delete"
doc_set_property navbar [list [list "index.tcl" "Manuals"] "Delete"]

doc_body_append "
<p> Are you sure that you want to <b>permanently delete</b> the manual
\"$title\" with $number_of_pages pages and $number_of_figures
figures?</p>

<form action=manual-delete-2 method=post>
[export_form_vars manual_id]
<center>
<input type=submit value=\"Yes, I want to delete it!\">
</center>
</form>

"
