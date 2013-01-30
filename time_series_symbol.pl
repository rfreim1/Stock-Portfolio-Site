#!/usr/bin/perl -w
BEGIN {
  $ENV{PORTF_DBMS}="oracle";  $ENV{PORTF_DB}="cs339";  $ENV{PORTF_DBUSER}="rhf687";
  $ENV{PORTF_DBPASS}="Yoe53chN";
  $ENV{PATH} = $ENV{PATH} . ":.";
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
use Getopt::Long;

$#ARGV>=2 or die "usage: time_series_symbol.pl symbol steps-ahead model \n";

$symbol=shift;
$steps=shift;
$model=join(" ",@ARGV);

$cmd = "get_data.pl --notime --close $symbol | (time_series_predictor_online $steps $model 2>/dev/null) | time_series_evaluator_online $steps";

system  $cmd;
