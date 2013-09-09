# /www/curriculum/clickthrough.tcl

ad_page_contract {
    /www/curriculum/clickthrough.tcl 
    records the user's action in clicking on an element in the curriculum 
    bar
    
    updates the user's curriculum bar cookie and then redirects
    if the user is logged in, adds a row to the user_curriculum_map table
    
    @author Philip Greenspun (philg@mit.edu)
    @creation-date October 6, 1999
    @cvs-id clickthrough.tcl,v 3.1.6.4 2000/07/21 03:59:13 ron Exp
    @param curriculum_element_id The curriculum element id that we are going to.
} {
    curriculum_element_id
}

set destination_url [db_string get_curric_url "select url from curriculum where curriculum_element_id = :curriculum_element_id"]

set cookie [ns_set get [ns_conn headers] Cookie]
if { [regexp {CurriculumProgress=([^;]+)} $cookie {} input_cookie] } {
    set new_cookie_value [curriculum_progress_cookie_value $input_cookie $curriculum_element_id]
    ns_set put [ns_conn outputheaders] "Set-Cookie" "CurriculumProgress=$new_cookie_value; path=/; expires=Fri, 01-Jan-2010 01:00:00 GMT"
}

set user_id [ad_get_user_id]

if { $user_id != 0 } {
    db_dml update_curric_map "insert into user_curriculum_map (user_id, curriculum_element_id, completion_date)
select :user_id, :curriculum_element_id, sysdate
from dual
where not exists (select 1 from user_curriculum_map 
                  where user_id = :user_id
                  and curriculum_element_id = :curriculum_element_id)"
}

ad_returnredirect $destination_url
