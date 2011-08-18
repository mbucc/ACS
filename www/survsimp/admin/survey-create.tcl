#
# /survsimp/admin/survey-create.tcl
#
# by raj@alum.mit.edu, February 9, 2000
#
# form for creating a survey
# 

set db [ns_db gethandle]

set survey_id [database_to_tcl_string $db "select survsimp_survey_id_sequence.nextval from dual"]

set whole_page "[ad_header "Create New Survey"]

<h2>Create a New Survey</h2>

[ad_context_bar_ws_or_index [list "index.tcl" "Simple Survey Admin"] "Create Survey"]

<hr>

<blockquote>

<form method=post action=\"survey-create-2.tcl\">
<p>
[export_form_vars survey_id]

Survey Name:  <input type=text name=name size=30>
<p>
Short Name:  <input type=text name=short_name size=20 Maxlength=20>
<p> 
Survey Description: 
<br>
<textarea name=description rows=10 cols=65>
</textarea>  
<p>
<center>
<input type=submit value=\"Create\">
</center>
</form>

</blockquote>

[ad_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $whole_page 



