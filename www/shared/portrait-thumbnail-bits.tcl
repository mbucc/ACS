# $Id: portrait-thumbnail-bits.tcl,v 3.1 2000/03/10 03:00:04 mbryzek Exp $
#
# /shared/portrait-thumbnail-bits.tcl
# 
# by philg@mit.edu on September 26, 1999
# 
# spits out correctly MIME-typed bits for a user's portrait (thumbnail version)
# 

set_form_variables

# user_id

set db [ns_db gethandle]

set column portrait_thumbnail

set file_type [database_to_tcl_string_or_null $db "select portrait_file_type
from users
where user_id = $user_id
and portrait_thumbnail is not null"]

if { [empty_string_p $file_type] } {
    # Try to get a regular portrait
    set file_type [database_to_tcl_string_or_null $db "select portrait_file_type
from users
where user_id = $user_id"]
    if [empty_string_p $file_type] {
	ad_return_error "Couldn't find thumbnail or portrait" "Couldn't find a thumbnail or a portrait for User $user_id"
	return
    }
    set column portrait
}

ReturnHeaders $file_type

ns_ora write_blob $db "select $column
from users
where user_id = $user_id"
    
