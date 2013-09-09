# /www/manual/admin/figure-delete-2.tcl
ad_page_contract {
    Process a \"delete figure\" request
    
    @param figure_id the ID of the figure to delete
    
    @author Ron Henderson (ron@arsdigita.com)
    @creation-date Feb 2000
    @cvs-id figure-delete-2.tcl,v 1.3.2.2 2000/07/21 04:02:48 ron Exp
} {
    figure_id:integer,notnull
}

# -----------------------------------------------------------------------------

# Verify the editor

db_1row manual_id "
select manual_id from manual_figures where figure_id = :figure_id"

page_validation {
    if {![ad_permission_p "manuals" $manual_id]} {
	error "You are not authorized to delete this figure"
    }
}

set image_file [manual_get_image_file $figure_id]

if [file exists $image_file] {
    exec rm $image_file
}

db_dml figure_delete "delete from manual_figures where figure_id = :figure_id"

ad_returnredirect "figures.tcl?manual_id=$manual_id"
