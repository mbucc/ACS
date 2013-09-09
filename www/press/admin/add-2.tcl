# /www/press/admin/add-2.tcl

ad_page_contract {

    Insert a new press item
    
    @author  Ron Henderson (ron@arsdigita.com)
    @created December 1999
    @cvs-id  add-2.tcl,v 3.4.2.5 2000/09/16 19:05:49 ron Exp
} {
    {scope}
    {group_id:integer}
    {important_p}
    {template_id:integer}
    {publication_name:trim}
    {publication_link:trim}
    {publication_date}
    {publication_date_desc:trim}
    {article_title:trim}
    {article_link}
    {article_pages}
    {abstract:allhtml,trim,optional ""}
    {html_p}
}

# Note: we don't need extensive validation of the input variables on
# this page because that was all handled by preview.tcl

# Verify that this user is a valid administrator

set user_id [ad_verify_and_get_user_id]

if {![press_admin_p $user_id $group_id]} {
    ad_return_complaint 1 "<li>Sorry but you're not authorized to add an item of this scope."
    return
}



# Insert the new row into the database

db_dml press_new_item "
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
  :scope,
  :group_id,
  :template_id,
  :important_p,
  :publication_name,
  :publication_link,
   to_date(:publication_date,'yyyy-mm-dd'),
  :publication_date_desc,
  :article_title,
  :article_link,
  :article_pages,
  :abstract,
  :html_p,
   sysdate,
  :user_id,
  '[ns_conn peeraddr]')"

db_release_unused_handles

# Redirect back to the administration page

ad_returnredirect ""

