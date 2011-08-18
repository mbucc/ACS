# Preview a template
#
# Author: ron@arsdigita.com, December 1999
#
# $Id: template-preview.tcl,v 3.0.4.2 2000/03/17 23:55:48 tzumainn Exp $
# -----------------------------------------------------------------------------

ad_page_variables {
    {target}
    {template_id "null"}
    {template_name}
    {template_adp}
}

set db [ns_db gethandle]

# Pre-processing

set template_name [string trim $template_name]
set template_adp  [string trim $template_adp]

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

if {0 != [database_to_tcl_string $db "
select count(*) from   press_templates 
where  template_id  <> $template_id
and    template_name = '[DoubleApos $template_name]'"]} {
    incr error_count
    append error_list "<li>Your template name conflicts with an existing template\n"
}

if {$error_count > 0} {
    ad_return_complaint $error_count $error_list
    return
}

# Done with the database

ns_db releasehandle $db

# -----------------------------------------------------------------------------
# Ship it out

ns_return 200 text/html "
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
[export_form_vars template_id template_name template_adp]
<center><input type=submit value=Submit></center>
</form>
</blockquote>

[ad_admin_footer]"
