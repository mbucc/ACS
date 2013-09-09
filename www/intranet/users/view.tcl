# /www/intranet/users/view.tcl

ad_page_contract {
    Purpose: View everything about a user. We redirect right 
    now to community-member.tcl but leave this file here to:
    1. default to the current cookied user
    2. have a secure place later for more detailed employee
       info w/out breaking links

    @param user_id 

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id view.tcl,v 3.8.2.4 2000/08/16 21:25:06 mbryzek Exp
} {
    { user_id:integer "[ad_maybe_redirect_for_registration]" }
}

ad_returnredirect /shared/community-member?[export_url_vars user_id]
