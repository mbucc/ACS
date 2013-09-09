# /www/press/admin/preview.tcl

ad_page_contract {

    Preview a new press item
    
    @author  Ron Henderson (ron@arsdigita.com)
    @created December 1999
    @cvs-id  preview.tcl,v 3.3.2.7 2000/09/22 01:39:08 kevin Exp
} {
    {press_id:integer ""}
    {group_id:integer}
    {template_id:integer}
    {important_p}
    {publication_name:trim,notnull}
    {publication_link}
    {publication_date:array,date,notnull}
    {publication_date_desc}
    {article_title:trim,notnull}
    {article_link}
    {article_pages}
    {abstract:allhtml ""}
    {html_p}
    {target}
} -validate {

    publication_link_ck -requires {publication_link} {
	if [exists_and_not_null publication_link] {
	    if [string equal $publication_link "http://"] {
		set publication_link ""
	    } elseif {[ad_url_valid_p $publication_link] != 1} {
		ad_complain "Your publication link doesn't appear to be a valid URL."
		return 0
	    }
	}
	return 1
    }

    article_link_ck -requires {article_link} {
	if [exists_and_not_null article_link] {
	    if [string equal $article_link "http://"] {
		set article_link ""
	    } elseif {[ad_url_valid_p $article_link] != 1} {
		ad_complain "Your article link doesn't appear to be a valid URL."
		return 0
	    }
	}
	return 1
    }
}

# Verify that this user is a valid administrator

set user_id [ad_verify_and_get_user_id]

if {![press_admin_any_group_p $user_id]} {
    ad_return_complaint 1 "<li>You are not authorized to access this page"
    return
}

# A little pre-processing

if [empty_string_p $group_id] {
    set scope "public"
} else {
    set scope "group"
}

# Grab the template so we can check additional required variables

set template_adp [db_string template_info "
select template_adp 
from   press_templates 
where  template_id = :template_id"]

# Template-specific error checking

set error_count 0
set error_text ""

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

set   publication_date_tmp $publication_date(date)
unset publication_date
set   publication_date $publication_date_tmp

if {[empty_string_p $publication_date_desc]} {
    set display_date [db_string publication_date "
    select to_char(to_date(:publication_date,'yyyy-mm-dd'),'Month fmdd, yyyy') from dual"]
} else {
    set display_date $publication_date_desc
}

# -----------------------------------------------------------------------------
# Ship out the preview...

doc_return  200 text/html "
[ad_header "Preview"]

<h2>Preview</h2>

[ad_context_bar_ws [list "../" "Press"] [list "" "Admin"] "Preview"]

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


