# /www/admin/press/index.tcl

ad_page_contract {

    Administration for the press module

    @author  Ron Henderson (ron@arsdigita.com)
    @created December 1999
    @cvs-id  index.tcl,v 3.2.6.4 2000/09/22 01:35:50 kevin Exp
} {
}

# Build the list of defined templates 

set avail_count 0
set avail_list ""

db_foreach template_items {
    select t.template_id,
           t.template_name,
           t.template_adp,
           count(p.template_id) as template_usage
    from   press_templates t, press p
    where  t.template_id = p.template_id(+)
    group  by t.template_id, t.template_name, t.template_adp
    order  by t.template_name
} {
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

db_release_unused_handles

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

doc_return  200 text/html "
[ad_admin_header "Press Administration"]

<h2>Press Administration</h2>

[ad_admin_context_bar "Press"]

<hr>

Documentation: <a href=/doc/press>/doc/press.html</a><br>
User pages: <a href=/press/>/press/</a><br>
Maintain press coverage: <a href=/press/admin>/press/admin/</a>

<p>$avail_template_list</p>

<p>
<ul>
<li><a href=template-add>Add a new template</a></li>
</ul>
</p>

[ad_admin_footer]"
