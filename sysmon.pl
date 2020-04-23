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

my $header_title  = $filedata->{header_title};
my $csv_file      = $filedata->{summary_file};
my $footer_hash   = $filedata->{footer};
my $is_anc_tag    = $filedata->{anchor_tag};
my $color_column  = $filedata->{color_column};
my $color_code    = $filedata->{color_code};
my $color_string = $filedata->{color_string};
my $color_string_code   = $filedata->{color_string_code};
my $key_column    = $filedata->{key_column};
my $export_button = $filedata->{summary_export_button};
my $export_file_name = $filedata->{summary_export_file_name};

###split column and color
my @ccol = split(',', $color_column);
my @ccod = split(',', $color_code);

my $color_code_hash = {};
if ( scalar @ccol ) {
	for( my $i = 0; $i < scalar @ccol; $i++ ) {
		my $val = &trim_space($ccod[$i]);
		$color_code_hash->{$ccol[$i]-1} = $val;
	}
}

my @cstr = split(',', $color_string);
my @cstrcod = split(',', $color_string_code);

my $color_string_code_hash = {};
if ( scalar @cstr ) {
	for( my $i = 0; $i < scalar @cstr; $i++ ) {
		my $key = &trim_space($cstr[$i]);
		my $val = &trim_space($cstrcod[$i]);
		$color_string_code_hash->{$key} = $val;
	}
}


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

my $export_button_html = '';
if ( $export_button =~ /Yes/i ) {
	$export_button_html = "<button onclick=exportTableToCSV(\'$export_file_name\')>Export To CSV File</button><br/><br/>";
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

		if ( $is_anc_tag =~ /Yes/i ) {
			if ( @datas ) {
				$html_table_string .= '<tr>';

				my $server = '';
				my @key_cols = split(',', $key_column);

				foreach my $k ( @key_cols ) {
					$server .= &trim_space($datas[$k-1]);
					$server .= '@';
				}
				$server =~ s/\@$//g;
				
				for (my $i = 0; $i < scalar @datas; $i++) {
					my $x = &trim_space($datas[$i]);

					if ( exists $color_code_hash->{$i} ) {
						my $color = '';
						if ( exists $color_string_code_hash->{$x} ) {
							$color = $color_string_code_hash->{$x};
						}
						else {
							$color = $color_code_hash->{$i};	
						}

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
				my $server = '';
				my @key_cols = split(',', $key_column);
				foreach my $k ( @key_cols ) {
					$server .= &trim_space($datas[$k-1]);
					$server .= '@';
				}
				$server =~ s/\@$//g;

				for (my $i = 0; $i < scalar @datas; $i++) {
					my $x = &trim_space($datas[$i]);

					if ( exists $color_code_hash->{$i} ) {
						my $color = '';
						if ( exists $color_string_code_hash->{$x} ) {
							$color = $color_string_code_hash->{$x};
						}
						else {
							$color = $color_code_hash->{$i};	
						}
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
$export_button_html
<table align="center" id="detail_table">
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


<script>
function exportTableToCSV(filename) {
    var csv = [];
    var rows = document.querySelectorAll("table tr");
    
    for (var i = 0; i < rows.length; i++) {
        var row = [], cols = rows[i].querySelectorAll("td, th");
        
        for (var j = 0; j < cols.length; j++) 
            row.push(cols[j].innerText);
        
        csv.push(row.join(","));        
    }

    // Download CSV file
    downloadCSV(csv.join("\\n"), filename);
}
function downloadCSV(csv, filename) {
    var csvFile;
    var downloadLink;

    // CSV file
    csvFile = new Blob([csv], {type: "text/csv"});

    // Download link
    downloadLink = document.createElement("a");

    // File name
    downloadLink.download = filename;

    // Create a link to the file
    downloadLink.href = window.URL.createObjectURL(csvFile);

    // Hide download link
    downloadLink.style.display = "none";

    // Add the link to DOM
    document.body.appendChild(downloadLink);

    // Click download link
    downloadLink.click();
}
</script>

</footer>
</html>
FOOTER
;