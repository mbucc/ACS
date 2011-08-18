// BlobDataSource.java
// part of the webmail ACS module
// written by Jin Choi <jsc@arsdigita.com>
// 2000-03-01

// This class provides a wrapper for BLOBs so that we can
// stuff them into Messages.

package com.arsdigita.mail;

import javax.activation.*;
import oracle.sql.*;
import java.sql.*;

import java.io.*;

public class BlobDataSource implements DataSource {
    protected BLOB blob;
    protected String contentType;
    protected String name;

    public BlobDataSource(BLOB blob, String contentType, String name) {
	this.blob = blob;
	this.contentType = contentType;
	this.name = name;
    }

    public InputStream getInputStream()
	throws IOException {
	try {
	    return blob.getBinaryStream();
	} catch (SQLException e) {
	    throw new IOException("SQL Exception caught: " + e.getMessage());
	}
    }

    public OutputStream getOutputStream()
	throws IOException {
	try {
	    return blob.getBinaryOutputStream();
	} catch (SQLException e) {
	    throw new IOException("SQL Exception caught: " + e.getMessage());
	}
    }
    
    public String getContentType() {
	return contentType;
    }

    public String getName() {
	return name;
    }
};
