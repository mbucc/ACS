

New NSV Interface:
------------------
January, 2000


The new nsv interface of AOLserver 3.0 was added to provide a high
performance, more flexible alternative to ns_share.  The model is
similar to the existing (and undocumented) ns_var command but uses an
array syntax and includes more features.


Basics:
-------

The following commands currently make up the nsv interface:

    	nsv_get - get key value 
    	nsv_exists - check key existence
    	nsv_set - set key value
    	nsv_append - append value
    	nsv_lappend - append value as list element
    	nsv_incr - increment and return value
    	nsv_unset - unset a value
    	nsv_array - manage nsv arrays

Commands for the most part mirror the cooresponding Tcl command for
ordinary variables.  Basically, to set a value, simply use the nsv_set
command:

	nsv_set myarray foo $value

and to get a value, simply use the nsv_get command:

	set value [nsv_get myarray foo]



Migrating From ns_share:
------------------------

Migrating from ns_share is straightforward.  If your init.tcl included
commands such as:

	ns_share myshare
	set myshare(lock) [ns_mutex create]

use instead:

	nsv_set myshare lock [ns_mutex create]

In your procedures, instead of:

	proc myproc {} {
		ns_share myshare

		ns_mutex lock $myshare(lock)
		...

use:

	proc myproc {} {
		ns_mutex lock [nsv_get myshare lock]
		...

and within an ADP page, instead of:

	<%
	ns_share myshare
	ns_puts $myshare(key1)
	%>

	<%=$myshare(key2)%>

use:

	<%
	ns_puts [nsv_get myshare key1]
	%>

	<%=[nsv_get myshare key2]%>


Notice that, unlike ns_share, no command is required to define the
shared array.  The first attempt at setting the variable through any
means will automaticaly create the array.  Also notice that only arrays
are supported.  However, to migrate from ns_share you can simply package
up all existing ns_share scalars into a single array with a short name,
perhaps just ".". For example, if you had:

	ns_share mylock myfile
	set myfile /tmp/some.file
	set mylock [ns_mutex create]

you can use:

	nsv_set . myfile /tmp/some.file
	nsv_set . mylock [ns_mutex create]


Multithreading Features:
------------------------

One advantages of nsv is built in interlocking for thread safety.
For example, consider a case of a "increment-by-one" unique id system.
Here's the ns_share solution:

	ns_share ids
	set ids(lock) [ns_mutex create]
	set ids(next) 0

	proc nextid {} {
		ns_share ids

		ns_mutex lock $ids(lock)
		set next [incr ids(next)]
		ns_mutex unlock $ids(lock)
		return $next
	}

and here's an nsv solution:

	nsv_set ids next 0

	proc nextid {} {
		return [nsv_incr ids next]
	}

Note that the nsv solution does not need a mutex as the nsv_incr command
is internally interlocked.


Compatibility with Tcl Arrays:
------------------------------

Another useful feature of nsv is the nsv_array command which works much
like the Tcl array command.  This can be used to import and export values
from ordinary Tcl arrays.  For example, to copy from Tcl use:

	nsv_array set meta [array get tmpmeta]

and to copy to Tcl use:

	array set metacopy [nsv_array get meta]

As with all other nsv command, nsv_array is atomic and no explicit
locking is required.  This feature can be used to contruct a new nsv
array by first filling up an ordinary temporary Tcl array via some time
consuming process and then swapping it into place as above.  While the
new temporary array is being constructed, other threads can access the
old array without delay or inconsistant data.  You can even reset a
complete nsv array in one step with "reset".  For example, instead of:

	ns_share lock meta
	set lock [ns_mutex create]

	ns_mutex lock $lock
	unset meta
	array set meta [array get tmpmeta]
	ns_mutex unlock $lock

you can simply use:

	nsv_array reset meta [array get tmpmeta]

The reset option will flush and then reset all values atomically,
eliminating the need for the explicit lock.

Other options for the nsv_array command include:

	nsv_array exists array - test existance of array
	nsv_array size array - return # of elements in array
	nsv_array names array - return keys of array


Configuration:
--------------

The nsv system uses a common multithreading technique to reduce the
potential for lock contention which is to split the locks to acheive
finer grained locking.  This technique groups arrays randomly into
buckets and only the arrays within a particular bucket share a lock.
The number of buckets to be used can be configured by setting the
"nsvbuckets" tcl parameters, e.g.:

	[ns/server/server1/tcl]
	nsvbuckets=20

The default is 8 which should be reasonalbe.  Note that you can monitor
the lock contention, if any, by enabling mutex metering:

	[ns/threads]
	mutexmetering=on

and then viewing the results of "ns_info locks" command after the server
has been running for some time.  The nsv locks all have names of the
form "nsv:##".  If you find many lock attempts which did not successed
immediately, try increasing nsvbuckets.


Feedback:
---------

Please send any feedback, including ideas for additional features,
to feedback@aolserver.com.
