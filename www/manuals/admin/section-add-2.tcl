# /www/manuals/admin/section-add-2.tcl
ad_page_contract {
    Process the add a new section page

    @param manual_id the ID of the manual we are adding to 
    @param parent_key the sort key of the parent to this section
    @param section_title the title of the new section
    @param label a short name for referencing
    @param file_name the name of a content file being uploaded

    @author Kevin Scaldeferri (kevin@caltech.edu)
    @creation-date Nov 1999
    @cvs-id section-add-2.tcl,v 1.5.2.4 2000/07/21 04:02:52 ron Exp
} {
    manual_id:integer,notnull
    {parent_key ""}
    section_title:trim,notnull
    {label:trim ""}
    {file_name ""}
    {file_name.tmpfile:tmpfile ""}
}

# -----------------------------------------------------------------------------

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

# Verify the editor

page_validation {
    if {![ad_permission_p "manuals" $manual_id]} {
	error "You are not authorized to edit this manual"
    }
}


# -----------------------------------------------------------------------------

# Get the sort_key for the parent of this page

if [empty_string_p $parent_key] {
    # we're adding a top-level section for the manual, so get the
    # current maximum sort key

    set max_sort_key [db_string max_sort_key "
    select max(sort_key)
    from   manual_sections
    where  manual_id = :manual_id
    and    length(sort_key) = 2"]

    # Next sort key is either 00 or 1 + the current maximum sort key.
    # Note that we have to trim leading 0's so that expr doesn't treat
    # our sort key as an octal number.

    if [empty_string_p $max_sort_key] {
	set next_sort_key "00"
    } else {
	set key_length    [string length $max_sort_key]
	set next_sort_key [format "%0${key_length}d" [expr [string trimleft $max_sort_key 0]+1]]
    }
} else {
    # we're adding a subsection, so grab the maximum sort key among
    # all the children for this parent

    set parent_key_base "${parent_key}__"

    set max_sort_key [db_string max_sort_key_from_parent "
    select max(sort_key)
    from   manual_sections
    where  manual_id = :manual_id
    and    sort_key like :parent_key_base
    and    active_p = 't'"]

    if [empty_string_p $max_sort_key] {
	# parent has no children - this is the first one
	set next_sort_key "${parent_key}00"
    } else {
	# new key will be the same length
	set key_length [string length $max_sort_key]

	# make sure that adding a new child won't overflow the keys

	set max_sort_key [string trimleft $max_sort_key 0]
	if {[expr $max_sort_key % 100]==99} {
	    ad_return_complaint 1 "<li>You cannot have more than 100 subsections in any section."
	    return
	} else {
	    set next_sort_key [format "%0${key_length}d" [expr $max_sort_key+1]]
	}
    }
}

# Insert this section into the database (as long as we like it)

set section_id [db_string next_section_id "
select manual_section_id_sequence.nextval from dual"]

# If they uploaded a file, then we need to add it to the content area
# and (optionally) register it under version control.   

if [exists_and_not_null file_name] {

    set content_p "t"

    # Generate a local filename for the content and copy it over
    set local_filename [ns_info pageroot]/manuals/sections/${manual_id}.${section_id}.html

    # Read the uploaded content and write it back out to the local
    # file

    set in [open ${file_name.tmpfile}]
    set content [read $in]
    close $in

    # Quite probably their file has all sorts of head tags and the like
    # which will only cause trouble

    regexp {<body>(.*)</body>} $content match body

    if [exists_and_not_null body] {
	set content $body
    }

    set    out [open $local_filename w]
    puts  $out $content
    close $out

    # Register the file for version control

    if [ad_parameter UseCvsP manuals]  {
	# Get the user's email address and name for the log entry
  
	db_1row user_info "
	select email, 
	       first_names || ' ' || last_name as full_name 
	from   users 
	where  user_id = :user_id"

	set msg  "Initial version added by $full_name ($email)"

	vc_add $local_filename
	vc_commit $local_filename $msg

    }

    # Now check the file and make sure it doesn't violate our content rules.
    # if it does, we don't add it to the database yet, but instead send
    # them off to fix it first.

    set exception_text [manual_check_content $manual_id $content]

    if ![empty_string_p $exception_text] {
	doc_set_property title "Problems with your file"
	doc_set_property navbar [list]

	doc_body_append "

	There are some problems with your file which you should correct 
	<a href=content-edit?[export_url_vars manual_id section_id]&new=t&new_list=[ns_urlencode [join [list $section_title $label $next_sort_key] ","]]>here</a>:

	<ul>
	$exception_text
	</ul>

	"

	return
    }

} else {
    set content_p "f"
}

db_dml section_insert "
insert into manual_sections
 ( section_id,
   manual_id,
   section_title,
   label,
   sort_key,
   creator_id,
   content_p)
values
 (:section_id,
  :manual_id,
  :section_title,
  :label,
  :next_sort_key,
  :user_id,
  :content_p
)"

ad_returnredirect "manual-view.tcl?manual_id=$manual_id"



