# Insert a new press item
#
# Author: ron@arsdigita.com, December 1999
#
# $Id: add-2.tcl,v 3.0.4.2 2000/04/28 15:11:19 carsten Exp $
# -----------------------------------------------------------------------------

ad_page_variables {
    {scope}
    {group_id}
    {important_p}
    {template_id}
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
    ad_return_complaint 1 "<li>Sorry but you're not authorized to add an item of this scope."
    return
}

# Insert the new row into the database

ns_db dml $db "
insert into press
 (press_id,
  scope,
  group_id,
  template_id,
  important_p,
  publication_name,
  publication_link,
  publication_date,
  publication_date_desc,
  article_title,
  article_link,
  article_pages,
  abstract,
  html_p,
  creation_date,
  creation_user,
  creation_ip_address)
values
 (press_id_sequence.nextval,
  '$scope',
  [ns_dbquotevalue $group_id integer],
   $template_id,
  '$important_p',
  [ns_dbquotevalue $publication_name],
  [ns_dbquotevalue $publication_link],
   to_date('$publication_date','yyyy-mm-dd'),
  [ns_dbquotevalue $publication_date_desc],
  [ns_dbquotevalue $article_title],
  [ns_dbquotevalue $article_link],
  [ns_dbquotevalue $article_pages],
  [ns_dbquotevalue $abstract],
  '$html_p',
   sysdate,
   $user_id,
  '[ns_conn peeraddr]')"

# Redirect back to the administration page

ad_returnredirect ""










