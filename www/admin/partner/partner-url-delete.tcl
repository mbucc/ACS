# $Id: partner-url-delete.tcl,v 3.0 2000/02/06 03:26:47 ron Exp $
set_the_usual_form_variables
# url_id 

set db [ns_db gethandle]

set selection [ns_db 1row $db "select url_stub, partner_id
  		               from ad_partner_url
                               where url_id='$QQurl_id'"]
set_variables_after_query

set page_title "Delete URL"
set context_bar [ad_context_bar_ws [list "index.tcl" "Partner manager"] [list "partner-view.tcl?[export_url_vars partner_id]" "One partner"] "$title"]

set page_body "
Are you sure you want to unassociate the url \"$url_stub\" for this partner?

<table>
<tr>
  <td><form method=post action=\"partner-url-delete-2.tcl\">
      [export_form_vars url_id]
      <input type=submit name=operation value=\"Yes\"></FORM>
  </td>
  <td><form method=post action=\"partner-url-delete-2.tcl\">
      [export_form_vars url_id]
      <input type=submit name=operation value=\"No\"></FORM>
  </td>
</tr>
</table>
"


ns_return 200 text/html [ad_partner_return_template]