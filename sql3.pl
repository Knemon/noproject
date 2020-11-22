use strict;
use warnings;

use DBI;
use Data::Dumper;
use Data::Printer;
use POSIX qw(strftime);

my $datestring = strftime '%d-%m-%Y', gmtime();

my %months = (
	5 	=> [1..31],
	6	=> [1..30],
	7	=> [1..30],
	8  	=> [1..31],
	9	=> [1..30],
);

my %names = (
	5 => 'May',
	6 => 'June',
	7 => 'July',
	8 => 'August',
	9 => 'September',
	10=> 'October'
);


for (0..100) {
	open(HTML, ">", "BETA.${datestring}.html") or die $!;
	
	header();
	
	reader(5,\@{$months{5}}) if $months{5};
	reader(6,\@{$months{6}}) if $months{6};
	reader(7,\@{$months{7}}) if $months{7};
	reader(8,\@{$months{8}}) if $months{8};
	reader(9,\@{$months{9}}) if $months{9};
	
	footer();
	
	close HTML;
	
	print "break :: $_ \n";
	
	sleep 4;
}

sub reader {
	
	    my $monat = shift;
		my @days = shift->@*;

		my $db = connect_db();
        my $sth = $db->prepare('select MAX(scan) from HOTEL;') or die $db->errstr;
        $sth->execute() or die $sth->errstr;
		my $date = $sth->fetchall_arrayref->[0][0];

		$sth = $db->prepare("select * from HOTEL WHERE scan=$date and month=$monat and persons > 1;") or die $db->errstr;
        $sth->execute() or die $sth->errstr;
		my %data = $sth->fetchall_hashref(1)->%*;

		my %hotel;
		
		foreach my $key ( keys %data) {
			
			my %ref = $data{$key}->%*;
			$hotel{$ref{product}}{name} = $ref{product};
			
			push $hotel{$ref{product}}{persons}->@*, $ref{persons} if !grep {/$ref{persons}/} $hotel{$ref{product}}{persons}->@*;
			push $hotel{$ref{product}}{policy}->@*,  $ref{policy}  if !grep {/$ref{policy}/}  $hotel{$ref{product}}{policy}->@*;
			
			$hotel{ $ref{product} }{ $ref{policy} }{ $ref{day} } = $ref{price};

		}


		print HTML " <div style=\"overflow-x:auto;\">  <table>   <tr>\n";	
		print HTML sprintf("      <th>%40s</th>\n",$names{$monat});
						
						
			print HTML "      <th> </th>\n";
			print HTML "      <th> </th>\n";
			print HTML "      <th> </th>\n";

		foreach my $day (@{$months{$monat}}) {
			print HTML "      <th>$day</th>\n";
		}
		
		print HTML "    </tr>\n";
		
		
		foreach my $key (sort keys %hotel) {
			my $name = $hotel{$key}{name};
			my @policy = $hotel{$key}{policy}->@*;
			my @persons = $hotel{$key}{persons}->@*;
			
			foreach my $p (sort @policy) {

				foreach my $max (@persons) {

					print HTML "    <tr>\n";	
					print HTML "      <th>$name $p $max</th>\n";
					print HTML "<th>$p</th>\n";
					print HTML "<th>$max</th>\n";
					print HTML "      <th> </th>\n";



						foreach my $dd (@days) {
							
							
							my $setprice = $hotel{$key}{$p}{$dd};
							if (!$setprice) {
								$setprice = ' '
							}
							print HTML "<th>$setprice</th>\n";

				
						}


				}	
			}
		}
		print HTML "</tr>\n";

	
	print HTML "</table></div>\n";
	print HTML "<br><br><br>\n";
	
	print "Finished $monat\n";
	sleep 1;	
	
}


sub connect_db {
	my $dbh = DBI->connect("dbi:SQLite:dbname=TESTDB.db") or die $DBI::errstr;
	return $dbh
}


sub header {
	print HTML<<FOO;
	<!DOCTYPE html>
	<HTML>
	<head>
	<style>
	table {
	  border-collapse: collapse;
	  width: 100%;
	}
	
	th, td {
	  text-align: left;
	  padding: 8px;
	}
	
	tr:nth-child(even) {background-color: #f2f2f2;}
	</style>
	</head>
	<body>
	<center><h1>BETA Analysis</h1></center><br>
	
FOO
}

sub footer {
	print HTML "<br><br><br>Generated $datestring\n</body>";
}
