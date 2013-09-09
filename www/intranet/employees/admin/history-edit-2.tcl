# /www/intranet/employees/admin/history-edit-2.tcl
ad_page_contract {
    
    Modified by mbryzek@arsdigita.com in January 2000 to 
    support new group-based intranet
    allows and administrator to edit the work percentage
    history of an employee
    
    @author ahmedaa@mit.edu
    @creation-date january 1st 2000
    @cvs-id history-edit-2.tcl,v 3.4.2.4 2000/08/16 21:24:49 mbryzek Exp
    @param percentage Percentage Full time
    @param user_id The user id
    @param start_block start block
    @param stop_block  Optional end block
    @param note Optional a note
} {
    percentage
    user_id
    start_block
    { stop_block "" }
    { note "" }
}


if { [string compare $stop_block "forever"] == 0 } {
    set stop_block [db_string get_stop_block \
	    "select distinct max(start_block) as max_start_block from im_start_blocks"]
}

db_transaction {

# change rows that do exist and overlap with my range
db_dml update_ranges "update im_employee_percentage_time 
                  set percentage_time = :percentage 
                  where user_id = :user_id
                  and start_block in (select start_block 
                                        from im_start_blocks 
                                       where start_block >= :start_block
                                         and start_block <= :stop_block)"

# insert rows that do not exist
db_dml insert_ranges "insert into im_employee_percentage_time 
                      select start_block, :user_id, :percentage, :note 
                        from im_start_blocks 
                       where start_block >= :start_block 
                         and start_block <= :stop_block
                         and not exists (select start_block 
                                           from im_employee_percentage_time imap2 
                                          where im_start_blocks.start_block = imap2.start_block 
                                            and user_id = :user_id)"

db_0or1row check_test "select 1 as existance_test
           from im_start_blocks 
          where start_block > (select max(start_block) 
                                 from im_employee_percentage_time 
                                where start_block < :start_block)
                                  and start_block < :start_block"



if {[exists_and_not_null existance_test] } {

    # now lets fill in the gaps that come before this range
    db_dml history_update "insert into im_employee_percentage_time 
                   (start_block, user_id, percentage_time, note) 
                   select start_block, :user_id, 0, :note  
                     from im_start_blocks 
                    where start_block < :start_block
                      and start_block > (select max(start_block) 
                                           from im_employee_percentage_time 
                                          where start_block < :start_block)"

}

}

ad_returnredirect history?[export_url_vars user_id]


