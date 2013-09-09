# /packages/templates/user-util-procs.tcl
ad_library {

  User utilities for the ArsDigita Publishing System.

  @author Karl Goldstein (karlg@arsdigita.com)
  @cvs-id user-util-procs.tcl,v 1.2.2.2 2000/07/23 22:36:34 seb Exp

}

# Copyright (C) 1999-2000 ArsDigita Corporation

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

proc ad_util_get_group_type_info { group_type { key "" } { procname "" } } {

  ns_share ad_group_type_cache

  set info [ns_set get $ad_group_type_cache $group_type]

  if { $info == "" } {

    set query "select * from user_group_types 
               where group_type = '$group_type'"
    set info [ad_dbquery onerow $query]

    if { $info != "" } {

      set info [ad_util_create_persistent_set $info]
    }

    ns_set put $ad_group_type_cache $group_type $info
  }

  if { ! [empty_string_p $key] } {

    if { [ns_set find $info $key] == -1 } { 
      ns_set put $info $key [eval $procname]
    }

    return [ns_set get $info $key]

  } else {

    return $info
  }
}

# Look for a value in the group cache, or call proc if it is not
# there.

proc ad_util_get_group_info { group_id { key "" } { procname "" } } {

  ns_share ad_group_cache

  set info [ns_set get $ad_group_cache $group_id]

  if { $info == "" } {

    set query "select * from user_groups where group_id = $group_id"
    set info [ad_dbquery onerow $query]

    if { $info != "" } {

      set info [ad_util_create_persistent_set $info]

      ns_share ad_group_short_name_cache
      set short_name [ns_set get $info short_name]
      ns_set update $ad_group_short_name_cache $short_name $info
    }

    ns_set put $ad_group_cache $group_id $info
  }

  if { ! [empty_string_p $key] } {

    if { [ns_set find $info $key] == -1 } { 
      ns_set put $info $key [eval $procname]
    }

    return [ns_set get $info $key]

  } else {

    return $info
  }
}

proc ad_util_get_group_info_by_short_name { short_name { key "" } } {

  ns_share ad_group_short_name_cache

  set info [ns_set get $ad_group_short_name_cache $short_name]

  if { $info == "" } {

    set query "select group_id from user_groups 
               where short_name = '$short_name'"

    set group_id [ad_dbquery onevalue $query]
    set info [ad_util_get_group_info $group_id]
  }

  if { ! [empty_string_p $key] } {
    return [ns_set get $info $key]
  } else {
    return $info
  }
}

# Get a list of group members

proc ad_util_get_group_members { group_id } {

  return [ad_util_get_group_info $group_id users \
      { ad_util_get_group_members_query $group_id } ]
}

proc ad_util_get_group_members_query { group_id } {

  set query "select user_id from user_group_map 
             where group_id = $group_id"

  return [ad_dbquery onelist $query]
}

proc ad_util_get_group_name { group_id } {

  set query "select group_name from user_groups 
             where group_id = $group_id"

  return [ad_dbquery onevalue $query]
}

proc ad_util_clear_group_info { key group_id } {

  ns_share ad_group_cache

  set info [ns_set get $ad_group_cache $group_id]

  if { $info != "" } { 
    ns_set delkey $info $key
  }
}

proc ad_util_group_url { { url "" } } {

  if { [empty_string_p $url] } {
    set url [ns_conn url]
  }

  # Parse the URL

  set exp {/([^/]*)/([^/]*)/(.*)}
  if { ! [regexp $exp $url x first_part second_part rest] } {
    return $url
  }

  # Test for the public groups directory

  if { [string compare $first_part [ug_url]] != 0 } {

    # Test for a special group type handler

    set type_info [ad_util_get_group_type_info $first_part]

    # If the first part of the URL does not correspond to a 
    # user group type, then this is not a scoped URL.
    if { $type_info == "" } { return $url }

    # If the group type does not use the virtual directory feature,
    # then assume this is not a scoped URL    
    if { [ns_set get $type_info has_virtual_directory_p] != "t" } {
      return $url
    }

    set pubdir [ns_set get $type_info group_public_directory]

    if { [empty_string_p $pubdir] } { 
      set url "[ug_url]/group/$rest"
    } else {
      set url "$pubdir/$rest"
    }

  } else {

    set url "[ug_url]/group/$rest"
  }

  # Now we are dealing with a group URL

  # Get a cached copy of the group info

  upvar #0 groupinfo groupinfo 
  set groupinfo [ad_util_get_group_info_by_short_name $second_part]

  return $url
}

# * * * * USER PROCEDURES * * * *

