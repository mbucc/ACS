// ClobDataSource.java
// part of the webmail ACS module
// written by Jin Choi <jsc@arsdigita.com>
// 2000-03-01

// This class provides a wrapper for CLOBs so that we can
// stuff them into Messages.

package com.arsdigita.mail;

import javax.activation.*;
import oracle.sql.*;
import java.sql.*;

import java.io.*;

public class ClobDataSource implements DataSource {
    protected CLOB clob;
    protected String contentType;
    protected String name;

    public ClobDataSource(CLOB clob, String contentType, String name) {
	this.clob = clob;
	this.contentType = contentType;
	this.name = name;
    }

    public InputStream getInputStream()
	throws IOException {
	try {
	    return clob.getAsciiStream();
	} catch (SQLException e) {
	    throw new IOException("SQL Exception caught: " + e.getMessage());
	}
    }

    public OutputStream getOutputStream()
	throws IOException {
	try {
	    return clob.getAsciiOutputStream();
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
