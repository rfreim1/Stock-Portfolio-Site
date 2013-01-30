#!/usr/bin/perl -w
#
#register.pl
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

#
# You need to override these for access to your database
#


BEGIN {
  $ENV{PORTF_DBMS}="oracle";
  $ENV{PORTF_DB}="cs339";
  $ENV{PORTF_DBUSER}="djl605";
  $ENV{PORTF_DBPASS}="rufi43TJ";

  unless ($ENV{BEGIN_BLOCK}) {
    use Cwd;
    $ENV{ORACLE_BASE}="/raid/oracle11g/app/oracle/product/11.2.0.1.0";
    $ENV{ORACLE_HOME}=$ENV{ORACLE_BASE}."/db_1";
    $ENV{ORACLE_SID}="CS339";
    $ENV{LD_LIBRARY_PATH}=$ENV{ORACLE_HOME}."/lib";
    $ENV{BEGIN_BLOCK} = 1;
    exec 'env',cwd().'/'.$0,@ARGV;
  }
};

use stock_data_access;


my $run;

if (defined(param("run"))) { 
    $run = param("run") == 1;
 } 
 else {
    $run = 0;
 }

#
# Headers and cookies sent back to client
#
# The page immediately expires so that it will be refetched if the
# client ever needs to update it
#
print header();

print "<html>";
print "<head>";
#print "<META HTTP-EQUIV=Refresh CONTENT=\"5; URL=portfolios.pl\">";
print "<title>Portfolio Registration</title>";
print "</head>";

print "<body style=\"height:auto;margin:0\">";

print "<style type=\"text/css\">\n\@import \"port.css\";\n</style>\n";

print "<div class=\"container\" style=\"background-color:#eeeee0; 
	margin:100px auto; width:300px; padding-left:10px;\">";
if(!$run){
	print start_form(-name=>'Register'),
	    h3('Register Account'),
	    "Username: ", textfield(-name=>'name'),p,
	    "Password: ", password_field(-name=>'password'),"<br/>", 
	    hidden(-name=>'run',-default=>['1']), "<center>",
	    submit(-class=>'btn', -name=>'Register'), "</center>",
	    end_form;
	 
	}
else{
	my $name = param("name");
	my $password = param("password");
	my $error = register($name, $password);
	if ($error){
		print $error;
	}
	else{
		print "Registration sucessful!<br />";
	}
}
print "</div>";

print "<footer style=\"position:fixed;bottom:0;
	width:100\%; height:30px; background-color:#000000;\">",
	"<a href=\"login.pl\"><strong>Return to Login</strong> </a>",
	"</footer>";


print end_html;

sub register{
	eval{ExecStockSQL(undef, "insert into users values(?,?,\'freedom\')", @_)};
	return $@;
}

