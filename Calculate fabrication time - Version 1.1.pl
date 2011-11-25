#!/usr/bin/perl 

use warnings;
use strict; 



## Open the input file (in the same location) 

# Ask the user to specify the name of the input file

my $file;

print "Please enter the name of the file:\n";
$file = <STDIN>;

chomp $file;


# Need to make sure that the file name has the extension right. If the user does not specify .nc at the end, add it automatically 
# also, if it's a .txt file, do not append .nc file extension  

unless (($file=~ /\.nc\s*$/i) || ($file =~ /\.txt\s*$/i)) {

    $file .= "\.nc";
}



my @input_lines;

open (FILE, $file) or die "Could not open the file: $!\n";

#Read the file data into @input_lines; 

@input_lines = <FILE>;
close FILE; 


# Prompt the user for the F-value

my ($f_value, $count, $fabrication_time);
print "Please enter the F-value\n";
$f_value = <STDIN>;
chomp $f_value; 

$count = 1;

my $summation = 0;


# Create a flag for yes-to-all 

my ($x_all, $y_all, $z_all);



# Create arrays for values that roll-over each time. 
my (@x_values, @y_values, @z_values);


# Check the code for elements that go outside the acceptable area

foreach (@input_lines) {

    # make sure we don't process lines other than the actual process lines (or whatever) 

    unless ($_ =~ /^\s*G\s?\d{1,3}(?=.*(?:X|Y|Z))/i) {
	next;
    }

 #   print $_;

    #simply take in every line and read the x,y,z values
    my ($x_check, $y_check, $z_check); 

    ($x_check) = ($_ =~ /\bX(\-?\d{1,5}(?:\.\d{1,4})?)\b/i);

 
    ($y_check) = ($_ =~ /\bY(\-?\d{1,5}(?:\.\d{1,4})?)\b/i); 
    ($z_check) = ($_ =~ /\bZ(\-?\d{1,5}(?:\.\d{1,4})?)\b/i); 



    # Set all the values to 0 so the program won't throw out an error if the value is empty

    unless ($x_check) {
	$x_check = 0;
    }


    unless ($y_check) {
	$y_check = 0;
    }


    unless ($z_check) {
	$z_check = 0;
    }



    # Check for X 

    if (($x_check <-75) || ($x_check>85)) {

    # Check if we're having left nozzle
	if (($x_check<120) && ($x_check > 85)) {
	    print "WARNING! one of the x-values is $x_check. This is outside the regular extruding area, but if you remove the left nozzle, it can be accommodated. Would you like to continue (Y/N)?\n";

	    my $answer;
	    $answer = <STDIN>;
	    chomp $answer; 
	    if ($answer =~ /^\s*n/i) {
		exit;
	    }
	}

	else {

	    print "WARNING! one of the x-values is $x_check. This is outside the regular extruding area. The normal limits are -75, 85 or -75,120 if left nozzle is absent. Would you like to continue (Y/N)?\n";

	    my $answer;
	    $answer = <STDIN>;
	    chomp $answer; 
	    if ($answer =~ /^\s*n/i) {
		exit;
	    }
	}
    }

    if (($y_check <-95) || ($y_check>0)) {

    # Check if door open

	if (($y_check>-110) && ($y_check <-95)) {
	    print "WARNING! one of the y-values is $y_check. This is outside the regular extruding area, but if you keep the door open, it can be accommodated. Would you like to continue (Y/N)?\n";

	    my $answer;
	    $answer = <STDIN>;
	    chomp $answer; 
	    if ($answer =~ /^\s*n/i) {
		exit;
	    }
	}

	else {

	    print "WARNING! one of the y-values is $y_check. This is outside the regular extruding area. The normal limits are -95, 0 or -110,0 if door is open. Would you like to continue (Y/N)?\n";

	    my $answer;
	    $answer = <STDIN>;
	    chomp $answer; 
	    if ($answer =~ /^\s*n/i) {
		exit;
	    }
	}
    }

    if (($z_check <-14.8) || ($z_check>50)) {

	# Check if we're having left nozzle
	
	print "WARNING! one of the z-values is $z_check. This is outside the regular extruding area, but depending on the nozzle/needle length, it can perhaps be accommodated. Would you like to continue (Y/N)?\n";

	my $answer;
	$answer = <STDIN>;
	chomp $answer; 
	if ($answer =~ /^\s*n/i) {
	    exit;
	}
	

    }


}

print "The code has been checked for \"out of bounds\" elements. All systems go!\n";

foreach (@input_lines) {


	# Make sure we dont modify the wrong lines
	unless ($_ =~ /z\-?\d{1,5}(?:\.\d{1,4})?\s*$/mi) {

		next;
	}




	# Set the initial values to zero. That way, if a value is blank in the g-code (highly unlikely)
	# then we won't have a total crash. 

	my ($x, $y, $z);

	($x, $y, $z) = ($_=~ /.*X(\-?\d{1,5}(?:\.\d{1,4})?)\s{1,2}Y(\-?\d{1,5}(?:\.\d{1,4})?)\s{1,2}Z(\-?\d{1,5}(?:\.\d{1,4})?)\s*$/mi);

	# The first line would not have any preceding values, so skip that 

	

	# Push the new values to the end of the array

	push (@x_values, $x);
	push (@y_values, $y);
	push (@z_values, $z);


    # Remove the first element of the array, promoting the second element to its place 
	
	unless (($count ==1) || ($count ==2)) {
	    shift (@x_values);
	    shift (@y_values);
	    shift (@z_values);

	}



	# Now add! 


	# If I dont add the unless statement, it'll throw an annoying error message (which might cause the user to panic). 

        # Note that the error itself is pretty harmless. 
	unless ($count == 1) {

	my $temp = sqrt (($x_values[1]-$x_values[0])**2+($y_values[1]-$y_values[0])**2+($z_values[1]-$z_values[0])**2);
	


	$summation += $temp;
	}
	++$count;



	}
	

$fabrication_time = $summation/$f_value;

print "The total pathlength is $summation mm\n";
print "The fabrication time is: $fabrication_time minutes\n";
print "\nPress Enter to exit\n";
<>;


exit 0;
