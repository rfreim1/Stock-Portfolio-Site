#!/usr/bin/perl -w
#
#handins.pl
#
#
# The combination of -w and use strict enforces various 
# rules that make the script more resilient and easier to run
# as a CGI script.
#
use strict;

# The CGI web generation stuff
# This helps make it easy to generate active HTML content
# from Perl
#
# We'll use the "standard" procedural interface to CGI
# instead of the OO default interface
use CGI qw(:standard);
# The interface to the database.  The interface is essentially
# the same no matter what the backend database is.  
#
# DBI is the standard database interface for Perl. Other
# examples of such programatic interfaces are ODBC (C/C++) and JDBC (Java).
#
#
# This will also load DBD::Oracle which is the driver for
# Oracle.
use DBI;
#
#
# A module that makes it easy to parse relatively freeform
# date strings into the unix epoch time (seconds since 1970)
#
use Time::ParseDate;

my $view;

if (defined(param("view"))) { 
  $view=param("view");
}
else{
	$view = "nada";
}

print header();

print "<html>";
print "<head>";
print "<title>Portfolio Handins</title>";
print "</head>";

print "<body style=\"height:auto;margin:0\">";

print "<style type=\"text/css\">\n\@import \"port.css\";\n</style>\n";

if ($view eq "sbfc"){
	print h3("Storyboard/Flowcharts"),
		img({-src => 'flowchart.jpg',  
   		-alt => 'Cannot find image'});
}
if ($view eq "er"){
	print h3("ER Diagram"),
		img({-src => 'er_diagram.jpg',  
   		-alt => 'Cannot find image'});
}
if ($view eq "relational"){
	print h3("Relational Design"),
		img({-src => 'relations.jpg',  
   			-alt => 'Cannot find image'});
}
if ($view eq "sqlddl"){
	open FILE, "setupdb.sql" or die $!;
	print h3("SQL DDL");
	print "<pre class=\"pre-scrollable\">";
	while (<FILE>) {
		 print $_; 
	}
	print "</pre>";
	close(file);
}
if ($view eq "sqldmldql"){
	open FILE, "dml.sql" or die $!;
	print h3("SQL DML/DQL");
	print "<pre class=\"pre-scrollable\">";
	while (<FILE>) {
		 print $_; 
	}
	print "</pre>";
	close(file);
}
print "<footer style=\"position:fixed;bottom:0;
	width:100\%; height:30px; background-color:#000000;\">",
	"<a href=\"login.pl\"><strong>Return to Login/Portfolio</strong> </a>",
	"</footer>";


print end_html;
