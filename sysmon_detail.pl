#!/usr/bin/perl -w
use strict;

# Dependencies ###################################
use FileHandle qw();
use File::Basename qw();
use Cwd qw();
my $base_dir;
my $relative_path;

BEGIN {
   $relative_path = './';
   $base_dir = Cwd::realpath(File::Basename::dirname(__FILE__) . '/' . $relative_path);
}
# Dependencies ####################################

use lib "$base_dir/lib64/perl5";

use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser) ;
use YAML::XS qw(LoadFile Load);
use Template qw(process);;
use JSON;
use Data::Dumper;
##################################################

# Version Info ###################################
my $VERSION = "1.0.0";
##################################################

my $q = new CGI;

print $q->header;

my $config_file = $q->param('config_file');
my $server = $q->param('server');

#################
# Config Values #
#################
my $CONFIG_FILE = "$base_dir/resources/$config_file";

# Load Config Data #######################################	
my $filedata = LoadFile($CONFIG_FILE);

my $header_title = $filedata->{header_title};
my $csv_file     = $filedata->{detail_file};
my $footer_hash  = $filedata->{footer};

####Read CSV File and Collect Lines
my $csv_lines = [];
my $fh = FileHandle->new;
if ( $fh->open("< $csv_file") ) {
	while (my $line = $fh->getline()) {
		chomp($line);
		push @$csv_lines, $line;
	}
	$fh->close;
} 
else {
	print "Cannot open $csv_file"; 
	die;
}

####Read CSV File and Collect Lines END

my $header_fields = $filedata->{'detail_fields'};

##start read and prepare Graph
my $final_data_array = [];
my $html_table_string = '';
if( scalar @$csv_lines ) {
	foreach my $line ( @$csv_lines ) {
		$line = &trim_space( $line );
		$line =~ s/\r|\n//g;
		next if $line =~ /^\s*$/;

		my @fields = split(',', $line);

		if ( $fields[0] =~ /$server/i ) {
			$html_table_string .= '<tr>';
			foreach my $x (@fields) {
				$html_table_string .= '<td>'.$x.'</td>'	;
			}
			$html_table_string .= '</tr>';
		}
	}
}

##trim
sub trim_space {
	my $line = shift;

	$line =~ s/^\s+//g;
	$line =~ s/\s+$//g;

	return $line;
}

print <<HEADER;
<!DOCTYPE HTML>
<html>
<head>
<style>
table {
  font-family: arial, sans-serif;
  border-collapse: collapse;
  width: 100%;
  align: center;
}

td, th {
  border: 1px solid #dddddd;
  text-align: left;
  padding: 8px;
}

tr:nth-child(even) {
  background-color: #dddddd;
}
</style>
</head>
HEADER

print <<BODY;
<body>
<div style='text-align: center;'>
<p style='margin: 5px 25px 0 25px; color: $footer_hash->{color};font-weight: $footer_hash->{color}; font-size: $footer_hash->{size}'>$header_title</p>
</div>
<table align="center">
  <tr>
    <th>$header_fields->{'field1'}</th>
    <th>$header_fields->{'field2'}</th>
    <th>$header_fields->{'field3'}</th>
    <th>$header_fields->{'field4'}</th>
    <th>$header_fields->{'field5'}</th>
    <th>$header_fields->{'field6'}</th>
  </tr>
  $html_table_string
</table>
</body>
<footer>
<div style='text-align: center;'>
<p style='margin: 5px 25px 0 25px; color: $footer_hash->{color};font-weight: $footer_hash->{color}; font-size: $footer_hash->{size}'>$footer_hash->{text}</p>
</div>
</footer>
</html>
BODY
;