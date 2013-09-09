# /file-storage/group.tcl

# This page seems to be obsolete.
# Mark Dettinger, 21 July 2000

ad_page_contract {
    This file displays all group wide files that the user has permission to see
  
    @author aure@arsdigita.com
    @creation-date June 1999
    @cvs-id group.tcl,v 3.7.6.1 2000/07/21 22:05:16 mdetting Exp
    
    modified by randyg@arsdigita.com, January 2000
} {
    {group_id ""}
}

if { $group_id == "all_public" } {
    ad_returnredirect "all-public"
    return
}

if { $group_id == "personal" } {
    ad_returnredirect "private-one-person"
    return
}

if { $group_id == "private_individual" } {
    ad_returnredirect "private-one-person"
    return
}

if { $group_id == "public_tree" } {
    ad_returnredirect ""
    return
}

if { [lindex $group_id 0] == "user_id" } {
    ad_returnredirect "public-one-person?user_id=[lindex $group_id 1]"
    return
}

if { [lindex $group_id 0] == "private_group" } {
    ad_returnredirect "private-one-group?group_id=[lindex $group_id 1]"
    return
}

if { [lindex $group_id 0] == "public_group" } {
    ad_returnredirect "public-one-group?group_id=[lindex $group_id 1]"
    return
}

ad_returnredirect "private-one-group?group_id=[lindex $group_id 1]"
