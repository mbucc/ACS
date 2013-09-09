# /www/survsimp/admin/survey-create.tcl
ad_page_contract {

  Form for creating a survey.

  @param  name         title for new survey
  @param  short_name   tag for new survey
  @param  description  description for new survey

  @author raj@alum.mit.edu
  @date   February 9, 2000
  @cvs-id survey-create.tcl,v 1.8.2.5 2000/09/22 01:39:22 kevin Exp

} {

    {name ""}
    {short_name ""}
    {description:html ""}

}

set whole_page "[ad_header "Create New Survey"]

<h2>Create a New Survey</h2>

[ad_context_bar_ws_or_index [list "" "Simple Survey Admin"] "Create Survey"]

<hr>

<blockquote>

<form method=post action=\"survey-create-2\">
<p>

Survey Name:  <input type=text name=name value=\"$name\" size=30>
<p>
Short Name:  <input type=text name=short_name value = \"$short_name\" size=20 Maxlength=20>
<p> 
Survey Description: 
<br>
<textarea name=description rows=10 cols=65>$description</textarea>
<br>
The description above is: 
<input type=radio name=desc_html value=\"pre\">Preformatted text
<input type=radio name=desc_html value=\"plain\" checked>Plain text
<input type=radio name=desc_html value=\"html\">HTML
<p>
<center>
<input type=submit value=\"Create\">
</center>
</form>

</blockquote>

[ad_footer]
"



doc_return  200 text/html $whole_page 

