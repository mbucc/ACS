<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id collaboration.adp,v 1.1.1.1 2000/08/08 07:24:59 ron Exp
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
Collaboration
</h2>

using the <a href="index">Dynamic Publishing System</a> 
by <a href="mailto:karlg@arsdigita.com">Karl Goldstein</a>

<hr>

<p>One of the goals of the template system is to foster collaboration
among programmers and HTML authors.  Authors need to be able to
add and edit templates to a developing site without having shell
access.  Perhaps the biggest problem with allowing this type of 
access is that it complicates any effort to use version control to
track changes to the site.  The template system includes 
a file upload script that is intended to address this problem.
Template authors upload files by the following mechanism:</p>

<ol>
<li>For existing templates or images, they use FTP to download the
files to their local computer.  Otherwise they start a new file
on their local computer.
<li>When they are ready to upload their changes, they visit
the file upload form in the site admin page at
<tt>https://www.yourdomain.com/admin/template/file-upload.adp</tt>.
The form asks for a local file, a remote URL, and a change
description.
<li>The submission script first checks the file type.  If it is
a text file, it strips carriage returns and writes the file
to the submitted URL.  If it is an image, it just copies the file
to the submitted URL.
<li>Once the file is in place, the script exec's <tt>cvs add</tt>
on the file.  If the file is already in the repository, this
will do nothing.
<li>Then the script exec's <tt>cvs commit</tt> on the file.
This will commit the uploaded changes and rev the file.
</ol>

<hr>

<a href="mailto:karlg@arsdigita.com">karlg@arsdigita.com</a>
