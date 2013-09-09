<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id overview.adp,v 1.1.1.1 2000/08/08 07:24:59 ron Exp
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
Overview
</h2>

of the <a href="index">Dynamic Publishing System</a> 
by <a href="mailto:karlg@arsdigita.com">Karl Goldstein</a>

<hr>
<div align=right>
<a href="spec">Next</a> | 
<a href="index">Top</a> 
</div>

<h3>The Problem</h3>

<p>The traditional way to create dynamic pages for AOLserver 
was to write "pages that are really programs," mixing Tcl code, 
database queries and HTML in a single file.  This approach was
convenient under the following conditions:</p>

<ul>
<li>when a single person dealt with both the programming and 
page layout.
<li>When a single presentation of the content was sufficient.
</ul>

<p>Alas, the world of web publishing is not so monotonic 
these days.  Most web publishing teams are faced with the following
dilemma(s):</p>

<ul> 

<li><p>The process of creating a page is no longer in the lone hands
of the programmer.  Page templates are usually designed by graphic
artists, UI experts, and their associated journeymen.  Programmers
must wire their code into the complex templates handed to them by
designers, and then pray that no one asks for any formatting
changes once they are finished.  Furthermore, every publisher
wants their pages to look different even if the functionality
is the same, requiring changes to the code for each project.</p>

<li><p>As the Web truly becomes World Wide, the need to present the
same content in different ways is becoming increasingly important.
This includes both publishing in different languages as well as
publishing for different devices, such as cell phones and home
internet appliances.</p>

</ul>

<p>The complexities of contemporary web publishing demand more
attention to improving productivity and collaboration among all
members of the team.  Programmers need better ways to reuse code and
avoid the need for constant changes with every change to the
formatting of a page.  On the other side of the fence,
designers need the freedom to change the look and feel of a page
without having to consult with the programmer.</p>

<h3>The Goals of this System</h3>

<p>Within the context of the ACS, a good solution to this problem
should possess the following characteristics:</p>

<ul>

<li><p><b>A high level of abstraction.</b>  Programmers and 
designers should only have to learn a single system that
serves as a substrate for all the functionally specific modules
in the toolkit.  The system should not make any assumptions
about how pages should look or function.</p>

<li><p><b>Separation of page components.</b> There should be
provisions so that pages can be broken into discrete components to
simplify maintenance of the HTML code and allow for reuse in
different contexts.  Examples of common page components include a
navigation bar, a search box, or a section of a report or story.</p>

<li><p><b>Global control over site format.</b>  There should be a
way to define one or more standard master templates used by most
pages on a site, so that changes to the overall look and feel of a
site can be made in one place.</p>

<li><p><b>Separation of code (Tcl and SQL) and layout (HTML).</b>
Programmers should be able to develop a formal data
specification that describes properties of the template as well as
any dynamic content the template may present.  HTML experts should be
able to lay out pages by referencing the dynamic content, without
requiring any assistance from the programmer to integrate a static
template with dynamic content.</p>

<li><p><b>Dynamic selection of presentation style.</b> Given that more
than one template may be created for each template specification, there
should be a general mechanism for selecting a specific presentation
style for each page request, depending on characteristics such as
user preference, location, browser type and/or device.</p>

<li><p><b>Usability.</b>  Programmers should be able to develop template
specifications using their standard tools for writing and maintaining code
on the server.  HTML experts should be able to access information 
about template specifications and work on templates remotely without needing
shell access to the server.</p>

<li><p><b>Integration with other tools.</b> Beyond the templating
system itself, many other tools may benefit from maintaining a
database of properties for each page on a site.  The template
specification should therefore be easily extensible so that other
tools may refer to it for other types of information.
Opportunities for such integration include:</p>

<ul>
<li>Specification of a page's location within a hierarachical view of
the site, for creation of standardized
navigation bars and site maps.
<li>Group- and user-level access control to the page, for the purposes
of privacy as well as for assessing usage fees.
</ul>

</p>

</ul>

<h3>Data Organization</h3>

<p>Considering the goals stated above, the core data components of
the system include the following:</p>

<ul>

<li><p><b>Specification files</b>.  To enable programmers to use Emacs
and CVS to build and maintain templates specifications, they are
stored in regular text files.  Specification files always carry the
<tt>data</tt> extension to identify them for parsing and browsing.
They are written as well-formed XML documents, using a standard <a
href="spec">specification</a> that is extensible to
accomodate customization.  I chose XML as the format because it is
widely familiar to web developers and is easy to parse.</p>

