# www/admin/spam/modify-daily-spam.tcl

ad_page_contract {

 Modify daily spam table

    @param file_prefix filename prefix for a periodic spam entry
    @param subject subject for the spam message
    @param user_class_id user_class_id for target recipients of this spam
    @param template_p t if Tcl substitution should be performed on message body
    @param day_of_week day of week to send spam 
    @param period period to send spam (daily, weekly, monthly, yearly)
    @param day_of_month day of month to send spam
    @param from_address from address for email header
    @param user_class_name pretty name of target recipients user class 

    @author hqm@arsdigita.com
    @cvs-id modify-daily-spam.tcl,v 3.3.6.5 2000/07/21 03:58:00 ron Exp
} {
    file_prefix:array
    subject:array
    user_class_id:array
    template_p:array,optional
    day_of_week:array
    period:array
    day_of_month:array
    from_address:array
    user_class_name:array,optional
}


db_transaction {
    db_dml delete_all_periodic_spams "delete from daily_spam_files"

    set iter 0

    while {[info exists user_class_id($iter)]} {
	if {[empty_string_p [set file_prefix($iter)]] || [empty_string_p [set subject($iter)]]} {
	    # ignore entries with null strings
	} else {

	    # For use as bind var, in following db_string command
	    set this_user_class_id [set user_class_id($iter)]

	    ns_log Notice "select name
	                          from user_classes
                                  where user_class_id  = $this_user_class_id"

	    set user_class_name [db_string user_class_name "select name
	                          from user_classes
                                  where user_class_id  = :this_user_class_id" ]

	    if {![info exists template_p($iter)]} {
		set template_p($iter) "f"
	    }

	    set bind_args [ns_set create]
	    ns_set put $bind_args "from_address" [set from_address($iter)]
	    ns_set put $bind_args "user_class_id" [set user_class_id($iter)]
	    ns_set put $bind_args "user_class_name" $user_class_name
	    ns_set put $bind_args "subject" [set subject($iter)]
	    ns_set put $bind_args "file_prefix" [set file_prefix($iter)]
	    ns_set put $bind_args "template_p" [set template_p($iter)]
	    ns_set put $bind_args "period" [set period($iter)]
	    ns_set put $bind_args "day_of_week" [set day_of_week($iter)]
	    ns_set put $bind_args "day_of_month" [set day_of_month($iter)]

	    db_dml update_all_spams  "insert into daily_spam_files
	       (from_address,
	       target_user_class_id,
	       user_class_description,
	       subject,
	       file_prefix,
	       template_p,
	       period,
	       day_of_week,
	       day_of_month) 
           values
	    (:from_address,
	    :user_class_id,
	    :user_class_name,
	    :subject,
	    :file_prefix,
	    :template_p,
	    :period,
	    :day_of_week,
	    :day_of_month)" -bind $bind_args
	}
	incr iter
    }
} on_error {
    ns_returnerror 500 "Error in updating daily_spam_files table: $errmsg"
    return
}

ad_returnredirect "show-daily-spam.tcl"