# $Id: delete-bookmark.tcl,v 3.0.4.1 2000/03/17 17:40:38 aure Exp $
# delete-bookmark.tcl
#
# the delete utility of the bookmarks system
#
# by dh@arsdigita.com and aure@arsdigita.com

set_the_usual_form_variables 

# bookmark_id, return_url

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set db [ns_db gethandle]

# start error-checking
set exception_text ""
set exception_count 0

if {(![info exists bookmark_id])||([empty_string_p $bookmark_id])} {
    incr exception_count
    append exception_text "<li>No bookmark was specified"
}

# make sure that the user owns the bookmark
set  ownership_query "
        select count(*)
        from   bm_list
        where  owner_id=$user_id
        and bookmark_id=$bookmark_id"
set ownership_test [database_to_tcl_string $db $ownership_query]

if {$ownership_test==0} {
    incr exception_count
    append exception_text "<li>You can not edit this bookmark"
}

# return errors
if { $exception_count> 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

set local_title [database_to_tcl_string $db "select local_title from bm_list where bookmark_id=$bookmark_id"]

set title "Delete \"$local_title\""

set whole_page "
[ad_header $title ]
<h2> $title </h2>
[ad_context_bar_ws [list $return_url [ad_parameter SystemName bm]] [list edit-bookmark.tcl?[export_url_vars bookmark_id] Edit Bookmark] "Delete"]
<hr>
"

set folder_p [database_to_tcl_string $db "select folder_p from bm_list where bookmark_id = $bookmark_id"]

if {$folder_p=="t"} { 
    
    set count_query "
    select count(*)
    from   bm_list
    connect by prior bookmark_id=parent_id
    start with parent_id = $bookmark_id
    "
    
    set number_to_delete [database_to_tcl_string $db $count_query]
    
    append whole_page " 
    Removing this folder will result in deleting $number_to_delete subfolders and/or bookmarks. <p>"
}

append whole_page "Are you sure you want to delete \"$local_title\"?<P>"


append whole_page " 
    <form action=delete-bookmark-2 method=post >
     <center>
     <input type=submit value=\"Yes, Delete!\" >
     </center>
     [export_form_vars bookmark_id return_url] 
    </form>
    [bm_footer]
    "

ns_return 200 text/html $whole_page











