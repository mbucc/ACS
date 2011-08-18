# $Id: user-remove-2.tcl,v 1.1.2.4 2000/04/28 15:11:07 carsten Exp $
#
# File: /www/intranet/employess/admin/user-remove-2.tcl
# Author: mbryzek@arsdigita.com, 3/15/2000
# removes specified user_id from all groups of type intranet

set_form_variables 0
# user_id

if { [exists_and_not_null user_id] } {
    set db [ns_db gethandle]
    
    ns_db dml $db "delete from user_group_map ugm 
                    where ugm.user_id='$user_id' 
                      and exists (select 1 
                                    from user_groups ug 
                                   where ug.group_id=ugm.group_id 
                                     and ug.group_type='[ad_parameter IntranetGroupType intranet intranet]')"


}

ad_returnredirect index.tcl