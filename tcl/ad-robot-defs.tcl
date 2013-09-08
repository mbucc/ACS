# ad-robot-defs.tcl
ad_library {
    @author Michael Yoon (michael@yoon.org)
    @creation-date 27-MAY-1999
    @cvs-id ad-robot-defs.tcl,v 3.4.2.5 2000/10/07 22:38:35 dennis Exp
}

proc_doc ad_replicate_web_robots_db {} {
Replicates data from the Web Robots Database (http://info.webcrawler.com/mak/projects/robots/active.html) into a table in the ACS database. The data is published on the Web as a flat file, whose format is specified in http://info.webcrawler.com/mak/projects/robots/active/schema.txt. Basically, each non-blank line of the database corresponds to one field (name-value pair) of a record that defines the characteristics of a registered robot. Each record has a "robot-id" field as a unique identifier. (There are many fields in the schema, but, for now, the only ones we care about are: robot-id, robot-name, robot-details-url, and robot-useragent.)\n<p>Returns the number of rows replicated. May raise a Tcl error that should be caught by the caller.
} {
    set web_robots_db_url [ad_parameter WebRobotsDB robot-detection]

    set result [ns_geturl $web_robots_db_url headers]
    set page [split $result "\n"]

    # A set in which to store the fields of a record as we
    # process the file.
    set robot [ns_set create]

    set robot_count 0
    foreach line $page {
	# A "robot-id" line delimits a new record, so each
	# time we encounter one, we need to write the prior
	# record (if there is one) into the database. There
	# is only case in which there will *not* be a prior
	# record, i.e., for the very first record.
	#
	if [regexp "robot-id: *(.+)" $line match robot_id] {
	    set prior_robot_id [ns_set get $robot "robot_id"]
	    if ![empty_string_p $prior_robot_id] {
		# As long as there is an actual value for
		# "robot_useragent", load the record, i.e.,
		# update it if a record with the same
		# robot_id already exists or insert it if
		# one does not. (There's no point in keeping
		# info about robots that we can't identify.)
		#
		set robot_useragent [ns_set get $robot "robot_useragent"]
		set robot_name [ns_set get $robot "robot_name"]
		set robot_details_url [ns_set get $robot "robot_details_url"]
		if ![empty_string_p $robot_useragent] {
		    if [robot_exists_p $prior_robot_id] {
			ns_log Notice "Updating existing robot: $robot_id"
			db_dml robot_record_update "
                                       update robots 
                                       set robot_name = :robot_name, 
                                           robot_details_url = :robot_details_url, 
                                           robot_useragent = :robot_useragent,
                                           modified_date = sysdate 
                                       where robot_id = :prior_robot_id"
		    } else {
			ns_log Notice "Inserting new robot: $robot_id"
			db_dml robot_record_insert "
                                       insert into robots
                                       (robot_id, robot_name, robot_details_url, robot_useragent, insertion_date) 
                                       values
                                       (:prior_robot_id, :robot_name, :robot_details_url, :robot_useragent, sysdate)"
		    }
		    incr robot_count
		}

		# Clear out the record so we can start anew.
		ns_set delkey $robot "robot_id"
		ns_set delkey $robot "robot_name"
		ns_set delkey $robot "robot_details_url"
		ns_set delkey $robot "robot_useragent"
	    }
	    ns_set put $robot "robot_id" [string trim $robot_id]
	}
	
	if [regexp "robot-name: *(.+)" $line match robot_name] {
	    ns_set put $robot "robot_name" [string trim $robot_name]
	}
	
	if [regexp "robot-details-url: *(.+)" $line match robot_details_url] {
	    ns_set put $robot "robot_details_url" [string trim $robot_details_url]
	}

	if [regexp "robot-useragent: *(.+)" $line match robot_useragent] {
	    ns_set put $robot "robot_useragent" [string trim $robot_useragent]
	}
    }

    # Don't forget the last record.
    #
    set robot_useragent [ns_set get $robot "robot_useragent"]
    set robot_name [ns_set get $robot "robot_name"]
    set robot_details_url [ns_set get $robot "robot_details_url"]
    if ![empty_string_p $robot_useragent] {
	if [robot_exists_p $prior_robot_id] {
	    ns_log Notice "Updating existing robot: $robot_id"
	    db_dml robot_record_update "update robots 
                                        set robot_name = :robot_name, 
                                            robot_details_url = :robot_details_url, 
                                            robot_useragent = :robot_useragent, 
                                            modified_date = sysdate 
                                        where robot_id = :prior_robot_id"
	} else {
	    ns_log Notice "Inserting new robot: $robot_id"
	    db_dml robot_record_insert "insert into robots
                                        (robot_id, robot_name, robot_details_url, robot_useragent, insertion_date) 
                                        values
                                        (:prior_robot_id, :robot_name, :robot_details_url, :robot_useragent, sysdate)"
	}
	incr robot_count
    }
    return $robot_count
}

proc_doc ad_cache_robot_useragents {} {Caches "User-Agent" values for known robots} {
    ns_share ad_robot_useragent_cache
    db_foreach { select robot_useragent from robots } {
	set ad_robot_useragent_cache($robot_useragent) 1
    }
}

proc_doc robot_exists_p {robot_id} {Returns true if a row already exists in the robots table with the specified "robot_id"} {
    return [db_string robot_exists "select count(*) from robots where robot_id = :robot_id"]
}

proc_doc robot_p {useragent} {Returns true if the useragent is recognized as a search engine} {
    ns_share ad_robot_useragent_cache

    # Memoize so we don't need to query the robots table for every single HTTP request.
    util_memoize ad_cache_robot_useragents

    if {[info exists ad_robot_useragent_cache($useragent)]} {
	return 1
    } else {
	return 0
    }
}

proc_doc ad_robot_filter {conn args why} {A filter to redirect any recognized robot to a specified page} {
    set useragent [ns_set get [ns_conn headers] "User-Agent"]

    if [robot_p $useragent] {
	set robot_redirect_url [ad_parameter RedirectURL robot-detection]
	# Be sure to avoid an infinite loop of redirects. (Actually, browsers
	# won't look infinitely; rather, they appear to abort after a URL
	# redirects to itself.)
	if { [string first $robot_redirect_url [ns_conn url]] != 0 } {
	    # requested URL does not start with robot redirect URL (usually a dir)
	    ns_log Notice "Robot being bounced by ad_robot_filter: User-Agent = $useragent"
	    ad_returnredirect $robot_redirect_url
	    set result "filter_return"
	} else {
	    # we've got a robot but he is happily in robot heaven
	    set result "filter_ok"
	}
    } else {
	set result "filter_ok"
    }

    return $result
}

proc_doc ad_update_robot_list {} {
Will update the robots table if it is empty or if the number of days since it was last updated is greater than the number of days specified by the RefreshIntervalDays configuration parameter in the "robot-detection" section
} {
    
    if [catch {
        set robot_count [db_string robot_count "select count(*) from robots"]
        if {$robot_count == 0} {
            ns_log Notice "Replicating Web Robots DB, because robots table is empty"
            db_transaction {
		ad_replicate_web_robots_db
            }
        } else {
            # refresh every 30 days by default
            set refresh_interval [ad_parameter RefreshIntervalDays robot-detection 30]
            
            set days_old [db_string robot_table_days_old {
                select trunc(sysdate - max(nvl(modified_date, insertion_date))) as n_days 
                  from robots
            }]
            if {$days_old > $refresh_interval} {
                ns_log Notice "Replicating Web Robots DB, because data in robots table has expired"
                db_transaction {
                    ad_replicate_web_robots_db
                }
            } else {
                ns_log Notice "Not replicating Web Robots DB at this time, because data in the robots table has not expired"
            }
        }
    } errmsg] {
        ad_notify_host_administrator "Error encountered in ad_update_robot_list" $errmsg
        return
    }
}

# Check to see if the robots table needs to be updated
# when the server starts (5 seconds after to be precise).
ad_schedule_proc -once t 5 ad_update_robot_list

# Install ad_robot_filter for all specified patterns
ns_share -init {set robot_filters_installed 0} robot_filters_installed
if {!$robot_filters_installed} {
    set robot_filters_installed 1
    foreach filter_pattern [ad_parameter_all_values_as_list FilterPattern robot-detection] {
	ns_log Notice "Installing robot filter for $filter_pattern"
	ad_register_filter postauth GET $filter_pattern ad_robot_filter
    }
}
