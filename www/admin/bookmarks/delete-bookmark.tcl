# /www/admin/bookmarks/delete-bookmark.tcl

ad_page_contract {
    admin version
    the delete utility of the bookmarks system
    @param bookmark_id ID of bookmark to be deleted
    @author David Hill (dh@arsdigita.com)
    @author Aurelius Prochazka (aure@arsdigita.com)    
    @creation-date June 1999  
    @cvs-id delete-bookmark.tcl,v 3.2.2.4 2000/09/22 01:34:23 kevin Exp
} {
    {bookmark_id:integer}
} 

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
# get local_title and folder_p
db_1row bm_info "
          select local_title, 
                        folder_p, 
                 first_names||' '||last_name as owner_name, 
                 owner_id  
          from   bm_list, users 
          where  bookmark_id = :bookmark_id
          and user_id = owner_id"

set title "Delete One"

set folder_html "
[ad_admin_header $title ]
<h2> $title </h2>
[ad_admin_context_bar [list index.tcl Bookmarks] [list one-user.tcl?[export_url_vars owner_id] $owner_name's] [list edit-bookmark.tcl?[export_url_vars bookmark_id] Edit] $title]
<hr>
"

if {$folder_p=="t"} { 
    
    set number_to_delete [db_string bm_count "select count(*)
                                              from   bm_list
                                              connect by prior bookmark_id=parent_id
                                              start with parent_id = :bookmark_id "]
    
    append folder_html " 
    Removing this folder will result in deleting $number_to_delete subfolders and/or bookmarks. <p>"
}
 
# release the database handle
db_release_unused_handles 

append folder_html "Are you sure you want to delete \"$local_title\"?<P>"

append folder_html " 
    <form action=delete-bookmark-2 method=post >
    <input type=submit value=\"Yes, Delete!\" >
    [export_form_vars bookmark_id] 
    </form>
    [ad_admin_footer]
    "

# --serve the page --------------------------
doc_return  200 text/html $folder_html







