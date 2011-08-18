#
# /admin/survsimp/survey-toggle.tcl
#
# by raj@alum.mit.edu, February 9, 2000
#
# toggle(enable/disable) a single survey
# 

ad_page_variables {
    survey_id 
    enabled_p
}

set db [ns_db gethandle]

if {$enabled_p == "f"} {
    set enabled_p "t"
} else {
    set enabled_p "f"
}

ns_db dml $db "
    update survsimp_surveys 
    set enabled_p = '$enabled_p' 
    where survey_id = $survey_id"

ns_db releasehandle $db

ad_returnredirect ""
