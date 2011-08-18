# Administration for the press module
#
# Author: ron@arsdigita.com, December 1999
#
# $Id: index.tcl,v 3.0.4.1 2000/03/15 20:38:22 aure Exp $
# -----------------------------------------------------------------------------

set db [ns_db gethandle]

# Build the list of defined templates 

set selection [ns_db select $db "
select t.template_id,
       t.template_name,
       t.template_adp,
       count(p.template_id) as template_usage
from   press_templates t, press p
where  t.template_id = p.template_id(+)
group  by t.template_id, t.template_name, t.template_adp
order  by t.template_name"]

set avail_count 0
set avail_list ""
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr avail_count
    append avail_list "
    <p>
    <li>$template_name
    (used $template_usage time[expr {$template_usage != 1 ? "s" : ""}])
    &nbsp; 
    <a href=template-edit?template_id=$template_id>edit</a>"

    if {$template_usage == 0 && $template_id > 1} {
	append avail_list \
		" | <a href=template-delete?template_id=$template_id>delete</a>"
    }

    append avail_list "
    <p>
    [press_coverage_preview $template_adp]"
}

ns_db releasehandle $db

if {$avail_count == 0} {
    set avail_template_list "
    There are no press coverage templates in the system."
} else {
    set avail_template_list "
    <p>You may edit any of the following templates:</p>
    <ul>
    $avail_list
    </ul>"
}

# -----------------------------------------------------------------------------
# Ship it out

ns_return 200 text/html "
[ad_admin_header "Press Administration"]

<h2>Press Administration</h2>

[ad_admin_context_bar "Press"]

<hr>

Documentation: <a href=/doc/press.html>/doc/press.html</a><br>
User pages: <a href=/press/>/press/</a><br>
Maintain press coverage: <a href=/press/admin>/press/admin/</a>

<p>$avail_template_list</p>

<p>
<ul>
<li><a href=template-add>Add a new template</a></li>
</ul>
</p>

[ad_admin_footer]"
