# tcl/ad-clickthrough.tcl

ad_library {
    logs clickthroughs from this site to foreign sites

    @author Philip Greenspun (philg@mit.edu)
    @creation-date 1997 
    @cvs-id ad-clickthrough.tcl,v 3.3.2.2 2000/07/22 09:01:07 ron Exp

    part of the ArsDigita Community System
    documented in /doc/clickthrough.tcl

    fixed by philg@mit.edu on November 24, 1999 to protect against
    inserting multiple rows on the first insert of the day
}

# usage: drop something that looks like this into your static .html
# files 
#
# /ct/**local_url**?send_to=**foreign_url**
#
# the initial /ct is what tells the AOLserver to come to this
# system of code.
#

# the rest of this system (reports) is located in /admin/click/ 

# if either the local URL or the foreign URL aren't known 
# in the database, the clickthough server creates a row

# in normal operation, the user is redirected immediately to the URL
# specified by the send_to variable.  Then the AOLserver thread
# requests a database connection and sends the insert to the database

# helper functions

# we register the entire hierarchy to this one function

ad_register_proc GET /ct click

# we provide this here for legacy users of philg's standalone clickthrough
# system (e.g., the old http://photo.net/photo/ site).  These sites had
# references that included a "realm", e.g., 
# http://clickthrough.photo.net/ct/philg/photo/where-to-buy.html?send_to=http://www.bhphotovideo.com

# in this case the "philg" after the "/ct/" is the realm.  So we need a different
# regexp, which we'll pull from the ad_parameters file

proc click {ignore} {
    set url_regexp [ad_parameter CustomREGEXP click {/ct/(.+)$}]
    if { ![regexp $url_regexp [ns_conn url] match local_url] || [ns_conn form] == "" || [ns_set find [ns_conn form] send_to]  == -1  || [ns_set get [ns_conn form] send_to] == "" } {
	     # we couldn't find the URL stub or there was no send_to
	ad_return_error "Reference Error" "Clickthroughs in [ad_system_name] are supposed to look like
<pre><code>
[ns_conn location]/ct/**local_url**?send_to=**foreign_url**
</pre></code>

This request looked like
<pre><code>
[ns_conn request]
</pre></code>
[ad_footer]"
        return
    }

    # realm and local_url were set by the REGEXP
    set foreign_url  [ns_set get [ns_conn form] send_to]
    # sometimes the foreign_url is malformed, notable just "http"
    if { $foreign_url == "http" } {
	an_return_error "Redirected to HTTP only" "You were redirected to just \"http\"; the way that we do clickthroughs here requires your browser to be a little bit liberal about how it handles URLs.  Your browser apparently isn't.  If you go back to the preceding page and View Source, you can probably tease out the target URL and go there manually with an Open command."
	return
    }
    ad_returnredirect $foreign_url
    # user is off our hands now; time to log
    # we regexp'd sucessfull
#      if { [catch { set db [ns_db gethandle -timeout -1 log] } errmsg] || [empty_string_p $db] } {
#  	# the non-blocking call to gethandle raised a Tcl error; this
#  	# means a db conn isn't free right this moment, so let's just
#  	# return
#  	ns_log Notice "Db handle wasn't available in click"
#  	return
#      }
    # we connected to the database successfully

    set update_sql "update clickthrough_log set click_count = click_count + 1 
where local_url = :local_url 
and foreign_url = :foreign_url
and trunc(entry_date) = trunc(sysdate)"

    db_dml update $update_sql -bind [ad_tcl_vars_to_ns_set local_url foreign_url]
    set n_rows [db_resultrows]
    if { $n_rows == 0 } {
	# there wasn't already a row there
	# let's insert one (but only one; in the very rare case that another thread is executing
	# this same code, we don't want to be left with two rows in the database for the same
	# tuple)

	set insert_sql "insert into clickthrough_log ( local_url, foreign_url, entry_date, click_count)
            select :local_url, :foreign_url, trunc(sysdate), 1
            from dual
            where 0 = (select count(*)
                       from clickthrough_log
                       where local_url = :local_url 
                       and foreign_url = :foreign_url
                       and trunc(entry_date) = trunc(sysdate))"

        if [catch { db_dml insert $insert_sql -bind [ad_tcl_vars_to_ns_set local_url foreign_url]} errmsg] {
	    ns_log Notice "Clickthrough insert failed:  $errmsg"
	}
    }
    db_release_unused_handles
}

