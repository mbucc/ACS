# /www/survsimp/admin/description-edit.tcl
ad_page_contract {

    Form to allow user to the description of a survey.

    @param  survey_id  integer denoting survey whose description we're changing

    @author Jin Choi (jsc@arsdigita.com) 
    @date   February 16, 2000
    @cvs-id description-edit.tcl,v 1.7.2.11 2000/09/22 01:39:20 kevin Exp
} {

    survey_id:integer

}


set user_id [ad_get_user_id]
survsimp_survey_admin_check $user_id $survey_id

db_1row survey_properites "select name as survey_name, description, description_html_p as desc_html
from survsimp_surveys
where survey_id = :survey_id"

set html_p_set [ns_set create]
ns_set put desc_html $desc_html

doc_return  200 text/html "[ad_header "Edit Description"]
<h2>$survey_name</h2>

[ad_context_bar_ws_or_index [list "" "Simple Survey Admin"] [list "one?[export_url_vars survey_id]" "Administer Survey"] "Edit Description"]

<hr>

<blockquote>
Edit and submit to change the description for this survey:
<form method=post action=\"description-edit-2\">
[export_form_vars survey_id]
<textarea name=description rows=10 cols=65>$description</textarea>  
<br>
The description above is:
<input type=radio name=desc_html value=\"pre\">Preformatted text
[bt_mergepiece  "<input type=radio name=desc_html value=\"f\">Plain text
<input type=radio name=desc_html value=\"t\">" $html_p_set] HTML
<P>

<center>
<input type=submit value=Update>
</center>

</blockquote>

[ad_footer]
"

