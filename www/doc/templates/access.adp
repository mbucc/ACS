<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id access.adp,v 1.1.1.1 2000/08/08 07:24:59 ron Exp
} {
}
%>

<html>
<head>
<title>
Dynamic Templates
</title>

<link rel=stylesheet href="style.css" type="text/css">

</head>
<body>
<h1>
Access Constraints
</h1>
Karl Goldstein (<a href="mailto:karlg@arsdigita.com">karlg@arsdigita.com</a>)
<hr>

<h3>Overview</h3>

<p>There are a variety of reasons why publishers may wish (or need) to
restrict access to specific pages:</p>

<ul>
<li>Information that only a specific class of users should see.
<li>Content made available on a subscription or pay-per-view basis.
<li>Submission pages from which naughty users should be banned.
<li>User services which require specific information that the user
has not yet provided (i.e. a page that gives the location of local animal
hospitals, but the user has not yet told us her zip code).
<li>Any arbitrary rule that a publisher may want to specify (i.e.
a page only for Libras who are older than 30 years old and live in 
California).
</ul>

<p>To address all these situations, the template system incorporates a
general page-level access control system that has the following
features:</p>

<ul> 

<li>Access constraints are specified in the template specification
file according to a standard format.  Each constraint consists of Tcl
code that may perform any type of checking desired.  In most cases,
the code will simply consist of a call to a proc written to handle
common types of constraints such as group-level access or subscription
control.  

<li>Access constraints and data sources are processed in the
same sequence in which they are written in the specification file.
Constraints that validate data sources (i.e. checking to
make sure that at least one row is returned, or that a column
value is not null) must be placed after the referenced data sources.
Constraints that depend only on the value of a cookie, or on
their own database queries, may be placed before any data sources
to avoid unnecessary processing.

<li>There may be any number of constraints placed on a page, 
corresponding to different conditions that may arise while
preparing the template.

<li>If access to the page is not permitted, then the code may
throw one of a set of predefined errors that the template system 
traps and process accordingly (see below).

</ul>

<h3>Constraint specification</h3>

<pre><% ns_puts [ns_quotehtml "
  <constraint>
    <name>constraint_name</name>
    <comment>constraint description</comment>
    <eval>
      ...constraint code...
    </eval>
  </constraint>
"]%></pre>

<h3>Standard access errors</h3>

<p>Registration required...</p>

<p>Invalid group</p>

<p>







