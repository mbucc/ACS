# $Id: make-default-2.tcl,v 3.0.4.1 2000/04/28 15:08:57 carsten Exp $
set_the_usual_form_variables
# template_id

set db [ns_db gethandle]


if [catch { ns_db dml $db "update ec_admin_settings set default_template = $template_id" } errmsg] {
    ad_return_complaint 1 "<li>We couldn't change this to be the default template.  Here is the error message that Oracle gave us:<blockquote>$errmsg</blockquote>"
    return
}

ad_returnredirect index.tcl