#!/usr/bin/perl -w
#
#login.pl
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
my $dbuser="djl605";
my $dbpasswd="rufi43TJ";

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

my $cookiename="PortSession";


#
# Get the session input and debug cookies, if any
#
my $inputcookiecontent = cookie($cookiename);

#
# Will be filled in as we process the cookies and paramters
#
my $outputcookiecontent = undef;
my $deletecookie=0;
my $user = undef;
my $password = undef;
my $logincomplain=0;

my $run;
if (defined($inputcookiecontent)) { 
  # Has cookie, let's decode it
  ($user,$password) = split(/\//,$inputcookiecontent);
  $outputcookiecontent = $inputcookiecontent;
} else {
  # No cookie, treat as anonymous user
  ($user,$password) = ("anon","anonanon");
}

if (defined(param("run"))) { 
    $run = param("run") == 1;
 } 
 else {
    $run = 0;
 }

if ($run) { 
    #
    # Login attempt
    #
    # Ignore any input cookie.  Just validate user and
    # generate the right output cookie, if any.
    #
    ($user,$password) = (param('user'),param('password'));
    if (ValidUser($user,$password)) { 

      # if the user's info is OK, then give him a cookie
      # that contains his username and password 
      # the cookie will expire in one hour, forcing him to log in again
      # after one hour of inactivity.
      # Also, land him in the base query screen
      $outputcookiecontent=join("/",$user,$password);
      $run = 0;
    } else {
      # uh oh.  Bogus login attempt.  Make him try again.
      # don't give him a cookie
      $logincomplain=1;  
      $run = 0;
    }
}
if (defined($outputcookiecontent)) { 
  ($user,$password) = split(/\//,$outputcookiecontent);
}

if (defined(param("logout"))){
  $deletecookie=1;
}

my @outputcookies;

#
# OK, so now we have user/password
# and we *may* have an output cookie.   If we have a cookie, we'll send it right 
# back to the user.
#
# We force the expiration date on the generated page to be immediate so
# that the browsers won't cache it.
#
if (defined($outputcookiecontent)) { 
  my $cookie=cookie(-name=>$cookiename,
		    -value=>$outputcookiecontent,
		    -expires=>($deletecookie ? '-1h' : '+1h'));
  push @outputcookies, $cookie;

} 

 
# Headers and cookies sent back to client
#
# The page immediately expires so that it will be refetched if the
# client ever needs to update it
#
if (ValidUser($user, $password)){
	print redirect(-uri=>'portfolios.pl', -cookie=>\@outputcookies);
}else{
print header(-expires=>'now', -cookie=>\@outputcookies);


print "<html>";
print "<head>";
print "<title>Portfolio Login</title>";
print "</head>";

print "<body style=\"height:auto;margin:0\">";

print "<style type=\"text/css\">\n\@import \"port.css\";\n</style>\n";
print "<div class=\"container\" style=\"background-color:#eeeee0; 
	margin:100px auto; width:300px; padding-left:10px;\">";


if ($logincomplain){
	print "<h5 style=\"color:red\">Login Failed. Try Again.<p><h5>", hr;
}
print start_form(-name=>"Login"),
    h3('Login to Your Portfolio'),
	"Username: ",textfield(-name=>'user'),	p,
	"Password: ",password_field(-name=>'password'),p,
	hidden(-name=>'run',default=>['1']),
	"<center>", submit(-class=>'btn', -name=>'Login'),p,p,
	"<a href=\"register.pl\">
	<strong>Register Account</strong> </a>",
	"</center>",
	end_form;
print "</div>";


print "<footer style=\"position:fixed;bottom:0;
	width:100\%; height:100px; background-color:#000000;\">", "<center>",
	"<a href=\"handins.pl?view=sbfc\"><strong>View Storyboard/FlowChart</strong> </a>",
	p,"<a href=\"handins.pl?view=er\"><strong>View E/R Diagram</strong> </a>",
	"<br/>","<a href=\"handins.pl?view=relational\"><strong>View Relational Design</strong> </a>",
	"<br/>","<a href=\"handins.pl?view=sqlddl\"><strong>View SQL DDL Code</strong> </a>",
	"<br/>","<a href=\"handins.pl?view=sqldmldql\"><strong>View SQL DML/DQL Code</strong> </a>",
	"</center>", "</footer>";

print end_html;
}


sub ValidUser{
	my ($name, $pass)= @_;
  my @col;
	eval {@col=ExecStockSQL("COL", "select count(*) from users where userid=? and password=?", $name, $password)};
	if ($@){	
    return 0;
	}
  else{
    return $col[0]>0;
  }
}
