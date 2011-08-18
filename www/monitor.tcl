# $Id: monitor.tcl,v 3.0 2000/02/06 02:39:07 ron Exp $
# this program was written by Philip Greenspun (philg@mit.edu)
# it is free to everyone under the standard GNU Public License 

set connections [ns_server active]

# let's build an ns_set just to figure out how many distinct elts; kind of a kludge
# but I don't see how it would be faster in raw Tcl

set scratch [ns_set new scratch]
foreach connection $connections {
    ns_set cput $scratch [lindex $connection 1] 1
}

set distinct [ns_set size $scratch]


set whole_page "<html>
<head>
<title>Life on the [ns_info server] server</title>
</head>

<body bgcolor=#ffffff text=#000000>
<h2>Life on the [ns_info server] server</h2>
<hr>

There are a total of [llength $connections] requests being served
right now (to $distinct distinct IP addresses).  Note that this number
seems to include only the larger requests.  Smaller requests, e.g.,
for .html files and in-line images, seem to come and go too fast for
this program to catch.

<p>

"

if [util_aolserver_2_p] {
    append whole_page "
AOLserver says that the max number of threads spawned since server
startup is [ns_totalstats HWM-threads].  The max threads since the
last interval reset (every 5 minutes or so by default):
[ns_intervalstats HWM-threads].  This final number is probably the
best estimate of current server activity.

<p>
"
}

if [util_aolserver_2_p] {
    # run standard Unix uptime command to get load average (crude measure of 
    # system health)
    set uptime_output [exec /usr/bin/uptime]
    append whole_page "

Here's what uptime has to say about the box:

<pre>
$uptime_output
</pre>
"
}

append whole_page "

<table>
<tr><th>conn #<th>client IP<th>state<th>method<th>url<th>n seconds<th>bytes</tr>
"

foreach connection $connections {
    append whole_page "<tr><td>[join $connection <td>]\n"
}


append whole_page "</table>

<hr>
<a href=\"http://photo.net/philg/\"><address>philg@mit.edu</address></a>
</body>
</html>
"

ns_return 200 text/html $whole_page
