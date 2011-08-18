# $Id: history-edit-2.tcl,v 3.0.4.3 2000/04/28 15:11:06 carsten Exp $
# /www/intranet/employees/admin/history-edit-2.tcl
# created: january 1st 2000
# ahmedaa@mit.edu
# Modified by mbryzek@arsdigita.com in January 2000 to 
# support new group-based intranet

# allows and administrator to edit the work percentage
# history of an employee
set db [ns_db gethandle]

# percentage, user_id, start_block, stop_block, note
set_the_usual_form_variables

if { [string compare $stop_block "forever"] == 0 } {
    set stop_block [database_to_tcl_string $db \
	    "select distinct max(start_block) as max_start_block from im_start_blocks"]
}

ns_db dml $db "begin transaction"

# change rows that do exist and overlap with my range
ns_db dml $db "update im_employee_percentage_time 
                  set percentage_time = $percentage 
                where user_id = $user_id
                  and start_block in (select start_block 
                                        from im_start_blocks 
                                       where start_block >= '$start_block'
                                         and start_block <= '$stop_block')"

# insert rows that do not exist
ns_db dml $db "insert into im_employee_percentage_time 
                      select start_block, $user_id, $percentage, '$QQnote' 
                        from im_start_blocks 
                       where start_block >= '$start_block' 
                         and start_block <= '$stop_block' 
                         and not exists (select start_block 
                                           from im_employee_percentage_time imap2 
                                          where im_start_blocks.start_block = imap2.start_block 
                                            and user_id = $user_id)"

set selection [ns_db select $db \
	"select start_block 
           from im_start_blocks 
          where start_block > (select max(start_block) 
                                 from im_employee_percentage_time 
                                where start_block < '$start_block') 
                                  and start_block < '$start_block'"]

set number_empty_spaces [ns_set size $selection]

if { $number_empty_spaces > 0 } {

    # now lets fill in the gaps that come before this range
    ns_db dml $db "insert into im_employee_percentage_time 
                   (start_block, user_id, percentage_time, note) 
                   select start_block, $user_id, 0, '$QQnote'  
                     from im_start_blocks 
                    where start_block < '$start_block'
                      and start_block > (select max(start_block) 
                                           from im_employee_percentage_time 
                                          where start_block < '$start_block')"

}

ns_db dml $db "end transaction"

ad_returnredirect history.tcl?[export_url_vars user_id]





