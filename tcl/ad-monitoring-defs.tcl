# /tcl/ad-monitoring-defs.tcl
ad_library {
    Utilities for general system monitoring

    @cvs-id  ad-monitoring-defs.tcl,v 3.16.2.4 2000/09/11 00:34:11 kevin Exp
    @author  mbryzek@arsdigita.com
    @author  sklein@arsdigita.com
}



proc_doc ad_monitor_format_kb { num } {
    format_kb takes in an integer, assumed to be a size value in
    kilobytes, and returns a prettily formatted value followed by
    a descriptive quantifier. 
} {
    if {$num < 0} {
	return [format "%5.1f Kb" [util_commify_number $num]]
    } else {
	switch [expr {([string length $num] - 1) / 3}] {
	    0   { return [append num  " Kb"] }
	    1   { return [format "%5.1f Mb" [expr {$num / 1000.0}]] }
	    default { return [format "%5.1f Gb" [util_commify_number [expr {$num / 1000000.0}]]] }
}   }   }


proc_doc ad_monitor_top {} { 
    ad_monitor_top parses the output from
    "top" and stores the results in a table. This is useful to later
    create reports of load averages and memory usage in a time-sensitive
    way.

    Required Parameters in the monitoring section:
      * TopLocation: Full path to execute top

    Optional Parameters:
      * LoadAverageAlertThreshold: Minimum load average before emailing
        persons to notify that the machine is overloaded

} {
    
    # list indicating the order in which top outputs data
    set proc_var_list [list pid username threads priority nice proc_size \
                       resident_memory state cpu_total_time cpu_pct command]
    # location of the desired top function
    set top_location [ad_parameter TopLocation monitoring]

    # make sure we have a path to top and that the file exists
    if { [empty_string_p $top_location] } {
	ns_log Error "ad_monitor_top: cannot find top; TopLocation parameter in monitoring 
                      is not defined"
	return
    } elseif { ![file exists $top_location] } {
	ns_log Error "ad_monitor_top: Specified location for top ($top_location) does not exist"
	return
    }

    # set top_output [exec $top_location]
    if [catch { set top_output [exec $top_location] } errmsg] {
        # couldn't exec top at TopLocation
        if { ![file exists $top_location] } {
                ad_return_error "top not found" "
    The top procedure could not be found at $top_location:
    <blockquote><pre> $errmsg </pre></blockquote>"
                return
        }
        ad_return_error "insufficient top permissions" "
    The top procedure at $top_location cannot be run:
    <blockquote><pre> $errmsg </pre></blockquote>"
        return
    }
    # else top execution went ok
    set top_list [split $top_output "\n"]

    ## Run through the output of top, grab header lines and leave the rest. 
    # number of header lines grabbed
    set ctr 0   	
 
    # greet the database
    

    # id for this iteration of top-parsing
    set top_id [db_string top_id_select "select ad_monitoring_top_top_id.nextval from dual"]

    # have we reached the list of process info yet?    
    set procflag 0	
    foreach line $top_list {

	if { $procflag > 0 } {
	    #compress multiple spaces
    	    regsub -all {[ ]+} [string trim $line] " " line    
            set proc_list [split $line]

	    #skip blank lines
            if { [llength $proc_list] < 2 } { continue } 
            if { [llength $proc_list] < 11 } { 
		ns_log Notice "skipping top process line: 
                     element list shorter than variable list."
		continue 
	    }
		
	    #set proc-related vars
 	    set pid       [lindex $proc_list 0]
	    set username  [lindex $proc_list 1]
	    set threads   [lindex $proc_list 2]
	    set priority  [lindex $proc_list 3]
	    set nice      [lindex $proc_list 4]
	    set proc_size [lindex $proc_list 5]
	    set resident_memory [lindex $proc_list 6]
	    set state           [lindex $proc_list 7]
	    set cpu_total_time  [lindex $proc_list 8]
	    set cpu_pct   [lindex $proc_list 9]
	    set command   [lindex $proc_list 10]

	    db_dml top_proc_info_insert "
	    insert into ad_monitoring_top_proc
	    (proc_id, top_id, pid, command, username, 
	      threads, priority, nice, proc_size, 
	      resident_memory, state, cpu_total_time, cpu_pct) 
 	    values 
	    (ad_monitoring_top_proc_proc_id.nextval, :top_id, :pid, 
	      :command, :username, :threads, :priority, :nice, :proc_size,  
	      :resident_memory, :state, :cpu_total_time, :cpu_pct)" 

	    continue   

	} elseif { [regexp -nocase {(.*PID.USERNAME.*)} $line match top_header] } {
	    ## this is the start of proc info lines
            incr procflag

	    continue

        } elseif { [regexp -nocase {load av[a-z]*: (.*)} $line match load] } {
	    ## this is the load header 
	    incr ctr

	    # remove commas, multiple spaces
    	    regsub -all {,} [string trim $load] "" load   
    	    regsub -all {[ ]+} $load " " load             

    	    set load_list [split $load " "]
    
    	    # We keep all three load avgs, ignore the time at the end of the line
    	    set load_1  [lindex $load_list 0]
	    set load_5  [lindex $load_list 1]
	    set load_15 [lindex $load_list 2]

	    # send out any high-load alerts
   	    if { $load_5 > [ad_parameter LoadAverageAlertThreshold monitoring 2.0] } {
              wd_email_notify_list "High Load Average on [ad_url]" \
                  "The load average over the last 5 minutes for [ad_url] was $load_5"
    	     } 

	} elseif { [regexp -nocase {mem[a-z]*: (.*)} $line match memory] } {
	    ## this is the memory header 
	    incr ctr
            foreach mem [split $memory ","] {
                regexp {^ *([^ ]*) (.*)} $mem match amount type
                set amount [string trim [string toupper $amount]]
               	# convert all mem values to Kilobytes 
                regsub {K$} $amount "" amount
                regsub {M$} $amount "000" amount

                set type [string trim [string tolower $type]]
                switch $type {
                    "real" { set memory_real $amount }
                    "free" { set memory_free $amount }
                    "swap free" { set memory_swap_free $amount }
                    "swap in use" { set memory_swap_in_use $amount }
                }
            } 
	}

	if {$ctr == 2 } {
 	    ## we have all the header information we currently store.
	    ## we should also store the rest of top's output... 
	    ## some of it can be gotten from the zoom package. 
	    db_dml top_misc_info_insert "insert into ad_monitoring_top
             (top_id, timestamp, timehour, load_avg_1, load_avg_5, load_avg_15,
              memory_real, memory_free, memory_swap_in_use, memory_swap_free)
            values
             (:top_id, sysdate, to_char(sysdate, 'HH24'), :load_1, :load_5, :load_15,
              :memory_real, :memory_free, :memory_swap_in_use, :memory_swap_free)"
	    incr ctr
	}
    # end of the foreach loop
    }

    if { $ctr < 2 } {
	# didn't even get load and memory lines from top
	ns_log Error "ad_monitor_top: Cannot parse output from top"
	return
    }
}


