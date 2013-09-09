# /www/intranet/employees/admin/qualification-add-2.tcl

ad_page_contract {

    

    @author teadams@arsdigita.com
    @creation-date April 24, 2000
    @cvs-id qualification-add-2.tcl,v 3.2.2.4 2000/08/16 21:24:50 mbryzek Exp
    @param return_url The url we return to
    @param qualification the new qualification
} {
    {return_url ""}
    qualification 
}





db_dml new_qual "insert into im_qualification_processes 
(qualification_id,qualification)  select im_qualification_seq.nextval, :qualification from dual where
not exists (select qualification_id from im_qualification_processes 
where qualification = :qualification)"

ad_returnredirect "qualification-list.tcl"

