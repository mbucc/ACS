# user-identification-edit.tcl

ad_page_contract { 
    @param user_identification_id
    @param first_names
    @param last_name
    @param email
    @param postal_code
    @param other_id_info

    @author
    @creation-date
    @cvs-id user-identification-edit.tcl,v 3.1.6.3 2000/07/21 03:56:59 ron Exp
} {
    user_identification_id
    first_names
    last_name
    email
    postal_code
    other_id_info
}



db_dml unused "update ec_user_identification
set first_names=:first_names,
last_name=:last_name,
email=:email,
postal_code=:postal_code,
other_id_info=:other_id_info
where user_identification_id=:user_identification_id"
db_release_unused_handles

ad_returnredirect "user-identification.tcl?[export_url_vars user_identification_id]"

