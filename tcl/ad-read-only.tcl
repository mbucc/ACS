ad_library {
    This page is for making the system read-only for maintenance
    purposes (i.e., if you're building a new Oracle installation
    and don't want users putting in orders, comments, etc., that 
    will be lost once you switch over to the new Oracle)

    @author ?
    @creation-date ?
    @cvs-id  ad-read-only.tcl,v 3.0.14.3 2000/09/22 01:33:57 kevin Exp
}

# THIS PROC decides whether the data base is in
# read-only mode.

proc_doc ad_read_only_p {} "" {
    # return 1 if you want the system to stop accepting user input
    # look in /web/yourdomain/parameters/ad.ini or return 0 if not found
    return [ad_parameter ReadOnlyP "" 0]
}

# This proc is called to generate
# the error message that explains what's up.

proc ad_return_read_only_maintenance_message {} {
    doc_return  200 text/html "[ad_header "System Maintenance"]

    <h2>We're Maintaining the Database</h2>
    <hr>
    
    We're sorry, but anything that you add to our database right now would
    be lost.  We'll be finished maintaining the database and expect the
    system to be back up and running 
    
    <blockquote>
    <strong>Monday, September 14th, 3:00 am (Eastern Time)</strong>
    </blockquote>
    <p>
    [ad_footer]
    "
}