# Query a list of user names.  Use the id option to return a list
# of duplets in the form { name id }

proc ad_util_get_user_names { args } { 

  ad_util_set_args id_list

  if { [llength $id_list] == 0 } { return [list] }

  if { [info exists id_p] } {
    set id_clause ", user_id"
  } else {
    set id_clause ""
  }

  set query "
    select 
      first_names || ' ' || last_name as name $id_clause
    from
      users
    where
      user_id in ([join $id_list ","])
  "

  if { [info exists id_p] } {
    return [ad_dbquery multilist $query]
  } else {
    return [ad_dbquery onelist $query]
  }
}  

# Look for a value in the user value cache, or call proc if it is not
# there.

proc ad_util_get_user_info { { key "" } { procname "" } { user_id "" } } {

  ns_share ad_user_cache

  if {[empty_string_p $user_id]} {
    set user_id [ad_get_user_id]
  }

  set info [ns_set get $ad_user_cache $user_id]

  if { $info == "" } {

    set query "select first_names, last_name, email, user_id from users
               where user_id = $user_id"

    set info [ad_dbquery onerow $query]
    if { $info != "" } { 
      set info [ad_util_create_persistent_set $info]
    } else {
      set info [ns_set create -persist]
    }
  }

  ns_set put $ad_user_cache $user_id $info

  if { ! [empty_string_p $key] } {

    if { [ns_set find $info $key] == -1 && ! [empty_string_p $procname] } { 
      ns_set put $info $key [eval $procname]
    }

    return [ns_set get $info $key]

  } else {

    return $info
  }
}

proc ad_util_clear_user_info { key { user_id "" } } {

  ns_share ad_user_cache

  if {[empty_string_p $user_id]} {
    set user_id [ad_get_user_id]
  }

  set info [ns_set get $ad_user_cache $user_id]

  if { $info != "" } { 
    ns_set delkey $info $key
  }
}

# Queries the groups to which a person belongs

proc ad_util_get_user_groups { { user_id "" } } {

  return [ad_util_get_user_info user_groups \
      { ad_util_get_user_groups_query $user_id } $user_id]
}

proc ad_util_get_user_groups_query { user_id } {

  set query "
    select 
      group_id
    from 
      user_group_map
    where 
      user_id = $user_id
  "

  set groups [ad_dbquery onelist $query]

  return $groups
}

ns_share -init { 

  set ad_user_cache [ns_set create -persist ad_user_cache]

} ad_user_cache

ns_share -init { 

  set ad_group_cache [ns_set create -persist ad_group_cache]

} ad_group_cache

ns_share -init { 

  set ad_group_short_name_cache [ns_set create -persist]

} ad_group_short_name_cache

ns_share -init { 

  set ad_group_type_cache [ns_set create -persist ad_group_type_cache]

} ad_group_type_cache

proc_doc ad_preference { command { name "" } { value "" } } "

  Gets or sets a named preference from the ad_prefs cookie.

" {

  global prefs
  if { ! [info exists prefs] } {
    set prefs [ad_util_parse_query [ns_urldecode [ad_util_get_cookie ad_prefs]]]
  }

  switch $command {

    get {
      if { [ns_set find $prefs $name] != -1 } {
	set value [ns_set get $prefs $name]
      }
    }

    set {
      ns_set update $prefs $name $value
      set cookie [ns_urlencode [ad_util_build_query $prefs]]
      ad_util_set_cookie persistent ad_prefs $cookie
    }

    restore {
      set user_id [ad_get_user_id]
      if { $user_id == 0 } { set user_id $name }

      set query "select name, value from ad_user_preferences 
                 where user_id = $user_id"
      foreach row [ad_dbquery multirow $query] {
	ad_util_set_variables $row
	ns_set update $prefs $name $value
      }
      set cookie [ns_urlencode [ad_util_build_query $prefs]]
      ad_util_set_cookie persistent ad_prefs $cookie
    }

    save {

#      set db [ns_db gethandle]

      db_with_handle db {

	ns_db dml $db "begin transaction"

	set row [ns_set create]

	set user_id [ad_get_user_id]
	ns_set put $row user_id $user_id

	foreach key [ad_util_get_keys $prefs] {

	  ns_set update $row value [ns_set get $prefs $key]
	  ns_set update $row name $key

	  ad_dbstore ad_user_preferences {user_id name} $row $db
	}

	ns_db dml $db "end transaction"
      }

#      ns_db releasehandle $db
    }

    default {
      error "Invalid command option to ad_preference"
    }
  }

  return $value
}

