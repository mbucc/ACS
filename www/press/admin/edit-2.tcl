# /www/press/admin/edit-2.tcl

ad_page_contract {

    Update a press item
    
    @author  Ron Henderson (ron@arsdigita.com)
    @created December 1999
    @cvs-id  edit-2.tcl,v 3.3.6.5 2000/09/16 19:05:49 ron Exp
} {
    {press_id:integer}
    {scope}
    {group_id:integer}
    {template_id:integer}
    {important_p}
    {publication_name:trim}
    {publication_link:trim}
    {publication_date}
    {publication_date_desc:trim}
    {article_title:trim}
    {article_link:trim}
    {article_pages:trim}
    {abstract:allhtml}
    {html_p}
}

# Verify that this user is a valid administrator

set user_id [ad_verify_and_get_user_id]

if {![press_admin_p $user_id $group_id]} {
    ad_return_complaint 1 "<li>You are not authorized to access this page"
    return
}

db_dml press_item_update "
update press 
set    scope                 = :scope,
       group_id              = :group_id,
       template_id           = :template_id,
       important_p           = :important_p,
       publication_date      = to_date(:publication_date,'yyyy-mm-dd'),
       publication_name      = :publication_name,
       publication_link      = :publication_link,
       publication_date_desc = :publication_date_desc,
       article_title         = :article_title,
       article_link          = :article_link,
       article_pages         = :article_pages,
       abstract              = :abstract,
       html_p                = :html_p
where  press_id              = :press_id"

# Redirect back to the admin page

ad_returnredirect ""
