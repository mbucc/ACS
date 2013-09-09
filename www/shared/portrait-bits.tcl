# /www/shared/portrait-bits.tcl

ad_page_contract {
    Return a portrait

    @author minhngo@cory
    @creation-date 7/31/2000
    @cvs-id portrait-bits.tcl,v 3.2.10.4 2000/09/09 20:59:26 kevin Exp
} {
    {user_id:naturalnum ""}
    {portrait_id:naturalnum ""}
}

# need to specify user_id or portrait_id
if {[empty_string_p $user_id] && [empty_string_p $portrait_id]} {
   ad_return_error "No ID specify" "Cannot leave user_id and portrait_id empty"
   return
}
# spits out correctly MIME-typed bits for a user's portrait

# if portrait_id is not given, retrieve it
set file_type ""
if {[empty_string_p $portrait_id]} {
   db_0or1row file_type_get "
      select portrait_file_type as file_type,
	     portrait_id
        from general_portraits
       where on_what_id = :user_id
	 and upper(on_which_table) = 'USERS'
	 and approved_p = 't'
	 and portrait_primary_p = 't'
   "
} else {
   set file_type [db_string file_type_get "
      select portrait_file_type
        from general_portraits
       where portrait_id = :portrait_id"]
}

if [empty_string_p $file_type] {
    ad_return_error "Couldn't find portrait" "Couldn't find a portrait for User $user_id"
    return
}

ReturnHeaders $file_type

db_write_blob return_file "select portrait from general_portraits where portrait_id = $portrait_id" 
db_release_unused_handles