<li><p><b>Template files</b>.  HTML templates are also stored as text
files, to enable HTML specialists to work remotely via FTP.  The
templates are purely HTML without the need for any embedded code.
They use a small set of <a href="tags">custom markup tags</a> to
reference the data sources listed in the corresponding specification
file.  Any number of templates may reference the same specification
file.</p>

<p>Templates do not necessarily represent complete pages.  They may be
discrete components of a page, thus maximizing the potential for
maintaining consistency across an entire site.  A custom markup tag is
used to include templates within other templates.</p>

<li><p><b>Content</b>.  To the extent that it is feasible, the HTML
templates themselves do not contain specific content, but merely lay
out how the content should appear on a page.  Most content will
originate from database queries, although some content may derive from
computations performed within the web server or from remote sources.
The templating system does not place any restrictions on the
origin of content, provided it is ultimately presented to the
sytem in one of the standard data structured specified in the 
<a href="spec">dynamic template specification</a>. </p>

<li><p><b>Documentation.</b> Template writers need a dictionary for
each specification file that provides the name and description of
all the dynamic variables they can insert into a template.  This
documentation is included in the specification by the programmer, and
accessible from a browser by referencing the URL of a <tt>spec</tt>
file from a browser.</p>

</ul>

<h3>Page Processing</h3>

<p>The templating system works by defining a <em>filter</em> on
all URLs that end with the <tt>adp</tt> extension.  When a user
requests an <tt>adp</tt>page from the server, the filter procedure
intercepts the request and performs the following steps:</p>

<ol>

<li><p>The procedure substitutes the <tt>data</tt> extension for
<tt>adp</tt> in the URL and looks for a template specification file at that
location.  If no specification file is found at that location, than the
filter terminates and processing of the <tt>adp</tt> page is handed
back to the web server.</p>

<li><p>If the procedure finds a specification file, it parses the
specification into a special data structure for processing.  This
data structure is cached, so parsing only occurs the first time
the file is requested or when the file changes.  The latter 
behavior may be disabled for better performance when a site is
not under active development.</p>

<li><p>A list of data sources is obtained from the template
specification.  The content from each of these data sources is
obtained, either by performing a database query or by evaluating a Tcl
expression.  Each content value is stored in a special variable that
the template can then reference to insert dynamic content into a
page.</p>

<li><p>Once the content is defined, the procedure checks the template
specification for directions on template selection.  The first step in
this process is to determine the <b>master template</b> for a page.
Typically the master template specifies a skeletal layout and include
page components found on all pages of a site, such as a standard
header, navigation bar, footer, and a content area.  The specification
can indicate a non-default master template to use, or that no master
template should be used at all.</p>

<p>The master template may need to be chosen dynamically depending on
a user's preferences and browser configuration.  A default master
template is specified as a configuration parameter.</p>

<li><p>The second step in template selection is to determine the
proper <b>content template</b> to use.  The content template usually
specifies the layout only of the content area of a page.  The
rest of the page is specified by a master template as described in
the previous step.</p>

<p>The default behavior is to look for a content template at the
requested URL.  Alternatively, the developer may specify a procedure
to dynamically choose from one of several templates written to present
the same or similar content.  There is no absolute convention for how
alternate templates may be named, but there are at least two
possibilities:</p>

<p>
<ul> 

<li>Multiple templates may be stored in the same directory as the
<tt>data</tt> file, each with a name identifying a particular style.
For example, <tt>home.data</tt> may be accompanied by
<tt>home-plain</tt> and <tt>home-fancy</tt>, all in the page
root of the server.

<li>Separate directory trees may be built to contain the templates for
each available style.  For example, <tt>templates/plain/home.adp</tt>
and <tt>templates/fancy/home.adp</tt> may be two ways to make use of the
specification contained in <tt>home.spec</tt>.

</ul>
</p>

<li><p>Once the dynamic content has been prepared and the templates have
been selected, the final HTML for the page can be generated and returned
to the client.</p>

</ol>

<div align=right>
<a href="spec">Next</a> | 
<a href="index">Top</a> 
</div>

<hr>

<a href="mailto:karlg@arsdigita.com">karlg@arsdigita.com</a>



