#
# /survsimp/admin/description-edit.tcl
#
# by jsc@arsdigita.com, February 16, 2000
#
# Edit the description on a survey.
# 

ad_page_variables {survey_id}

set db [ns_db gethandle]

set user_id [ad_get_user_id]
survsimp_survey_admin_check $db $user_id $survey_id

set selection [ns_db 1row $db "select name as survey_name, description
from survsimp_surveys
where survey_id = $survey_id"]

set_variables_after_query

ns_db releasehandle $db

ns_return 200 text/html "[ad_header "Edit Description"]
<h2>$survey_name</h2>

[ad_context_bar_ws_or_index [list "index.tcl" "Simple Survey Admin"] [list "one.tcl?[export_url_vars survey_id]" "Administer Survey"] "Edit Description"]

<hr>

<blockquote>
Edit and submit to change the description for this survey:
<form action=\"description-edit-2.tcl\">
[export_form_vars survey_id]
<textarea name=description rows=10 cols=65>
$description
</textarea>  

<P>

<center>
<input type=submit value=Update>
</center>

</blockquote>

[ad_footer]
"


