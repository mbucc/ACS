#  www/admin/ecommerce/templates/make-default-2.tcl
ad_page_contract {
    @param template_id
  @author
  @creation-date
  @cvs-id make-default-2.tcl,v 3.2.2.4 2000/08/16 15:15:45 stevenp Exp
} {
    template_id:integer
}


if [catch { db_dml update_set_default_template "update ec_admin_settings set default_template = :template_id" } errmsg] {
    ad_return_complaint 1 "<li>We couldn't change this to be the default template.  Here is the error message that Oracle gave us:<blockquote>$errmsg</blockquote>"
    return
}
db_release_unused_handles

ad_returnredirect index.tcl