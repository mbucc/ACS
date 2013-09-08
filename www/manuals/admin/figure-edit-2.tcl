# /www/manual/admin/figure-edit-2.tcl
ad_page_contract {
    Receive and process the new figure/caption

    @param manual_id the ID of the manual
    @param figure_if the ID of the figure being edited
    @param label a short name for referencing
    @param caption a caption for the figure
    @param file_name the name of the file being uploaded
    @param numbered_p whether the figure is numbered

    @author Kevin Scaldeferri (kevin@caltech.edu)
    @creation-date Feb 2000
    @cvs-id figure-edit-2.tcl,v 1.3.2.4 2000/07/25 09:20:18 ron Exp
} {
    manual_id:integer,notnull
    figure_id:integer,notnull
    label:trim,notnull
    {caption ""}
    file_name
    file_name.tmpfile:tmpfile
    numbered_p
}

# -----------------------------------------------------------------------------

# Verify the editor

page_validation {
    if {![ad_permission_p "manuals" $manual_id]} {
	error "You are not authorized to edit this manual"
    }
}

# -----------------------------------------------------------------------------
# Error Checking

page_validation {
    if ![empty_string_p $file_name] {
	set ext [string tolower [file extension $file_name]]
	if {[lsearch -exact [list .jpg .jpeg .gif] $ext] == -1} {
	    error "$file_name doesn't look like an image file."
	}
    }
}

# -----------------------------------------------------------------------------

# These items will always be updated

set dml "
update manual_figures 
set    label      = :label, 
       caption    = :caption,
       numbered_p = :numbered_p"

# Modify sort_key appropriately
# this isn't done with a trigger because it requires
# a somewhat ugly sequence of triggers

db_transaction {

    set old_numbered_p [db_string numbered_p "
    select numbered_p from manual_figures
    where figure_id = :figure_id"]

    if { $old_numbered_p == "f" && $numbered_p == "t" } {
	append dml ",
	sort_key = (select decode(sign(max(sort_key)),1,max(sort_key)+1,1)
	from manual_figures where manual_id = :manual_id)"
    } elseif { $old_numbered_p == "t" && $numbered_p == "f" } {
	append dml ",
	sort_key = 0"
	db_dml figure_update_sort_keys "
	update manual_figures
	set sort_key = sort_key - 1
	where manual_id = :manual_id
	and sort_key > (select sort_key from manual_figures
	where figure_id = :figure_id)"
    }


    # Are we uploading a new file?

    if ![empty_string_p $file_name] {

	set image_file [ns_info pageroot][manual_get_image_file $figure_id]
	set tmpfile    ${file_name.tmpfile}
	ns_cp $tmpfile $image_file

	# Guess the MIME type of the file and compute the width/height of
	# the uploaded image
	set file_type [ns_guesstype $file_name]

	switch $file_type {
	    "image/gif" {
		set image_size [ns_gifsize $image_file]
	    }

	    "image/jpeg" -
	    "image/jpg" {
		set image_size [ns_jpegsize $image_file]

		# Watch out for a claimed bug in jpegsize
		if { [lindex $image_size 0] < 10 && [lindex $image_size 1] < 10 } {
		    set image_size [list "" ""]
		}
	    }

	    default {
		set image_size [list "" ""]
	    }
	}

	append dml ",
	file_type = :file_type,
	width     = [lindex $image_size 0],
	height    = [lindex $image_size 1]"
    }

    append dml " where figure_id = :figure_id"

    db_dml update_figure $dml
}

# redirect to the figures page

ad_returnredirect "figures.tcl?[export_url_vars manual_id figure_id]"




