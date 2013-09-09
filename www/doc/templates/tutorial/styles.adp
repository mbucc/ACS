<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id styles.adp,v 1.1.1.1 2000/08/08 07:24:59 ron Exp
}
%>

<html>
<head>
<title>
Dynamic Publishing System
</title>
</head>
<body>

<h2>
Applying Styles
</h2>

part of a tutorial on the <a href="index.adp">Dynamic Publishing System</a> 
by <a href="mailto:karlg@arsdigita.com">Karl Goldstein</a>

<hr>

<p>One of the core issues addressed by this templating system is the
need to apply different styles to the same underlying data.  Common
applications for this capability include versions with and without
graphics, versions for specific browsing devices such as PDA's, and
versions in multiple languages.</p>

<p>The basic process by which a style is applied to a page is as 
follows:</p>

<ul> 

<li>The client submits a request for a standard URL, such as
<tt>home.adp</tt>.

<li>The template system process the data sources in the specification
file associated with home.adp.

<li>If the <tt>style</tt> property is specified in the specification,
the system does not try to parse a file named <tt>home.adp</tt>.
Instead, it runs a specified proc or chunk of code to obtain one
of several alternate templates.  The process by which this reference
is obtained is entirely up to the publisher.  It may use any
combination of cookie values, database queries and other data.

<li>The alternate template file is parsed and returned to the user.
The alternate template is itself a dynamic template, so that specific
data sources may be added to it in addition to the global data sources
specified in the template for the public URL.</li>

</ul>

<p>This lesson illustrates  a simple example of how a publisher might
tailor the appearance of a page to suit the whims of different clients,
while maintaining control over the data presented on the page.</p>

</p>

<h3>Create the specification file</h3>

<p>Create a file named <tt>contacts.data</tt> in a test directory of
your server and enter the following specification:</p>

<%=[ad_util_get_source "samples/contacts.data"]%> 

<p>
Note that we have specified a style handler as one of the general
properties of this template.  This particular style handler 
simply returns the value of a CGI query parameter.  This value
is transformed into the file path for a specific template to use
for this page request.  The algorithm for achieving this transformation
will depend on your site.  In this case 
</p>

<p><a href="samples/contacts.data">View the data dictionary</a></p>

<h3>Create the template</h3>

<p>Here is what the XYZ template (one of the two possible templates)
looks like:</p>

<%=[ad_util_get_source "samples/contacts-xyz.adp"]%> 

<p><a href="samples/contacts.adp?company_code=xyz">View results (Company XYZ)</a></p>

<p><a href="../show-source.tcl?url=tutorial/samples/contacts-abc.adp">View the source for the alternate template (Company ABC)</a></p>

<p><a href="samples/contacts.adp?company_code=abc">View results (Company ABC)</a></p>

<a href="index">Tutorial Contents</a>

<hr>

<a href="mailto:karlg@arsdigita.com">karlg@arsdigita.com</a>













