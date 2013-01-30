#!/usr/bin/perl -w

use Data::Dumper;
use Finance::Quote;
use Date::Manip;
use Getopt::Long;
use Time::CTime;
use FileHandle;
use strict;
use CGI qw(:standard);
use DBI;
use Time::ParseDate;

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
my $inputcookiecontent = cookie($cookiename);

my $stockName;
if (defined param("name")){
	$stockName = param("name");
 }
 elsif(defined param("stock")){
	$stockName=param("stock");
 }
my $portName;
if (defined param("port")){
   $portName = param("port");
}
my $action;
my $run;
if (defined(param("act"))) { 
  $action=param("act");
  if (defined(param("run"))) { 
    $run = param("run") == 1;
  } else {
    $run = 0;  
  }
} else {
  $action="base";
  $run = 0;  
}

print header();
print "<html>";
print "<head>";
print "<title>Portfolios</title>";
print "</head>";
print "<body style=\"height:auto;margin:0\">";

print "<style type=\"text/css\">\n\@import \"port.css\";\n</style>\n";
print "<div class=\"container\" style=\"background-color:#eeeee0; 
        margin:100px auto; width:500px; padding:10px;\">";
print "<div style= \"border-bottom:2px ridge black\">" ,
  h3($stockName),
  "</div>";
if (!$run){
  print "<table class=\"table\"> <tbody>";
  print "<tr><td>";
  print start_form,
        submit (-name=>'addDaily', -value=>'Record Daily Info for '.$stockName),"<br/>",
        hidden(-name=>'run',-default=>['1']), 
        hidden(-name=>'act',-default=>['daily']), 
	hidden(-name=>'name',-default=>[$stockName]),
	hidden(-name=>'port',-default=>[$portName]),
        end_form;
  print "</td></tr>";
  print "<tr><td>";
  print start_form(-name=>'Shannon'),
      h3('Shannon Value of ' . $stockName),
         "Initial Cash: ", textfield(-name=>'initialcash'),"<br/>", p,
          "Tradecost: ", textfield(-name=>'tradecost'),"<br/>", 
	    hidden(-name=>'symbol',-default=>[$stockName]),
	    hidden(-name=>'run',-default=>['1']),
	    hidden(-name=>'act',-default=>['shannon']),
      hidden(-name=>'port',-default=>[$portName]),
            submit(-class=>'btn', -name=>'Submit'), "</center>",
      end_form; 
  print "</td></tr>";

  print "<tr><td>";
  print start_form(-name=>'Predictor'),
      h3('Prediction of ' . $stockName),
         "Number of days to predict: ", textfield(-name=>'days'),"<br/>", p,
	    hidden(-name=>'symbol',-default=>[$stockName]),
	    hidden(-name=>'run',-default=>['1']),
	    hidden(-name=>'act',-default=>['predict']),
      hidden(-name=>'port',-default=>[$portName]),
            submit(-class=>'btn', -name=>'Submit'), "</center>",
      end_form; 
  print "</td></tr>";


  print start_form(-name=>'Plot', -action=>'plot_stock_final.pl'),
      h3('Plot History of ' . $stockName),
        "From Date: ", textfield(-name=>'fromTime'),p,
        "To Date: ", textfield(-name=>'toTime'),"<br/>", 
	  hidden(-name=>'symbol',-default=>[$stockName]),
	  hidden(-name=>'type',-default=>['plot']),
    hidden(-name=>'port',-default=>[$portName]),
	  #hidden(-name=>'act',-default=>['plot']),
	  #hidden(-name=>'run',-default=>['1']),
	  #hidden(-name=>'act',-default=>['plot']),
            submit(-class=>'btn', -name=>'Plot'), "</center>",
      end_form; 
  print "</td></tr>";
  print "</tbody></table>";
}else{
  if ($action eq "daily"){
	  $run = 0;
	  $action = base;
	  my $error = UpdateDaily($stockName);
	  if ($error){
	  print $error;
    }else{
	  print h4($stockName . "'s daily information has been updated");
	  print "<table class=\"table\"> <tbody>";
	  print "<tr><td>";
	  print start_form,
		   submit (-name=>'backToPort', -value=>'Back'),"<br/>",
		   hidden(-name=>'stock',-default=>[$stockName]),
       hidden(-name=>'port',-default=>[$portName]),
		  end_form;
	  print "</td></tr>";
	  print "</tbody></table>";
    }
  }
  #if ($action eq "plot"){
#	$run = 0;
#	$action = base;
#	PlotHistory($stockName);
  	#print "<a href=\'plot_stock.pl?symbol=$stockName&type=plot\'>Plot</a>";
	
 # }
 if ($action eq "shannon"){
    my $initial = param("initialcash");
    my $tradecost = param("tradecost"); 
    my $stock = param("symbol");
    print h4($stock . "'s future predictions");
    print "<table class=\"table\"> <tbody>";
    print "<tr><td>";

    my @output = `./shannon_ratchet.pl $stock $initial $tradecost`;
    foreach my $out(@output){
	print $out."</br>";
    }
    print "</td></tr>";
    print "<tr><td>";
    print "<a href=\"stock.pl?port=$portName&stock=$stock\"> Back</a>";
    print "</td></tr>";
    print "</tbody></table>";

 }
 if ($action eq "predict"){
    my $stock = param("symbol");
    my $days = param("days");
    my $stockFile = "$stock$days.png"; 
    my $predictor = `./time_series_symbol_project.pl $stock $days AWAIT 200 AR 16`;

    #print $predictor;
    #die $stockFile;
    print "<b>Future Predictions</b><p><img src =\'$stockFile\'><p>\n";

    print "<a href=\"stock.pl?port=$portName&stock=$stock\"> Back</a>";
  }
}

