#!/usr/bin/perl -w
#
#portfolios.pl
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

my $cookiename="PortSession";

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
#
# Get the session input and debug cookies, if any
#
my $inputcookiecontent = cookie($cookiename);

my $user = undef;
my $password = undef;
my $delete;


($user,$password) = split(/\//,$inputcookiecontent);

if (defined(param('delete'))){
  $delete = param("delete");
  deletePort($user, $delete);
}
else{
  $delete = undef;
}

#
# Headers and cookies sent back to client
#
# The page immediately expires so that it will be refetched if the
# client ever needs to update it
#
if (defined($user)){
  if (defined($delete)){
    print redirect(-uri=>'portfolios.pl');
  }
  print header();
}
else{
  print redirect(-uri=>'login.pl');
}

print "<html>";
print "<head>";
print "<title>Portfolios</title>";
print "</head>";

print "<body style=\"height:auto;margin:0\">";

print "<style type=\"text/css\">\n\@import \"port.css\";\n</style>\n";

print "<div style=\"position:absolute;top:0;
  width:100\%; height:30px; background-color:#eeee00; left:0; z-index:999;\">", 
  "<a href=\"login.pl?logout=1\"><strong>Logout</strong> </a>",
  "</div>";


print "<div class=\"container\" style=\"background-color:#eeeee0; 
	margin:100px auto; width:400px; padding:10px;\">";
print "<div style= \"border-bottom:2px ridge black\">" ,
  h2($user."\'s portfolios"),
  "</div>";

print "<table class=\"table\" style=\"background-color:white\"> <tbody>";
my @ports = GetPorts($user);
my $i;

foreach my $port(@ports){
  $i++;
  if ($i % 2){
    print "<tr>";
  }
  else{
    print "<tr class=\"info\">";
  }
  print  "<td><a href=\"port.pl?name=$port\"> $port </a> </td> 
    <td><a href=\"portfolios.pl?delete=$port\" class=\"button btn btn-danger\">Delete Portfolio</a> </td></tr>";
}


print "</tbody> </table>";

print "<a href=\"createPort.pl\" class=\"btn btn-primary\">  Create Portfolio</a>";

print "</div>";

print end_html;


sub GetPorts{
	my ($user)=@_;
  my @row;
	eval {@row=ExecStockSQL("COL", "select name from portfolios where owner=?", $user)};
  if ($@) { 
    return undef;
  } else {
    return @row;
  }
}

sub deletePort{
  my ($user, $port)=@_;
  eval {ExecStockSQL(undef, "delete from portfolios where owner=? and name=?", $user, $port)};
  return $@;
}
