# $Id: delete-bookmark.tcl,v 3.0 2000/02/06 03:08:35 ron Exp $
# delete-bookmark.tcl
# admin version
#
# the delete utility of the bookmarks system
#
# by dh@arsdigita.com and aure@arsdigita.com

set_the_usual_form_variables 
# bookmark_id



# -- error-checking ------------------------------------
set exception_text ""
set exception_count 0

if {(![info exists bookmark_id])||([empty_string_p $bookmark_id])} {
    incr exception_count
    append exception_text "<li>No bookmark was specified"
}

# return errors
if { $exception_count> 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

# ---------------------------------------------------------

set db [ns_db gethandle]

# get local_title and folder_p
set selection  [ns_db 1row $db "select local_title, folder_p, first_names||' '||last_name as owner_name, owner_id  from bm_list,users where bookmark_id=$bookmark_id
and user_id = owner_id"]
set_variables_after_query

set title "Delete One"

set folder_html "
[ad_admin_header $title ]
<h2> $title </h2>
[ad_admin_context_bar [list index.tcl Bookmarks] [list one-user.tcl?[export_url_vars owner_id] $owner_name's] [list edit-bookmark.tcl?[export_url_vars bookmark_id] Edit] $title]
<hr>
"



if {$folder_p=="t"} { 
    
    set number_to_delete [database_to_tcl_string $db "select count(*)
    from   bm_list
    connect by prior bookmark_id=parent_id
    start with parent_id=$bookmark_id "]
    
    append folder_html " 
    Removing this folder will result in deleting $number_to_delete subfolders and/or bookmarks. <p>"
}

append folder_html "Are you sure you want to delete \"$local_title\"?<P>"


append folder_html " 
    <form action=delete-bookmark-2.tcl method=post >
    <input type=submit value=\"Yes, Delete!\" >
    [export_form_vars bookmark_id] 
    </form>
    [ad_admin_footer]
    "


# --serve the page --------------------------
ns_return 200 text/html $folder_html











