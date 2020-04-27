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

my $config_file = $q->param('config_file');
my $server = $q->param('server');
my $action = $q->param('action');

my $search_string = '';
my @ss = split('@', $server);

for( my $w = 0; $w < scalar @ss; $w++ ) {
	my $d = @ss[$w];
	$search_string .= $d;
	if ( scalar @ss - 1 > $w ) {
		$search_string .= ".*,\\s*"
	}
}
# print $search_string;
#################
# Config Values #
#################
my $CONFIG_FILE = "$base_dir/resources/$config_file";

# Load Config Data #######################################	
my $filedata = LoadFile($CONFIG_FILE);

my $header_title = $filedata->{header_title};
my $csv_file     = $filedata->{detail_file};
my $footer_hash  = $filedata->{footer};
my $key_column   = $filedata->{key_column};
my $export_button = $filedata->{detail_export_button};
my $export_file_name = $filedata->{detail_export_file_name};

####Read CSV File and Collect Lines
my $final_data_array = [];
my $csv_lines = [];
my $header_line = '';
my $fh = FileHandle->new;
if ( $fh->open("< $csv_file") ) {
	# $header_line = $fh->getline();
	while (my $line = $fh->getline()) {
		chomp($line);
		push @$csv_lines, $line;
	}
	$fh->close;
  $header_line =~ s/\r|\n//g;
  push @$final_data_array, $header_line;
} 
else {
	die "Cannot open $csv_file"; 
}

##header dynamic
my $header_html_string = '<tr>';
if ( $header_line !~ /^\s*$/ ) {
	my @headers = split(',', $header_line);
	if ( @headers ) {
		foreach ( @headers ) {
			$header_html_string .= '<th>'.$_.'</th>';
		}
	}
}
$header_html_string .= '</tr>';

####Read CSV File and Collect Lines END
my $export_button_html = '';
if ( $export_button =~ /Yes/i ) {
  $export_button_html = "<a href='sysmon_detail.pl?config_file=".$config_file."&server=".$server."&action=export'>Export To CSV File</a><br/><br/>";
}

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

		if ( $line =~ /$search_string/i ) {
			$html_table_string .= '<tr>';
			foreach my $x (@fields) {
				$html_table_string .= '<td>'.$x.'</td>'	;
			}
			$html_table_string .= '</tr>';
      push @$final_data_array, $line;
		}
	}
}

if ( $action =~ /export/ ) {
  print "Content-Type:application/x-download\n";
  print "Content-Disposition:attachment;filename=$export_file_name\n\n";
  for my $line (@$final_data_array) {
    print $line;
    print "\r\n";
  }
  exit;
}
else {
  print $q->header;
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
$export_button_html
<table align="center" id="detail_table">
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
BODY
;

print <<FOOTER;
<footer>
<div style='text-align: center;'>
<p style='margin: 5px 25px 0 25px; color: $footer_hash->{color};font-weight: $footer_hash->{color}; font-size: $footer_hash->{size}'>$footer_hash->{text}</p>
</div>
</footer>

</html>
FOOTER
;


