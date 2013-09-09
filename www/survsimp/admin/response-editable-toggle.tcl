# /www/survsimp/admin/response-editable-toggle.tcl
ad_page_contract {

    Toggles a survey between allowing a user to
    edit to or not.

    @param  survey_id survey we're dealing with

    @author Jin Choi (jsc@arsdigita.com)
    @cvs-id response-editable-toggle.tcl,v 1.2.2.5 2000/07/21 04:04:21 ron Exp
} {

    survey_id:integer

}

db_dml survsimp_response_editable_toggle "update survsimp_surveys set single_editable_p = logical_negation(single_editable_p)
where survey_id = :survey_id"

db_release_unused_handles
ad_returnredirect "one?[export_url_vars survey_id]"
