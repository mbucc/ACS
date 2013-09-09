# /www/admin/partner/partner-url-delete.tcl

ad_page_contract {
    Confirms delete of url

    @param url_id 

    @author mbryzek@arsdigita.com
    @creation-date 10/1999

    @cvs-id partner-url-delete.tcl,v 3.2.2.3 2000/09/22 01:35:45 kevin Exp
} {
    url_id:integer,notnull
}


db_1row partner_url_id_from_url \
	"select url_stub, partner_id
  	   from ad_partner_url
          where url_id=:url_id"

set page_title "Delete URL"
set context_bar [ad_context_bar_ws [list "index" "Partner manager"] [list "partner-view?[export_url_vars partner_id]" "One partner"] "$page_title"]

set page_body "
Are you sure you want to unassociate the url \"$url_stub\" for this partner?

<table>
<tr>
  <td><form method=post action=\"partner-url-delete-2\">
      [export_form_vars url_id]
      <input type=submit name=operation value=\"Yes\"></FORM>
  </td>
  <td><form method=post action=\"partner-url-delete-2\">
      [export_form_vars url_id]
      <input type=submit name=operation value=\"No\"></FORM>
  </td>
</tr>
</table>
"

# ad_partner_return_template releases the db handles

doc_return  200 text/html [ad_partner_return_template]