print "<footer style=\"bottom:0;
        width:30\%; height:30px; background-color:#000000;\">",
        "<a href=\"port.pl?name=$portName\"><strong>Return to Portfolio $portName</strong> </a>",
        "</footer>";
print end_html;

sub UpdateDaily{
  my $symbol;
  if (defined param("name")){
	$symbol = param("name");
  }
  else{
	$symbol=param("stock");
  } 
  my @info=("time", "open", "high", "low", "close","volume");
  my @values = (); 
  my $con=Finance::Quote->new();
  $con->timeout(60);
  my %quotes = $con->fetch("usa",$symbol); 
  my $time;
  if (!defined($quotes{$symbol,"success"})) { 
        print "No Data\n";
   } else {
     foreach my $key (@info) {
        if (defined($quotes{$symbol,$key})) {
                if ($key eq "time"){    
                  my $temptime = $quotes{$symbol, $key};
                  $time = UnixDate($temptime, "%s");
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
        #print "$index: ";
        #print "$values[$index]\n";
   }   
   my $count = ExecStockSQL("TEXT", "select count(symbol) from stockssymbolsaddon where symbol=rpad(?, 16)", $symbol);
   my $sql = "insert into stocksdailyaddon values(\'$symbol\',?,?,?,?,?,?)";
   eval{ExecStockSQL(undef, $sql, @values)};
   if ($@){
	print $@;
   }else{
	if ($count == 0){
	  $count=$count+1;
	  $sql = "insert into stockssymbolsaddon values(\'$symbol\',\'$count\',\'0\',\'$time\')";
	  eval{ExecStockSQL(undef, $sql)};
	}else{
	  $count = $count + 1;
	  $sql = "update stockssymbolsaddon set count=? where symbol=rpad(?, 16)";
	  eval{ExecStockSQL(undef, $sql, $count, $symbol)};
	  $sql = "update stockssymbolsaddon set last=? where symbol=rpad(?, 16)";
	  eval{ExecStockSQL(undef, $sql, $time, $symbol)};
	}
}
   return $@; 
}

#sub PlotHistory{
# my $from = param("fromTime");
# my $to = param("toTime");
# my $stock = param("symbol");
# my @results = `./get_data.pl --from='$from' --to='$to' --close --plot $stock`;
# print @results;
#}

