ad_page_contract {
    add a persistent comment to a page
    
    @param page_id
    @cvs-id persistent-add.tcl,v 3.3.2.5 2000/09/22 01:37:17 kevin Exp
} {
    {page_id:naturalnum,notnull}
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_get_user_id]
if {$user_id == 0} {
    ad_returnredirect /register.tcl?return_url=[ns_urlencode  /comments/persistent-add.tcl?[export_url_vars page_id]]
}


set selection [db_0or1row page_data_get {
    select  nvl(page_title,url_stub) as page_title, url_stub 
    from static_pages
    where page_id = :page_id
}]

if {$selection == 0} {
    ad_return_complaint "Invalid page id" "Page id could not found"
    db_release_unused_handles
    return
}

doc_return  200 text/html "[ad_header "Add a comment to $page_title" ]

<h2>Add a comment</h2>
to <a href=\"$url_stub\">$page_title</a>
<hr>

What comment or alternative perspective
would you like to add to this page?<br>
<form action=persistent-add-2 method=post>
[export_form_vars page_id comment_id]
<textarea name=message cols=70 rows=10 wrap=soft></textarea><br>
<input type=hidden name=comment_type value=alternative_perspective>
<br>
Text above is
<select name=html_p><option value=f>Plain Text<option value=t>HTML</select>
<p>
<center>
<input type=submit name=submit value=\"Proceed\">
</center>
</form>
[ad_footer]
"

