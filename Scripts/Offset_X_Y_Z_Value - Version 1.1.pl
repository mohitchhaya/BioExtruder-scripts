#!/usr/bin/perl 

use warnings;
use strict; 

# Get the value of the x offset

print "Please enter the value of the x-offset. Enter 0 if you do not wish to offset:\n";
my $x_offset; 
$x_offset = <STDIN>;
chomp $x_offset;


# Get the value of Y offset


print "Please enter the value of the y-offset. Enter 0 if you do not wish to offset:\n";
my $y_offset; 
$y_offset = <STDIN>;
chomp $y_offset;


# Get the value of Z offset

print "Please enter the value of the z-offset. Enter 0 if you do not wish to offset:\n";
my $z_offset; 
$z_offset = <STDIN>;
chomp $z_offset;

print "Please enter the value of the r-offset. Enter 0 if you do not wish to offset:\n";
my $r_offset; 
$r_offset = <STDIN>;
chomp $r_offset;


########## FILE OPENING CAN BE DONE IN A MODULE ##############

## Open the input file (in the same location) 

# Ask the user to specify the name of the input file

my $file;

print "Please enter the name of the input file:\n";
$file = <STDIN>;

chomp $file;


# Need to make sure that the file name has the extension right. If the user does not specify .nc at the end, add it automatically 
# also, if it's a .txt file, do not append .nc file extension  

unless (($file=~ /\.nc\s*$/i) || ($file =~ /\.txt\s*$/i)) {

    $file .= "\.nc";
}




# as for the output, Im not sure if the user would want the program to append the modified G-code at the end of the input file. For the moment, I've made it so that it
# makes a new output.txt file and then the user can manually paste the code down the bottom wherever they want. win-win!


my $output = "output_change_x_y_z.txt";
my @input_lines;

open (FILE, $file) or die "Could not open the file: $!\n";

#Read the file data into @input_lines; 

@input_lines = <FILE>;
close FILE; 

foreach (@input_lines) {


	#make sure we dont modify the wrong lines
	unless ($_ =~ /^\s*G\d{1,3}(?=.*\b(?:x|y|z)\-?\d{1,5}(?:\.\d{1,5})?)/mi) {
	    next;
	}

	my $temp_x;
	my $temp_y;
	my $temp_z;
	my $temp_r;
	my $rest;

# Extract values from line using regex

	($rest, $temp_x, $temp_y, $temp_z, $temp_r) = ($_=~ /^\s*(G\d{1,2}.*?\b)(?=.*?(?:x|y|z)\-?\d{1,5}(?:\.\d{1,5})?)(?:X(\-?\d{1,5}(?:\.\d{1,4})?))?(?:\s{1,2}Y(\-?\d{1,5}(?:\.\d{1,4})?))?(?:\s{1,2}Z(\-?\d{1,5}(?:\.\d{1,4})?))?(?:\s{1,2}R(\-?\d{1,5}(?:\.\d{1,4})?))?\s*$/mi);

	#add offsets to the values
	if ($temp_z){$temp_z += $z_offset;}
	if ($temp_x){$temp_x += $x_offset;}
	if ($temp_y){$temp_y += $y_offset;}
	if ($temp_r){$temp_r += $r_offset;}


	#print the new-line including the z-value and the rest of the stuff
	$_ = "$rest";
	if ($temp_x) {$_ .= "X$temp_x";}
	if ($temp_y) {$_ .= " Y$temp_y";}
	if ($temp_z) {$_ .= " Z$temp_z";}
	if ($temp_r) {$_ .= " R$temp_r";}
	
	#	$_ = "$rest"."X$temp_x Y$temp_y Z$temp_z";
	}
	

# Open the output file and print the modified code there

open (OUTPUT, ">$output") or die "Could not open output file";
print OUTPUT join ("\n", @input_lines), "\n"; 

exit 0;
