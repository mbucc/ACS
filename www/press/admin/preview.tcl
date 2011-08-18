# Preview a new press item
#
# Author: ron@arsdigita.com, December 1999
#
# $Id: preview.tcl,v 3.0.4.1 2000/03/15 20:34:39 aure Exp $
# -----------------------------------------------------------------------------

ad_page_variables {
    {press_id ""}
    {group_id}
    {template_id}
    {important_p}
    {publication_name "" qq}
    {publication_link}
    {publication_date_desc}
    {article_title "" qq}
    {article_link}
    {article_pages}
    {abstract "" qq}
    {html_p}
    {target}
}

# Verify that this user is a valid administrator

set user_id [ad_verify_and_get_user_id]
set db      [ns_db gethandle]

if {![press_admin_any_group_p $db $user_id]} {
    ad_return_complaint 1 "<li>You are not authorized to access this page"
    return
}

# A little pre-processing

if {$publication_link == "http://"} {
    set publication_link ""
}

if {$article_link == "http://"} {
    set article_link ""
}

if [empty_string_p $group_id] {
    set scope "public"
} else {
    set scope "group"
}

# Grab the template so we can check additional required variables

set template_adp [database_to_tcl_string $db "
select template_adp from press_templates where template_id=$template_id"]

# -----------------------------------------------------------------------------
# Error checking for a press item

set error_count 0
set error_text ""

if {[empty_string_p $publication_name]} {
	incr error_count
	append error_text "<li>You must provide the publication name\n"
}

if {[empty_string_p $article_title]} {
    incr error_count
    append error_text "<li>You must provide the article name\n"
}

if {![empty_string_p $publication_link] && ![philg_url_valid_p $publication_link]} {
    incr error_count
    append error_text \
	    "<li>The publication link does not look like a valid URL\n"
}

if {![empty_string_p $article_link] && ![philg_url_valid_p $article_link]} {
    incr error_count
    append error_text \
	    "<li>The article link does not look like a valid URL\n"
}
    
if {[catch { ns_dbformvalue [ns_conn form] publication_date date publication_date}]} {
    incr error_count
    append error_text "<li>The publication date is not a valid date\n"
} elseif {[empty_string_p $publication_date]} {
    incr error_count
    append error_text "<li>You must provide a publication date\n"
}

# Check for additional fields needed by the template

if {[info exists template_adp]} {
    if {[regexp abstract $template_adp]} {
	if {[empty_string_p $abstract]} {
	    incr error_count 
	    append error_text "<li>Your formatting template requires an abstract\n"
	}
    }
    if {[regexp article_pages $template_adp]} {
	if {[empty_string_p $article_pages]} {
	    incr error_count 
	    append error_text "<li>Your formatting template requires a page reference\n"
	}
    }
}

if {$error_count > 0} {
    ad_return_complaint $error_count $error_text
    return
}

# -----------------------------------------------------------------------------
# Done with error checking.  Now create a preview of the press item

# Convert the publication date to the correct format for display

if {[empty_string_p $publication_date_desc]} {
    set display_date [database_to_tcl_string $db "
    select to_char(to_date('$publication_date','yyyy-mm-dd'),'Month fmdd, yyyy') 
    from dual"]
} else {
    set display_date $publication_date_desc
}

ns_db releasehandle $db

# -----------------------------------------------------------------------------
# Ship out the preview...

ns_return 200 text/html "
[ad_header "Preview"]

<h2>Preview</h2>
[ad_context_bar_ws \
	[list "../" "Press"] \
	[list "" "Admin"] \
	"Preview"]
<hr>

<p>The press item will be displayed as follows:</p>

<blockquote>
[press_coverage \
	$publication_name $publication_link $display_date \
	$article_title $article_link $article_pages $abstract \
	$template_adp]

<br>

<form method=post action=$target>
[export_form_vars \
	press_id scope group_id template_id important_p \
	publication_name publication_link publication_date publication_date_desc \
	article_title article_link article_pages abstract html_p]
<center><input type=submit value=Confirm></center>
</form>
</blockquote>

[ad_footer]"





