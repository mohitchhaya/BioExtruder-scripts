#!/usr/bin/perl 


##### POTENTIAL IMPROVEMENTS ######

# Ferry will use this to print several scaffolds at once. For that, he will need to add a "spacer code" to move the nozzle away from the first
# scaffold and move on to the next one in line. Currently the code doesn't support that. Maybe add some sort of logic to automatically add the 
# spacer code? Confirm with Ferry. 

###################################



use warnings;
use strict; 

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


my $output = "output_change_delta_z.txt";
my @input_lines;

open (FILE, $file) or die "Could not open the file: $!\n";

# Read the file data into @input_lines; 

@input_lines = <FILE>;
close FILE; 

my $input_data; 

$input_data = join ('', @input_lines); 



# Let's calculate the current value of step height. I'm assuming that it'll be the same for all layers. If not, need to add a verifying step 

my ($temp_step_initial, $temp_step_final, $start_step);

($temp_step_initial, $temp_step_final) = ($input_data =~ /^\s*G\d{1,2}(?=.*\b(?:x|y|z|p)\-?\d{1,5}(?:\.\d{1,5})?).*Z(\-?\d{1,5}(?:\.\d{1,4})?).*\n(?s:.*?)Z(?!\1\s)(\-?\d{1,5}(?:\.\d{1,4})?)/mi);

$start_step = $temp_step_final - $temp_step_initial;

print "The current value of delta-z is $start_step.\n";
print "Please enter the new value of delta-z. If Z=1 in layer1 and Z=1.25 in the next layer, then delta-z is 0.25 \n";


my ($new_step, $start_position, $step_difference);
$new_step = <STDIN>;

# If the starting value is 0, then the first block would remain zero (that's what the portugese code has done). But, if it's -15 (using the block) then it needs to also modify the first block. 

print "Please enter the starting z-position of the build platform (eg -15). If it is 0, please specify it as such:\n";
$start_position = <STDIN>;
chomp ($new_step, $start_position);



my $count = 1;
my @output_array;

while ($input_data =~ /^(?!.*X0(?:\.0)?\s{1,3}Y0(?:\.0)?\s{1,3}Z0(?:\.0)?).*(?!X0(?:\.0)?\s{1,3}Y0(?:\.0)?\s{1,3}Z0(?:\.0)?)Z(\-?\d{1,5}(?:\.\d{1,4})?).*\n(?:.*Z(?:\1)\s*\n|(?:G\d{1,2}|\%)(?!.*Z\-?\d{1,5}(?:\.\d{1,4})?).*\n|\s*\n){1,}/mig) {

    my @loop_lines;
    @loop_lines = split ("\n", $&);


    foreach (@loop_lines) {

	my $temp_z;
	my $rest;
	my $tail;
	($rest, $temp_z, $tail) = ($_=~ /^\s*(G\d{0,3}.*\b)Z(\-?\d{1,5}(?:\.\d{1,4})?)\b(.*)/mi);
	
	# If there is no Z-value in the line, then don't touch that line. Send it to the output
	# array directly without modifications. 
	unless (defined $temp_z) {
		push (@output_array, $_);
		next;
	}

        # If Z=0/-14.75 in the first batch of lines, we can safely assume that it's the starting position and need not be changed. 

	if ((($temp_z == 0)||($temp_z == -14.75)) && ($count== 1)) {
	    push (@output_array, $_);
            # If the counter is not reset to 0, the first block after 0 would start at double the step :p 
	    $count = 0;
	    next;
	}

	#Set the value of Z variable. 
	$temp_z = $start_position + ($count*$new_step);
	print "$temp_z = $start_position \+ \( $count * $new_step\)\n";

	#remove space at the end (totally a hack) 
	$rest =~ s/\s*$//g;

	#push the line to the end of the output array. We then print this array at the end. 
        push (@output_array, "$rest Z$temp_z$tail");

	
    }
    ++$count;
}


# Open the output file and print the modified code there

open (OUTPUT, ">$output") or die "Could not open output file";
print OUTPUT join ("\n", @output_array), "\n"; 

exit 0;
