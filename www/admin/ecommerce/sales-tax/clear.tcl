#  www/admin/ecommerce/sales-tax/clear.tcl
ad_page_contract {

  @author
  @creation-date
  @cvs-id clear.tcl,v 3.1.6.3 2000/09/22 01:35:00 kevin Exp
} {
}


doc_return  200 text/html  "[ad_admin_header "Clear Sales Tax Settings"]

<h2>Clear Sales Tax Settings</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Sales Tax"] "Clear Settings"]

<hr>

Please confirm that you wish to clear all your sales tax settings.

<form method=post action=clear-2>
<center>
<input type=submit value=\"Confirm\">
</center>
</form>

[ad_admin_footer]
"