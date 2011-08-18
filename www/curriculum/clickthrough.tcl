# $Id: clickthrough.tcl,v 3.0.4.1 2000/04/28 15:09:54 carsten Exp $
#
# /www/curriculum/clickthrough.tcl 
#
# by philg@mit.edu on October 6, 1999
#
# records the user's action in clicking on an element in the curriculum 
# bar
# 
# updates the user's curriculum bar cookie and then redirects
# if the user is logged in, adds a row to the user_curriculum_map table

set_the_usual_form_variables

# curriculum_element_id

set db [ns_db gethandle]

set destination_url [database_to_tcl_string $db "select url from curriculum where curriculum_element_id = $curriculum_element_id"]

set cookie [ns_set get [ns_conn headers] Cookie]
if { [regexp {CurriculumProgress=([^;]+)} $cookie {} input_cookie] } {
    set new_cookie_value [curriculum_progress_cookie_value $input_cookie $curriculum_element_id]
    ns_set put [ns_conn outputheaders] "Set-Cookie" "CurriculumProgress=$new_cookie_value; path=/; expires=Fri, 01-Jan-2010 01:00:00 GMT"
}

set user_id [ad_get_user_id]

if { $user_id != 0 } {
    ns_db dml $db "insert into user_curriculum_map (user_id, curriculum_element_id, completion_date)
select $user_id, $curriculum_element_id, sysdate
from dual
where not exists (select 1 from user_curriculum_map 
                  where user_id = $user_id
                  and curriculum_element_id = $curriculum_element_id)"
}

ad_returnredirect $destination_url
