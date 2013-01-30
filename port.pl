#!/usr/bin/perl -w
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
# You need to override these for access to your database
#
my $dbuser="djl605";
my $dbpasswd="rufi43TJ";

my $cookiename="PortSession";

my $withdraw;
my $deposit;
my $amount;
my $depaccount;

if (defined(param("withdraw"))) { 
    $withdraw = param("withdraw") == 1;
    $deposit = 0;
    $amount = param("amount1");
} 
else {
    $withdraw = 0;
}
if (defined(param("deposit"))) { 
      $amount = param("amount2"); 
      $deposit = param("deposit") == 1;
} 
else {
      $deposit = 0;
}

if (defined(param("account"))){
  $depaccount = param("account");
}
else{
  $depaccount = 0;
}


my $port = param("name");

#
# Get the session input and debug cookies, if any
#
my $inputcookiecontent = cookie($cookiename);
my $user;
my $password;

($user,$password) = split(/\//,$inputcookiecontent);

my $error;
my @portID = getPortID($user, $port);
my $id= $portID[0];
my @money= getCash($id);

if($withdraw){
  my $cash1 = $money[0];
  if ($cash1 > $amount){
    withdrawCash($id, $amount);
  }
  else{
    $error = "Cannot withdraw more money than in cash account";
  }
}
elsif($deposit){
  if ($depaccount){
    my @accID = getPortID($user, $depaccount);
    my $accid= $accID[0];
    my @accmoney= getCash($accid);
    my $cash2 = $accmoney[0];
    if ($cash2 > $amount){
      my $error1 =withdrawCash($accid, $amount);
      if($error1){
        $error = $error1;
      }
      else{
         depositCash($id, $amount);
      }
    }
    else{
      $error = "Cannot withdraw more money than in cash account";
    }
  }
  else{
    depositCash($id, $amount);
  }
}
my $symbol;
my $shares;
my $invalidNumber = 0;
my $invalidSymbol = 0;
my $insufFunds = 0;
my $notOwned = 0;

if (defined(param("symbol")) and defined(param("shares"))){
        $symbol = uc (param("symbol"));
	$shares = param("shares");
	if(!($shares =~ /^\s*[0-9]+/)) {
	  $invalidNumber = 1;
	}
	else {
	  my @findSymbol = ExecStockSQL("ROW", "select count(symbol) from stockssymbols where symbol=rpad(?,16)", $symbol);
	  if(!$findSymbol[0]) {
	    $invalidSymbol = 1;
	  }
          else {


	    my @stockinfo = eval {ExecStockSQL("ROW", "select symbol, close, timestamp from stocksdaily where timestamp=(select MAX(last) from stockssymbols where symbol=rpad(?, 16)) and symbol=rpad(?, 16)",$symbol, $symbol);
	    };

	    my $price = $stockinfo[1];
	    if($price * $shares <= $money[0]) {
	      withdrawCash($id, $price * $shares);


	      @stockinfo = ExecStockSQL("ROW", "select count from holdings where symbol=rpad(?,16) and portfolioid=?", $symbol, $id);


	      if(not (@stockinfo)) {

		ExecStockSQL(undef, "insert into holdings values(?, ?, ?)", $symbol, $id, $shares);
	      }
	      else {
		ExecStockSQL(undef, "update holdings set count=? where symbol=rpad(?,16) and portfolioid=?", $stockinfo[0] + $shares, $symbol, $id);
	      }
	    }
	    else {
	      $insufFunds = 1;
	    }
	  }
	}
}


if (defined(param("sellsymbol")) and defined(param("shares"))){
  $symbol = uc(param("sellsymbol"));
  $shares = param("shares");

  if(!($shares =~ /^\s*[0-9]+/)) {
    $invalidNumber = 1;
  }
  else {
    my @findSymbol = ExecStockSQL("ROW", "select symbol, count from holdings where symbol=rpad(?,16) and portfolioid=?", $symbol, $id);
    if(!$findSymbol[0] or $findSymbol[1] < $shares) {
      $notOwned = 1;
    }
    elsif($findSymbol[1] == $shares) {
      ExecStockSQL(undef, "delete from holdings where symbol=rpad(?,16) and portfolioid=?", $symbol, $id);
      
      my @stockinfo = eval {ExecStockSQL("ROW", "select symbol, close, timestamp from stocksdaily where timestamp=(select MAX(last) from stockssymbols where symbol=rpad(?, 16)) and symbol=rpad(?, 16)",$symbol, $symbol);
      };
      
      
      my $price = $stockinfo[1];
      depositCash($id, $price * $shares);
    }
    else {
      ExecStockSQL(undef, "update holdings set count=? where symbol=rpad(?,16) and portfolioid=?", $findSymbol[1] - $shares, $symbol, $id);


      my @stockinfo = eval {ExecStockSQL("ROW", "select symbol, close, timestamp from stocksdaily where timestamp=(select MAX(last) from stockssymbols where symbol=rpad(?, 16)) and symbol=rpad(?, 16)",$symbol, $symbol);
      };
      
      
      my $price = $stockinfo[1];
      depositCash($id, $price * $shares);

    
    }
  }
}






if (defined($user)){
  if ($deposit or $withdraw or ($symbol and $shares)){
    my $uri = 'port.pl?name='.$port;
    if($invalidNumber) { $uri = $uri . "&invalidNum=" . $invalidNumber; }
    if($invalidSymbol) { $uri = $uri . "&invalidSym=" . $invalidSymbol; }
    if($insufFunds) { $uri = $uri . "&insufFund=" . $insufFunds; }
    if($notOwned) { $uri = $uri . "&notOwned=" . $notOwned; }
    print redirect(-uri=>$uri);
  }
  print header();
}
else{
  print redirect(-uri=>'login.pl');
}




print "<html>";
print "<head>";
print "<title>$port</title>";
print "</head>";

print "<body style=\"height:auto;margin:0\">";

print "<style type=\"text/css\">\n\@import \"port.css\";\n</style>\n";

print "<div style=\"position:absolute;top:0;
  width:100\%; height:30px; background-color:#eeee00; left:0; z-index:999;\">", 
  "<a href=\"login.pl?logout=1\"><strong>Logout</strong> </a>",
  "</div>";

if(defined(param("invalidNum")) and param("invalidNum") eq "1") {
  print "<script type=\"text/javascript\"> alert('Invalid entry: must be a positive integer');</script>";

}

if(defined(param("invalidSym")) and param("invalidSym") eq "1") {
  print "<script type=\"text/javascript\"> alert('Invalid entry: Stock symbol not found');</script>";

}

if(defined(param("insufFund")) and param("insufFund") eq "1") {
  print "<script type=\"text/javascript\"> alert('Insufficient funds.');</script>";
}

if(defined(param("notOwned")) and param("notOwned") eq "1") {
  print "<script type=\"text/javascript\"> alert('You do not have enough of that stock to sell.');</script>";
}

print "<div class=\"container\" style=\"background-color:#eeeee0; 
	margin:100px auto; width:800px; padding:10px;\">";
print "<div style= \"border-bottom:2px ridge black\">",
  h2($port), 
  "</div>";


print "<strong><u>Cash Account:</u> \$"; 
my @money2= getCash($id);
my $cash = $money2[0];
printf "%20.2f", $cash, "</strong>";


print start_form(-name=>"Withdraw"),"<br />",
	 "&nbsp;&nbsp;",
	hidden(-name=>'withdraw',default=>['1']),
  hidden(-name=>'name',default=>['$port']),
  "\$", textfield(-name=>'amount1'),
  submit(-class=>'btn', -name=>'Withdraw'),
	end_form;

print "<strong>OR </strong>";

print start_form(-name=>"Deposit"), "<br/>",
  "&nbsp;&nbsp;",
	hidden(-name=>'deposit',default=>['1']),
  hidden(-name=>'name',default=>['$port']),
  "\$", textfield(-name=>'amount2'),
  submit(-class=>'btn', -name=>'Deposit'),p,
  " &nbsp;&nbsp; &nbsp;&nbsp;OPTIONAL Account to withdraw from:", textfield(-name=>'account'),
  
	end_form;



#area to place adding stocks functionality
#probably want a form(start_form/end_form/submit btn)
print hr, "<strong><u>Buy Stock:</u></strong>",p,
      start_form, 
      "symbol:", textfield(-name=>'symbol'),p,
      "shares:", textfield(-name=>'shares'),p,
      hidden(-name=>'name',default=>['$port']),
      submit(-class=>'btn', -name=> 'Add Stock'),
      end_form;

print hr, "<strong><u>Sell Stock:</u></strong>",p,
      start_form,
      "symbol:", textfield(-name=>'sellsymbol'),p,
      "shares:", textfield(-name=>'shares'),p,
      hidden(-name=>'name',default=>['$port']),
      submit(-class=>'btn', -name=> 'Sell Stock'),
      end_form;

print hr, "<strong><u>Stocks:</u></strong>", p;

print "<table class=\"table\" style=\"background-color:white\"> <tbody>";
#can changed layout of table as you wish also porbably want to print in each stock page as well
print "<th>sym</th><th>market value</th><th># of shares</th><th>cov</th><th>Beta</th>";
my @ndaqInfo = `./get_info.pl NDAQ`;
my $marketVar = (split(/\s+/, $ndaqInfo[1]))[4];
my @stocks = ExecStockSQL("2D", "select symbol, count from holdings where portfolioid=?", $id);

my $portValue = 0;
my @stocksymbols = ();
for (my $i = 0; $i < @stocks; $i++) {
  foreach my $stock ($stocks[$i]) {
    my $s = @{$stock}[0];
    push(@stocksymbols, $s);
    my $s2 = @{$stock}[1];
    my @stockInfo = ExecStockSQL("ROW", "select symbol, close, timestamp from stocksdaily where timestamp=(select MAX(last) from stockssymbols where symbol=rpad(?, 16)) and symbol=rpad(?, 16)", $s, $s);

    my $value = $stockInfo[1];
    $portValue += $value * $s2;
    print "<tr><td> <a href=\"stock.pl?port=$port&stock=$s\"> $s </a></td>";

	 printf( "<td>\$%20.2f</td>",$value * $s2 );
	 print  "<td> $s2</td>";
         my @cov = `./get_info.pl $s`;
	 my $COV = (split(/\s+/, $cov[1]))[7];
	 print "<td>$COV</td>";
	 my @covarWithMarket = `./get_covar.pl $s NDAQ`;
	 my $beta = (split(/\s+/, $covarWithMarket[5]))[2] / ($marketVar * $marketVar);
	 print "<td>$beta</td>",
	 "</tr>";
  }
}

print "</tbody> </table>";

###prints port market value as a whole
print hr, "<strong><u>Statistics:</u></strong>", p,p,
      "Market Value of Portfolio: ";
printf("\$%20.2f", $portValue + $cash);
print p;


if($#stocksymbols >= 1) {
  my $covarArgs = join(" ", @stocksymbols);


  print "Correlation matrix of stocks: ", p;

  print "<table class=\"table\" style=\"background-color:white\"> <tbody>";


  my @outputRows= `./get_covar.pl --field1=close --field2=close $covarArgs`;

  shift(@outputRows);
  shift(@outputRows);
  shift(@outputRows);
  shift(@outputRows);
  foreach my $outputRow (@outputRows) {
    print "<tr><td>";
    $outputRow =~ s/\s+/<\/td><td>/g;
    print $outputRow, "</td></tr>";
  }

  print "</tbody></table>";
}





print "</div>";

print "<footer style=\"position:fixed;bottom:0;
  width:100\%; height:30px; background-color:#000000;\">",
  "<a href=\"portfolios.pl\"><strong>Return to Portfolio</strong> </a>",
  "</footer>";

print end_html;

sub getPortID{
	my ($user, $port)=@_;
	my @col;
	eval {@col=ExecStockSQL("COL", "select id from portfolios where owner=? and name=?",
	 $user, $port)};
  if ($@) { 
    die "no";
  } else {
    return @col;
  }

}

sub getCash{
	my($id)=@_;
	my @col;
	eval {@col=ExecStockSQL("COL", "select cash from portfolios where id=?",
	 $id)};
  if ($@) { 
    die "no";
  } else {
    return @col;
  }
}

sub depositCash{
  my($id, $amount) = @_;
  eval{
    ExecStockSQL(undef, "update portfolios set cash=cash+? where id=?", $amount,$id)
  };
  return $@;
}

sub withdrawCash{
  my($id, $amount) = @_;
    eval{
      ExecStockSQL(undef, "update portfolios set cash=(cash-?) where id=?", $amount, $id)
    };
    return $@;
  
}
