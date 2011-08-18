# Update a press item
#
# Author: ron@arsdigita.com, December 1999
#
# $Id: edit-2.tcl,v 3.0.4.2 2000/04/28 15:11:21 carsten Exp $
# -----------------------------------------------------------------------------

ad_page_variables {
    {press_id}
    {scope}
    {group_id}
    {template_id}
    {important_p}
    {publication_name}
    {publication_link}
    {publication_date}
    {publication_date_desc}
    {article_title}
    {article_link}
    {article_pages}
    {abstract}
    {html_p}
}

# Verify that this user is a valid administrator

set user_id [ad_verify_and_get_user_id]
set db      [ns_db gethandle]

if {![press_admin_p $db $user_id $group_id]} {
    ad_return_complaint 1 "<li>You are not authorized to access this page"
    return
}

ns_db dml $db "
update press 
set    scope                 = '$scope',
       group_id              = [ns_dbquotevalue $group_id integer],
       template_id           =  $template_id,
       important_p           = '$important_p',
       publication_date      = to_date('$publication_date','yyyy-mm-dd'),
       publication_name      = [ns_dbquotevalue $publication_name],
       publication_link      = [ns_dbquotevalue $publication_link],
       publication_date_desc = [ns_dbquotevalue $publication_date_desc],
       article_title         = [ns_dbquotevalue $article_title],
       article_link          = [ns_dbquotevalue $article_link],
       article_pages         = [ns_dbquotevalue $article_pages],
       abstract              = [ns_dbquotevalue $abstract],
       html_p                = '$html_p'
where  press_id              =  $press_id"

# Redirect back to the admin page

ad_returnredirect ""
