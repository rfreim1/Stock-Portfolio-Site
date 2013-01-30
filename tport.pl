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

my $action;
my $run;
my $curStock;
if (defined(param("act"))) { 
  $action=param("act");
  if (defined(param("run"))) { 
    $run = param("run") == 1;
  } else {
    $run = 0; 
  }
} else {
  $action="base";
  $run = 1; 
}
if (defined(param("stock"))){
  $curStock=param("stock");
} else{
  $curStock=undef;
}

my $cookiename="PortSession";
my $portName = param("name");

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
print "<div style= \"border-bottom:2px ridge black\">" ,
        h2($portName),
        "</div>";

$portName = "Fire";
my @holdings = GetHoldings($portName);
foreach my $hold (@holdings){
   print "$hold\n";
}

print "$action\n";
if ($action eq 'daily'){
  if ($run eq '1'){
	my $error = UpdateDaily($curStock);
	print "$curStock is updated\n";
	$run = '0';
 	$action = 'base';
  }else{
 	$action = undef;
	print "else\n";
  }
}

print "<table class=\"table\"> <tbody>";
#foreach my $stock("AAPL", "IDTI"){
foreach my $stock(@holdings){
  print "$stock\n";
  print "<tr><td>";
  print h3($stock);
  print "</td><td>";
  print start_form,
	submit (-name=>'addDaily', -value=>'Record Daily Info'),"<br/>",
	hidden(-name=>'run',-default=>['1']), "<center>",
	hidden(-name=>'act',-default=>['daily']), "<center>",
	hidden(-name=>'stock',-default=>[$stock]), "<center>",
	end_form;
}
print "</td></tr>";
print "</tbody> </table>";

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

sub UpdateDaily{
  my ($symbol) = @_;
 $symbol = "AAPL";
  my @info=("time", "open", "high", "low", "close","volume");
  my @values = ();
  my $con=Finance::Quote->new();
  $con->timeout(60);
  my %quotes = $con->fetch("usa",$symbol); 
  if (!defined($quotes{$symbol,"success"})) { 
        print "No Data\n";
   } else {
     foreach my $key (@info) {
   	if (defined($quotes{$symbol,$key})) {
                if ($key eq "time"){    
                  print "here\n";
                  my $temptime = $quotes{$symbol, $key};
                  my $time = UnixDate($temptime, "%s");
                  push(@values, $time);
                }else{
                my $temp = $quotes{$symbol,$key};
                push(@values, $temp);
		}
         }else{
		push(@values, '1');
         }   
     }   
   }   

   for my $index (0 .. $#values){
        print "$index: ";
        print "$values[$index]\n";
   }
   my $sql = "insert into stocksdailyaddon values(\'$symbol\',?,?,?,?,?,?)";
   eval{ExecStockSQL(undef, $sql, @values)};
   return $@;
}

print "<script type=\"text/javascript\" src=\"port.js\"> </script>";



