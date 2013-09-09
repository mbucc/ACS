<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id spec.adp,v 1.1.1.1 2000/08/08 07:24:59 ron Exp
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
Data Specification Files
</h2>

for the <a href="index">Dynamic Publishing System</a> 
by <a href="mailto:karlg@arsdigita.com">Karl Goldstein</a>

<hr>
<div align=right><a href="overview">Previous</a> | 
<a href="tags/index">Next</a>  | 
<a href="index">Top</a></div>

<h3>Introduction</h3>

<p>Data specifications for dynamic templates are stored in plain text
files in the document tree of the web server.  Specifications files
carry the <tt>data</tt> extension.  They are formatted as XML
documents.  An XML element named <tt>template</tt> serves as the root
of each data specification.</p>

<p>The core specification for a dynamic template consists of three tiers of
information:</p>

<ul>

<li><p><b>Global properties.</b> This includes basic information that
applies to the template as a whole.  Each global property is a child
element of the root <tt>template</tt> element.</p>

<li><p><b>Data sources.</b> Each template may have zero or more
sources of dynamic content.  Data sources may obtain data directly
from a database query, or from the results of a Tcl procedure.  The
properties for each data source are contained within a
<tt>datasource</tt> element under the document root.</p>

<li><p><b>Variables.</b>  Each data source makes one or more dynamic
variables available for placing in a template.  Each variable should
be documented for the template writer.  The properties for each
variable are contained within the particular <tt>datasource</tt>
element that determines its value.</p>

</ul>

<p>The overall structure of the basic specification document looks
like this (each property is described in the document below):</p>

<pre>
&lt;template>

  &lt;name><em>template namespace</em>&lt;name>
  &lt;title><em>template title</em>&lt;title>
  &lt;master><em>master template URL</em>&lt;master>
  &lt;comment><em>template description</em>&lt;/comment>

  &lt;process>

  <em>For each data source in the template:</em>

  &lt;datasource>

    &lt;name><em>name</em>&lt;name>
    &lt;type>query, param <em>or</em> eval&lt;/type>
    &lt;structure>onevalue, onerow <em>or</em> multirow&lt;/structure>
    &lt;condition><em>condition</em>&lt;/condition>
    &lt;comment><em>data source description</em>&lt;/comment>

    <em>For each variable in the data source: </em>
    &lt;variable>
      &lt;name><em>variable name</em>&lt;name>
      &lt;comment><em>variable description</em>&lt;/comment>
    &lt;/variable>

  &lt;/datasource>

  &lt;process>

&lt;/template>
</pre>

<p>As is generally true for XML documents, white space is ignored in
parsing the specification.  Longer properties such as comments and queries
can thus be broken into multiple lines to improve the legibility of
the specification.  Comments may NOT contain other markup tags, as this
will invalidate the structure of the specification as an XML document.</p>

<h3>Template properties</h3>

<p>Basic template properties include the following:</p>

<ul>

<li><p>The <tt>name</tt> property should be a short token without
white space, such as <tt>home</tt> or <tt>myworkspace</tt>.  The
template name defines an optional variable namespace for all data
sources in the template.  This is done to avoid collisions between
variable names in subtemplates.  See below for more information on
variable names.</p>

<li><p>The <tt>title</tt> property is optional and may be referenced
as the title of the page.  This property does not apply to subtemplates
that specify page components that would never appear in a page of their
own.</p>

<li><p>The <tt>master</tt> property is optional and specifies the URL
of the master template in which the current template should be embedded
as content.  If no master template is defined, then the default
master template at <tt>/templates/master.adp</tt> is used.</p>

<p>This property only applies when the requested URL matches that of
the specification URL, after substituting <tt>adp</tt> for <tt>data</tt>.
Other referenced templates are assumed to be subtemplates.</p>

<li><p>The <tt>comment</tt> property may be used to provide a general
description of the template for documentation purposes.</p>

</ul>

<h3>Data source properties</h3>

<p>Data source properties include the following:</p>

<ul>

<li><p>The <tt>name</tt> property should be a short token without
white space, such as <tt>userinfo</tt>.  This property is used by the
template writer to refer to variable(s) provided by the data source,
in a manner dependent on the structure of the data (see the next
property).</p>

<li><p>The <tt>structure</tt> property specifies how the content
provided by this data source is structured.  There are three options:</p>

<ol>

<li><p><tt>onevalue</tt> indicates that the data source makes available a
single string.  The template writer refers to this value in one
of two ways:</p>

<pre>&lt;var name="template_namespace.datasource_name">
&lt;var name="datasource_name"></pre>

<li><p><tt>onerow</tt> indicates that the data source makes available a
single set of values, represented internally as a single <tt>ns_set</tt>.  
The template writer refers to each variable in the set like so:</p>

<pre>&lt;var name="template_namespace.datasource_name.variable_name">
&lt;var name="datasource_name.variable_name"></pre>

<li><p><tt>multirow</tt> indicates that the data source makes
available a <em>list</em> of sets of values, represented internally as
a list of <tt>ns_sets</tt>. The template writer refers to variables
from a multirow data source within the context of a <tt>multiple</tt>
tag:</p>

<pre>&lt;var name="template_namespace.datasource_name.variable_name">
&lt;var name="datasource_name.variable_name"></pre>

</ol>

<li><p>The <tt>type</tt> property specifies the general origin of the
data, and informs the template processor how to use the
<tt>condition</tt> property.  Options include:</p>

<ol>

<li><p><tt>eval</tt>, in which case the value of the
<tt>condition</tt> property is evaluated as a Tcl procedure with a
return value matching the specified data structure for this data
source.</p>

<li><p><tt>param</tt>, in which case the value of the
<tt>condition</tt> property is the name of a CGI query parameter.</p>

<li><p><tt>query</tt>, in which case the value of the
<tt>condition</tt> property is a database query that returns an
appropriately structured result.</p>

</ol>

<li><p>The <tt>comment</tt> property may be used to provide a general
description of the data source for documentation purposes.</p>

</ul>

<h3>Variable properties</h3>

<p>There are two key variable properties:</p>

<ul>

<li><p>The <tt>name</tt> property refers to the naming of the variable
by the data source.  For <tt>onerow</tt> and <tt>multirow</tt> data
sources, it corresponds internally to a key in the ns_set(s) that hold
the dynamic content.</p>

<li><p>The <tt>comment</tt> property is critical so that the
template writer knows how to apply the variable.</p>

</ul>

<div align=right><a href="overview">Previous</a> | 
<a href="tags/index">Next</a>  | 
<a href="index">Top</a></div>

<hr>

<a href="mailto:karlg@arsdigita.com">karlg@arsdigita.com</a>




