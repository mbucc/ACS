# merge-from-search.tcl

ad_page_contract {
    exists to redirect to merge.tcl after /user-search.tcl
    or /admin/users/search.tcl 
    
    @param u1
    @param user_id_from_search
    @author philg@mit.edu
    @creation-date October 30, 1999
    @cvs-id merge-from-search.tcl,v 3.1.6.2.2.2 2000/07/31 19:47:46 gjin Exp

} {
    u1:notnull
    user_id_from_search:integer,notnull
}

ad_returnredirect "merge.tcl?u1=$u1&u2=$user_id_from_search"
