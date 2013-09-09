# /www/manuals/admin/figure-add-2.tcl
ad_page_contract {
    Receive and process figure info

    @param manual_id the ID of the manual we are adding to
    @param label a short name for referencing
    @param caption the caption for the figure
    @param file_name the uploaded file
    @param numbered_p does the figure get a number?

    @author Kevin Scaldeferri (kevin@caltech.edu)
    @creation-date Jan 2000
    @cvs-id figure-add-2.tcl,v 1.3.2.5 2000/07/25 05:04:15 kevin Exp
} {
    manual_id:integer,notnull
    label:trim,notnull
    {caption ""}
    file_name:trim,notnull
    file_name.tmpfile:tmpfile
    numbered_p
}


# -----------------------------------------------------------------------------

# Verify the editor

page_validation {
    if {![ad_permission_p "manuals" $manual_id]} {
	error "You are not authorized to edit this manual"
    }

    if {[file size ${file_name.tmpfile}] == 0 } {
	error "The file you specified is either empty or invalid."
    }
    
}

# -----------------------------------------------------------------------------
# Error Checking

page_validation {

    set ext [string tolower [file extension $file_name]]
    if {[lsearch -exact [list .jpg .jpeg .gif] $ext] == -1} {
	error "$file_name doesn't look like an image file."
    }

    # Check to make sure the label will be unique for this manual

    set label_conflict_p [db_string label_conflict "
    select count(*)
    from   manual_figures
    where  manual_id = :manual_id
    and    label like :label"]

    if {$label_conflict_p} {
	error "Your label is already being used by another figure in this manual"
    }
}

# -----------------------------------------------------------------------------

set figure_id [db_string next_figure_id "
select manual_figure_id_sequence.nextval from dual"]

set tmpfile    ${file_name.tmpfile}
set image_type [ns_guesstype $file_name]
set image_dir  [ns_info pageroot]/manuals/figures

switch $image_type {
    "image/gif" {
	set image_file "$image_dir/${manual_id}.${figure_id}.gif"
	set image_size [ns_gifsize $tmpfile]
    }

    "image/jpeg" -
    "image/jpg"  {
	set image_file "$image_dir/${manual_id}.${figure_id}.jpg"
	set image_size [ns_jpegsize $tmpfile]

	# Watch out for a claimed bug in jpegsize
	if { [lindex $image_size 0] < 10 && [lindex $image_size 1] < 10 } {
	    set image_size [list "" ""]
	}
    }

    # Don't need a default because we already verified the image type above
}

# Copy the uploaded file to the correct location

ns_cp $tmpfile $image_file

# If the figure is numbered then compute the sort_key, othewise just
# set the sort_key to zero.

if {$numbered_p == "t"} {
    set sort_key [db_string sort_key "
    select decode(sign(max(sort_key)),1,max(sort_key)+1,1) as sort_key 
    from   manual_figures 
    where  manual_id = :manual_id"]
} else {
    set sort_key 0
}

# Insert an entry into the figures database for this figure

db_dml figure_insert "
insert into manual_figures
( figure_id,
  manual_id,
  label,
  caption,
  file_type,
  sort_key,
  numbered_p,
  width,
  height
)
values
( :figure_id,
  :manual_id,
  :label,
  :caption,
  :image_type,
  :sort_key,
  :numbered_p,
  [lindex $image_size 0],
  [lindex $image_size 1])"

db_release_unused_handles

# Redirect to the main figures page

ad_returnredirect "figures.tcl?manual_id=$manual_id"
