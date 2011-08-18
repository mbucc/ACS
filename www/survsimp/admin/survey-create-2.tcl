#
# /survsimp/admin/survey-create-2.tcl
#
# by philg@mit.edu, February 9, 2000
#
# actually does the insert
# 
#$Id: survey-create-2.tcl,v 1.2.2.3 2000/04/28 15:11:34 carsten Exp $
#

ad_page_variables {name description short_name survey_id} 

set db [ns_db gethandle]

set exception_count 0
set exception_text ""

if { [empty_string_p $short_name] } {
    incr exception_count
    append exception_text "<li>You didn't enter a short name for this survey.\n"
} else {
    # make sure the short name isn't used somewhere else

    set short_name_used_p [database_to_tcl_string $db "select
      count(short_name) from survsimp_surveys where lower(short_name) =
      '[string tolower $QQshort_name]'"]

    if {$short_name_used_p > 0} {
	incr exception_count
	append exception_text "<li>This short name, $short_name, is already in use.\n"
    }
}

if { [empty_string_p $name] } {
    incr exception_count
    append exception_text "<li>You didn't enter a name for this survey.\n"
}

if { [empty_string_p $description] } {
    incr exception_count
    append exception_text "<li>You didn't enter a description for this survey.\n"
}

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}

set user_id [ad_verify_and_get_user_id]

# make sure the short_name is unique

ns_db dml $db "insert into survsimp_surveys
(survey_id, name, short_name, description, creation_user)
values
($survey_id, '$QQname', '$QQshort_name', '$QQdescription', $user_id)"

ad_returnredirect "question-add.tcl?survey_id=$survey_id"