# TopFrequency determines how often this proc is run, in minutes.
# If this is run too often, it occasionally runs into memory
# allocation trouble when trying to exec top... 

set top_frequency [ad_parameter TopFrequency monitoring 0]
ns_log Notice "top_frequency is $top_frequency"

if { $top_frequency > 0 } {
	set top_frequency_in_seconds [expr 60 * $top_frequency]
	ad_schedule_proc $top_frequency_in_seconds ad_monitor_top
}



proc_doc ad_monitoring_analyze_tables {} {

    This procedure analyzes all the tables in the database. New tables
    are automatically added to the table "ad_monitoring_tables_estimated."
    If you want, you can disable estimates on particular tables by going
    to /www/admin/monitoring/analyze.

    The Parameter NumDaysToEstAllRows is used to specify how many days
    it should take to estimate statistics for all tables. For example, the
    default setting of 7 days means that each night, we will estimate
    statistics for 1/7th of the tables in the database.

    Written by kschmidt@arsdigita.com, 6/28/2000

} {

    # Are we even doing this?
    if {[ad_parameter AutoAnalyzeP monitoring 0]==0} {
	ns_log notice "ad_monitoring_analyze_tables: Not Analyzing Tables"
	return
    }
    
    #how many days should a complete scan take
    set numdays [ad_parameter NumDaysToEstAllRows monitoring 7]
    if {$numdays < 1} {
	ns_log error "ad_monitoring_analyze_tables: Parameter NumDaysToEstAllRows cannot be less than 1."
	return
    }
    
    # grab a handle
    #set db [ns_db gethandle subquery]
    
    # This is used to update the list of tables which should be analyzed
    # by checking to see if any new tables have been added to the database
    db_dml new_tables_to_be_analyzed_insert "insert into ad_monitoring_tables_estimated 
                   (table_entry_id, table_name)
                   select ad_monitoring_tab_est_seq.nextval,table_name 
                   from user_tables ut 
                   where not exists (select 1 
                      from ad_monitoring_tables_estimated amte
                      where upper(amte.table_name)=upper(ut.table_name))"

    # Grab the first fraction of rows, organized by the last time they 
    # were analyzed

    set alltables [db_list_of_lists tables_to_analayze_select_fraction "
        select table_name, percent_estimating,table_entry_id
        from (select amte.*
              from ad_monitoring_tables_estimated amte 
              where enabled_p='t'
              order by nvl(last_estimated, sysdate-100) asc)
        where rownum < (select count(*)/:numdays from ad_monitoring_tables_estimated)
    "]
    
    # Now we go through each item
    foreach table_item  $alltables {
	# Variables to be used JAva

	set entry_id [lindex $table_item 2]
	set table_name [lindex $table_item 0]
	set percent [lindex $table_item 1]

	#The string to execute.  
	set execstr "analyze table :table_name estimate statistics sample :percent percent"
	
        # for some reason this failed.. probably cause the table doesn't exists
        # anymore
	ns_log notice "Analyzing $table_name.."
	if {[catch {db_dml table_analyze $execstr} errmsg]} {
	    # Look up the table in user_tables
	    if { ![db_table_exists $table_name] } {
	        # The table wasn't listed.. so we disable this entry
		db_dml one_table_entry_disable_monitoring "update ad_monitoring set enabled_p='f' 
		    where table_entry_id=:entry_id" 
            } else {
		ns_log error "ad_monitoring_analyze_tables: Error while executing: $execstr"
	    }
        } else {
            #Change the last estimated, and continue looping
            db_dml one_table_entry_update_last_estimated "
              update ad_monitoring_tables_estimated
              set last_estimated=sysdate, 
                  last_percent_estimated=percent_estimating 
              where table_entry_id=:entry_id"
        } 
    } 
    db_release_unused_handles
} 

ns_schedule_daily -thread 20 48  ad_monitoring_analyze_tables

