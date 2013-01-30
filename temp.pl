#!/usr/bin/perl -w
use Data::Dumper;
use Finance::Quote;
##
##port.pl
##
##
## The combination of -w and use strict enforces various 
## rules that make the script more resilient and easier to run
## as a CGI script.
##
use strict;
#
## The CGI web generation stuff
## This helps make it easy to generate active HTML content
## from Perl
##
## We'll use the "standard" procedural interface to CGI
## instead of the OO default interface
use CGI qw(:standard);
## The interface to the database.  The interface is essentially
## the same no matter what the backend database is.  
##
## DBI is the standard database interface for Perl. Other
## examples of such programatic interfaces are ODBC (C/C++) and JDBC (Java).
##
##
## This will also load DBD::Oracle which is the driver for
## Oracle.
use DBI;

use stock_data_access;

  my ($symbol) = "AAPL";
  my @info=("date","time","high","low","close","open","volume");
  my @values = ($symbol);
  my $con=Finance::Quote->new();
  $con->timeout(60);
  my %quotes = $con->fetch("usa",$symbol); 
  if (!defined($quotes{$symbol,"success"})) { 
        print "No Data\n";
   } else {
  
     foreach my $key (@info) {
        if (defined($quotes{$symbol,$key})) {
                my $temp = $quotes{$symbol,$key};
                #push(@values, $temp);
		push(@values, '1');
         }else{
                push(@values, '0');
         }   
     }   
   }   

   for my $index (0 .. $#values){
        print "$index: ";
        print "$values[$index]\n";
   }   
   my @testArray = ("AAPL", "7", "7", "7", "7", "7", "0");
   my $sql = "insert into stocksdailyaddon values(?,?,?,?,?,?,?)";
   #eval{ExecStockSQL(undef, $sql, @testArray)};
   print "@testArray\n";
   print "@values\n";
   eval{ExecStockSQL(undef, $sql, @values)};
   #   return $@; 

my @ans = GetHoldings("Fire");
    foreach my $p(@ans){
	print "$p\n";
    }

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
