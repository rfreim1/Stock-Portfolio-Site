#!/usr/bin/perl -w
use Data::Dumper;
use Finance::Quote;
use Date::Manip;
#
#port.pl
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

my $curStock;
if (defined(param("stock"))){
  $curStock=param("stock");
} else{
  $curStock=undef;
}
my $cookiename="PortSession";
my $portName = param("name");

$portName = "Fire";

#
# Get the session input and debug cookies, if any
#
my $inputcookiecontent = cookie($cookiename);

print header();

print "<html>";
print "<head>";
print "<title>MyPortfolios</title>";
print "</head>";

print "<body style=\"height:auto;margin:0\">";
print "<style type=\"text/css\">\n\@import \"port.css\";\n</style>\n";

print "<div class=\"container\" style=\"background-color:#eeeee0; 
        margin:100px auto; width:500px; padding:10px;\">";
print "<div style= \"border-bottom:2px ridge black\">" ,
  h3($portName." Portfolio"),
  "</div>";

print "<table class=\"table\"> <tbody>";
my @holdings = GetHoldings($portName);
my $i;

foreach my $stock(@holdings){
  $i++;
  if ($i % 2){
    print "<tr>";
  }
  else{
    print "<tr class=\"info\">";
  }
  print  "<td><a href=\"stock.pl?name=$stock\"> $stock </a> </td>";
}

print "</tbody> </table>";

print "</div>";

print end_html;



sub GetHoldings{
  my ($pname) = @_;
  my $id;
  my @col;
   eval {($id) = ExecStockSQL("COL", "select id from  portfolios 
	where portfolios.name=?", $pname)}; 
   eval {@col = ExecStockSQL("COL", "select symbol from holdings
		where holdings.portfolioid=?",$id)};
  if ($@) { 
    return undef;
  } else {
    return @col;
  }
}



