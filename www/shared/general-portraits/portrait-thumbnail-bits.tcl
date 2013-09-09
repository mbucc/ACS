# /www/shared/general-portraits/portrait-bits-thumbnail.tcl

ad_page_contract {
    Return a thumbnail picture

    @author minhngo@cory.eecs.berkeley.edu
    @creation-date 7/26/2000
    @cvs-id portrait-thumbnail-bits.tcl,v 1.1.2.3 2000/09/10 19:31:18 kevin Exp
} {
    portrait_id:naturalnum
}

# spits out correctly MIME-typed bits for a user's portrait

set file_type [db_string file_type_get "
select portrait_file_type
from general_portraits
where portrait_id = :portrait_id"]

if [empty_string_p $file_type] {
    ad_return_error "Couldn't find portrait" "Couldn't find a portrait for User $user_id"
    return
}

ReturnHeaders $file_type
db_write_blob return_file "select portrait_thumbnail from general_portraits where portrait_id = :portrait_id"
db_release_unused_handles

