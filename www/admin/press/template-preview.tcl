# /www/admin/press/template-preview.tcl

ad_page_contract {

    Preview a template

    @author  Ron Henderson (ron@arsdigita.com)
    @created December 1999
    @cvs-id  template-preview.tcl,v 3.1.8.6 2001/01/11 23:17:18 khy Exp
} {
    {target}
    {template_id:integer,verify}
    {template_name:trim}
    {template_adp:trim,allhtml}
}

# Build a preview of the template

set preview [press_coverage_preview $template_adp]

# NOTE: AOLserver 2.x does not throw exceptions for ns_adp_parse, so
# we can't check for a parsing error from here.  In AOLserver 3.0
# you can test for an error using the following:
#
# if {[ns_adp_exception] != "ok"} {
#     incr error_count
#     append error_list "<li>You're ADP generated a parsing error"
# }

# -----------------------------------------------------------------------------
# Error checking

set error_count 0
set error_list ""

if {[empty_string_p $template_name]} {
    incr error_count
    append error_list "<li>You must provide a template name\n"
}

if {[empty_string_p $template_adp]} {
    incr error_count
    append error_list "<li>You must provide the template ADP code\n"
}

if {[string length $template_adp] > 4000} {
    incr error_count
    append error_list "<li>Your template is too long (4000 characters max)"
}

# Check for name conflicts

if [empty_string_p $template_id] {
    set template_id [db_null]
}

if {0 != [db_string template_name_check "
select count(*) 
from   press_templates 
where  template_id  <> :template_id
and    template_name = :template_name"]} {
    incr error_count
    append error_list "<li>Your template name conflicts with an existing template\n"
}

if {$error_count > 0} {
    ad_return_complaint $error_count $error_list
    return
}

# Done with the database

db_release_unused_handles

# -----------------------------------------------------------------------------
# Ship it out

doc_return  200 text/html "
[ad_admin_header "Preview"]

<h2>Preview</h2>

[ad_admin_context_bar [list "" "Press"] "Template Preview"]

<hr>

<p>The following preview shows what press items formatted using the
template <b>$template_name</b> will look like:

<blockquote>
$preview
<br>

<form method=post action=$target>
[export_form_vars template_name template_adp]
[export_form_vars -sign template_id]
<center><input type=submit value=Submit></center>
</form>
</blockquote>

[ad_admin_footer]"
