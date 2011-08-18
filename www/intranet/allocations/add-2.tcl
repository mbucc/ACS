# $Id: add-2.tcl,v 3.1.4.2 2000/04/28 15:11:04 carsten Exp $
# File: /www/intranet/allocations/add-2.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Writes allocations to db
# 

set_the_usual_form_variables

# group_id, allocated_user_id, start_block, end_block, percentage_time, note, allocation_id, maybe return_url

ad_maybe_redirect_for_registration
set user_id [ad_get_user_id]

set db [ns_db gethandle]

# Now check to see if the input is good as directed by the page designer

set exception_count 0
set exception_text ""

if {[string length $note] > 1000} {
    incr exception_count
    append exception_text "<LI>\"note\" is too long\n"
}

#check the start and end blocks
set selection [ns_db 0or1row $db "select 1 from dual 
where to_date('$start_block', 'YYYY-MM-DD') <= 
to_date('$end_block', 'YYYY-MM-DD')
"]
if {[empty_string_p $selection]} {
    incr exception_count
    append exception_text "<li>Please make sure your start block is not 
    after your end block.\n"
}


if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}


if [empty_string_p $end_block] {
    set end_block $start_block
}
# So the input is good --
# Now we'll update the allocation.

set dml_type "insert"

ns_db dml $db "begin transaction"

# We want to be smart about adjusting the current allocations

# if the allocation_id and the start_block are the same as an
# existing row,  this means we are changing a particular allocation
# decision from before. We want to do an update of that row instead of
# creating a new row.

    ns_db dml $db "update 
im_allocations 
set last_modified=sysdate,
last_modifying_user = $user_id, modified_ip_address = '[ns_conn peeraddr]',
percentage_time = $percentage_time,
note = '$QQnote', user_id =  [ns_dbquotevalue $allocated_user_id],
group_id = $group_id
where start_block >= '$start_block' and start_block <=\
 '$end_block'
and allocation_id = $allocation_id"

# if the user_id, start_date and group_id is that same
# as an exisiting row and the allocation_id is not the same (above case), 
# we are giving a user two different allocations
# on the same project. we want to do an update of that row
# instead of creating a new row

ns_db dml $db "update im_allocations 
set last_modified=sysdate,
last_modifying_user = $user_id, modified_ip_address = '[ns_conn peeraddr]',
percentage_time = $percentage_time,
note = '$QQnote',
allocation_id = $allocation_id
where start_block >= '$start_block' and start_block <=\
 '$end_block'
and user_id =  [ns_dbquotevalue $allocated_user_id]
and group_id = $group_id
and allocation_id <> $allocation_id"

# If the conditions above don't apply, let's add a new row

ns_db dml $db "insert into im_allocations
(allocation_id, last_modified, last_modifying_user, 
modified_ip_address, group_id, user_id, start_block, percentage_time, note)
select $allocation_id, sysdate, $user_id, 
'[ns_conn peeraddr]', $group_id,  
[ns_dbquotevalue $allocated_user_id], start_block, 
$QQpercentage_time, '$QQnote' 
from im_start_blocks 
where start_block >= '$start_block' and start_block <= '$end_block'
and not exists (select 1 from im_allocations im2
where im2.allocation_id = $allocation_id 
and im_start_blocks.start_block = im2.start_block)
and not exists (select 1 from im_allocations im3
where im3.user_id =  [ns_dbquotevalue $allocated_user_id]
and im3.group_id = $group_id 
and im3.allocation_id <> $allocation_id
and im_start_blocks.start_block = im3.start_block)"

# clean out allocations with 0 percentage
ns_db dml $db "delete from im_allocations where percentage_time=0"

ns_db dml $db "end transaction"

if [info exist return_url] {
    ad_returnredirect $return_url
} else {
    ad_returnredirect index.tcl?[export_url_vars start_block group_id]
}
 