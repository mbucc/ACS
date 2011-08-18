# $Id: portrait-bits.tcl,v 3.2 2000/03/10 02:38:25 mbryzek Exp $
#
# /shared/portrait-bits.tcl
# 
# by philg@mit.edu on September 26, 1999
# 
# spits out correctly MIME-typed bits for a user's portrait
# 

set_form_variables

# user_id

set db [ns_db gethandle]

set file_type [database_to_tcl_string_or_null $db "select portrait_file_type
from users
where user_id = $user_id"]

if [empty_string_p $file_type] {
    ad_return_error "Couldn't find portrait" "Couldn't find a portrait for User $user_id"
    return
}

ReturnHeaders $file_type

ns_ora write_blob $db "select portrait
from users
where user_id = $user_id"
    

