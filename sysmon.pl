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

#################
# Config Values #
#################
my $CONFIG_FILE = "$base_dir/resources/$config_file";

# Load Config Data #######################################	
my $filedata = LoadFile($CONFIG_FILE);

my $header_title    = $filedata->{header_title};
my $csv_file        = $filedata->{summary_file};
my $footer_hash     = $filedata->{footer};
my $is_anc_tag      = $filedata->{anchor_tag};

####Read CSV File and Collect Lines
my $csv_lines = [];
my $header_line = '';
my $fh = FileHandle->new;
if ( $fh->open("< $csv_file") ) {
	$header_line = $fh->getline();
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
##start read and prepare Graph
my $final_data_array = [];
my $html_table_string = '';
if( scalar @$csv_lines ) {
	foreach my $line ( @$csv_lines ) {
		$line = &trim_space( $line );
		$line =~ s/\r|\n//g;
		next if $line =~ /^\s*$/;

		my @datas = split(',', $line);

		my $server = $datas[0];
		my $status = $datas[1];

		my $is_green = 1;
		my $color = '#33cc33';
		if ( $status =~ /Red/i ) {
			$is_green = 0;
			$color = '#ff3300';
		}

		if ( $is_anc_tag =~ /Yes/i ) {
			if ( @datas ) {
				$html_table_string .= '<tr>';
				foreach my $x (@datas) {
					if ( $x =~ /RED|GREEN/i ) {
						$html_table_string .= '<td style="background-color:'.$color.'"><a href="sysmon_detail.pl?config_file='.$config_file.'&server='.$server.'" target="_blank">'.$x.'</a></td>';
					}
					else {
						$html_table_string .= '<td><a href="sysmon_detail.pl?config_file='.$config_file.'&server='.$server.'" target="_blank">'.$x.'</a></td>';
					}
				}
				$html_table_string .= '</tr>';
			}
		}
		else {
			if ( @datas ) {
				$html_table_string .= '<tr>';
				foreach my $x (@datas) {
					if ( $x =~ /RED|GREEN/i ) {
						$html_table_string .= '<td style="background-color:'.$color.'">'.$x.'</td>';
					}
					else {
						$html_table_string .= '<td>'.$x.'</td>';
					}
				}
				$html_table_string .= '</tr>';
			}
			# $html_table_string .= '<tr><td>'.$server.'</td><td style="background-color:'.$color.'">'.$status.'</a></td></tr>';	
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
  width: 60%;
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
  $header_html_string
  $html_table_string
</table>
</body>
BODY

print <<FOOTER;
<footer>
<div style='text-align: center;'>
<p style='margin: 5px 25px 0 25px; color: $footer_hash->{color};font-weight: $footer_hash->{color}; font-size: $footer_hash->{size}'>$footer_hash->{text}</p>
</div>
</footer>
</html>
FOOTER