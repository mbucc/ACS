# /www/press/admin/delete.tcl

ad_page_contract {

    Delete an existing press item (confirmation page)
 
    @author  Ron Henderson (ron@arsdigita.com)
    @created December 1999
    @cvs-id  delete.tcl,v 3.4.2.5 2000/09/22 01:39:06 kevin Exp
} {
    press_items:notnull
}

set user_id [ad_verify_and_get_user_id]

# initialize the data for these items

db_foreach press_items_info "
select scope,
       group_id,
       important_p,
       publication_name,
       publication_link,
       to_char(publication_date,'Month fmdd, yyyy') as display_date,
       publication_date_desc,
       article_title,
       article_link,
       article_pages,
       abstract,
       html_p,
       template_adp
from   press p, press_templates t
where  p.press_id in ([join $press_items ","])
and    p.template_id = t.template_id" {

    if {![press_admin_p $user_id $group_id]} {
	ad_return_complaint "You are not authorized to delete these items"
	return
    }

    if {![empty_string_p $publication_date_desc]} {
	set display_date $publication_date_desc
    }

    append press_info "
    <p>
    [press_coverage \
	    $publication_name $publication_link $display_date \
	    $article_title $article_link $article_pages $abstract \
	    $template_adp]</p>"
}

# -----------------------------------------------------------------------------

doc_return  200 text/html "
[ad_header "Delete Press Items"]

<h2>Delete</h2>

[ad_context_bar_ws [list "/press/" "Press"] [list "" "Admin"] "Delete"]

<hr>

<p>Please confirm that you want to <b>permanently delete</b> the
following press items:</p> 

<form method=post action=delete-2>
[export_form_vars press_items]
<center><input type=submit value=\"Yes, I want to delete them\"></center>
</form>

<blockquote>$press_info</blockquote>

[ad_footer]"

