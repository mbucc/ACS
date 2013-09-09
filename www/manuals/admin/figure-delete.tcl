# /www/manual/admin/figure-delete.tcl
ad_page_contract {
    Confirmation page to delete a figure

    @param figure_id the ID of the figure to delete

    @author Kevin Scaldeferri (kevin@caltech.edu)
    @creation-date Feb 2000
    @cvs-id figure-delete.tcl,v 1.4.2.3 2000/07/25 09:20:18 ron Exp
} {
    figure_id:integer,notnull
}

# -----------------------------------------------------------------------------

# Verify the editor

db_1row manual_info "
select m.title,
       m.manual_id
from   manuals m, manual_figures f
where  f.figure_id = :figure_id
and    f.manual_id = m.manual_id"

page_validation {
    if {![ad_permission_p "manuals" $manual_id]} {
	error "<li>You are not authorized to edit this manual"
    }
}

# -----------------------------------------------------------------------------

doc_set_property title "Delete Figure"
doc_set_property navbar [list \
	[list "/manuals" "Manuals"] \
	[list "index.tcl" "Admin"] \
	[list "manual-view.tcl?manual_id=$manual_id" "$title"] \
	[list "figures.tcl?manual_id=$manual_id" "Figures"] \
	"Delete Figure"]

doc_body_append "

<p>Please confirm that you want to <b>permanently delete</b> this figure.</p> 

<center>
<form action=figure-delete-2 method=post>
[export_form_vars figure_id]
<input type=submit value=\"Yes, I want to delete it!\">
</form>
</center>

"
