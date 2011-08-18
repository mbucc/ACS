# Delete an existing press item (confirmation page)
# 
# Author: ron@arsdigita.com, December 1999
#
# $Id: delete.tcl,v 3.0.4.2 2000/04/28 15:11:20 carsten Exp $
# -----------------------------------------------------------------------------

ad_page_variables {press_id}

set user_id [ad_verify_and_get_user_id]
set db      [ns_db gethandle]

# initialize the data for this item

set selection [ns_db 1row $db "
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
where  p.press_id = $press_id
and    p.template_id = t.template_id"]

if {[empty_string_p $selection]} {
    ad_return_error "An error occurred looking up press_id = $press_id"
    return
} else {
    set_variables_after_query
}

# Verify that this user is a valid administrator

if {![press_admin_p $db $user_id $group_id]} {
    ad_returnredirect "/press/"
    return
}

if {![empty_string_p $publication_date_desc]} {
    set display_date $publication_date_desc
}

# -----------------------------------------------------------------------------

ns_return 200 text/html "
[ad_header Admin]

<h2>Delete</h2>

[ad_context_bar_ws [list "../" "Press"] [list "" "Admin"] "Delete"]

<hr>

<p>Please confirm that you want to <b>permanently delete</b> the
following press item:</p> 

<blockquote>
[press_coverage \
	$publication_name $publication_link $display_date \
	$article_title $article_link $article_pages $abstract \
	$template_adp]
</blockquote>

<form method=post action=delete-2>
[export_form_vars press_id]
<center><input type=submit value=\"Yes, I want to delete it\"></center>
</form>

[ad_footer]"





