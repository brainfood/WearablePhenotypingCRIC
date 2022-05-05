#!/usr/bin/perl
use strict;

#The Zephyr biopatch records accelerometer information in 3
#axes of motion (vertical, lateral, and sagittal) at 100 Hz.
#This script accepts an accelerometer data file (*_Accel.csv),
#averages the data across every minute, converts the data from
#bits to G, and calculates a single vector magnitude value for
#the activity at each minute. This script then outputs the
#data/time for each minute, along with the vector magnitude
#value in comma-delimited format. Note, this script does filter
#out entries that contain invalid accelerometer values (4095),
#output which timepoints & axes contain invalid values, and
#finally prints the total number of invalid values filtered
#for each axis of motion. All information about invalid values
#is printed to STDERR.

#Usage: perl parse_zephyr_accel_file.pl zephyr_Accel.csv > formatted_results.csv

#Number of bits for each unit g.
my $bits_to_g = 83;
#Zephyr biopatch marks invalid entries with these values.
my %invalid_values = ('4095', 1);

my $input_filename = $ARGV[0];

#Track the running sum of each axis of motion for the
#current epoch being processed.
my $vertical_sum;
my $lateral_sum;
my $sagittal_sum;
#Total number of valid timepoints processed from each axis of
#motion in the current epoch.
my $vertical_count = 0;
my $lateral_count = 0;
my $sagittal_count = 0;

#Tracks the current date/time (up to the minute) of the current
#epoch being processed.
my $curr_epoch;

#Tracks total number of invalid values for each axis of motion.
my $vertical_invalid = 0;
my $lateral_invalid = 0;
my $sagittal_invalid = 0;
#Tracks total number of timepoints which contain invalid values.
my $total_invalid = 0;

open(INFILE, $input_filename) or die "Cannot find or open $input_filename: $!\n";

#Skip header line
my $line = <INFILE>;

#Print new header
print "Time,Vertical,Lateral,Sagittal,VectorMagnitude\n";

#Prime loop with first line of data
$line = <INFILE>;
chomp($line);

#Extract time from current line, and data from each axis of motion
my ($curr_time, $curr_vertical, $curr_lateral, $curr_sagittal) = split(",", $line);
$vertical_sum = $curr_vertical;
$lateral_sum = $curr_lateral;
$sagittal_sum = $curr_sagittal;

#Check motion data for invalid entries

#Flag - 1: Any axis of motion for current timepoint contains
#          invalid value.
#       0: None of the axes of motion for current timepoint
#          contain invalid value.
my $any_invalid = 0;

#If invalid values found, set to 0 so they won't contribute
#to running sums for each axis of motion.
if($invalid_values{$curr_vertical} == 1) {
    print STDERR "Invalid vertical value ($curr_vertical) at $curr_time\n";
    $curr_vertical = 0;
    $vertical_invalid++;
    $any_invalid = 1;
} else { $vertical_count++; }
if($invalid_values{$curr_lateral} == 1) {
    print STDERR "Invalid lateral value ($curr_lateral) at $curr_time\n";
    $curr_lateral = 0;
    $lateral_invalid++;
    $any_invalid = 1;
} else { $lateral_count++; }
if($invalid_values{$curr_sagittal} == 1) {
    print STDERR "Invalid sagittal value ($curr_sagittal) at $curr_time\n";
    $curr_sagittal = 0;
    $sagittal_invalid++;
    $any_invalid = 1;
} else { $sagittal_count++; }

#Increments count of total number of timepoints with invalid
#values if any of the axes of motion contain an invalid value.
$total_invalid += $any_invalid;

#Extract data, hour, and minute from current time point
$curr_time =~ m/(\d+\/\d+\/\d+ \d+:\d+):\d+/;
$curr_epoch = $1;

while($line = <INFILE>) {
    
    chomp($line);
    
    #Extract time from current line, and data from each axis of motion
    ($curr_time, $curr_vertical, $curr_lateral, $curr_sagittal) = split(",", $line);
    
    #Check if current time comes from the same epoch being processed
    $curr_time =~ m/(\d+\/\d+\/\d+ \d+:\d+):\d+/;
    my $new_epoch = $1;
    
    if($new_epoch ne $curr_epoch) {
        
        #Process and output current epoch
        
        #Calculate mean activity in each axis of motion across
        #the current epoch.
        my $vertical_mean = $vertical_sum / $vertical_count;
        my $lateral_mean = $lateral_sum / $lateral_count;
        my $sagittal_mean = $sagittal_sum / $sagittal_count;
        
        #Convert activity data from bits to g
        $vertical_mean = $vertical_mean / $bits_to_g;
        $lateral_mean = $lateral_mean / $bits_to_g;
        $sagittal_mean = $sagittal_mean / $bits_to_g;
        
        #Calculate vector magnitude from axis data
        my $vector_magnitude = sqrt(($vertical_mean**2 + $lateral_mean**2 + $sagittal_mean**2));
        
        #Format output values to use two decimal places
        $vertical_mean = sprintf "%.2f", $vertical_mean;
        $lateral_mean = sprintf "%.2f", $lateral_mean;
        $sagittal_mean = sprintf "%.2f", $sagittal_mean;
        $vector_magnitude = sprintf "%.2f", $vector_magnitude;
        
        #Output time of epoch along with vector magnitude
        print "$curr_epoch:00,$vertical_mean,$lateral_mean,$sagittal_mean,$vector_magnitude\n";
        
        #Update variables to reflect new epoch
        $curr_epoch = $new_epoch;
        ($vertical_sum, $lateral_sum, $sagittal_sum, $vertical_count, $lateral_count, $sagittal_count) = 0;
    }
    
    #Check motion data for invalid entries
    $any_invalid = 0;
    
    #If invalid values found, set to 0 so they won't contribute
    #to running sums for each axis of motion.
    if($invalid_values{$curr_vertical} == 1) {
        print STDERR "Invalid vertical value ($curr_vertical) at $curr_time\n";
        $curr_vertical = 0;
        $vertical_invalid++;
        $any_invalid = 1;
    } else { $vertical_count++; }
    if($invalid_values{$curr_lateral} == 1) {
        print STDERR "Invalid lateral value ($curr_lateral) at $curr_time\n";
        $curr_lateral = 0;
        $lateral_invalid++;
        $any_invalid = 1;
    } else { $lateral_count++; }
    if($invalid_values{$curr_sagittal} == 1) {
        print STDERR "Invalid sagittal value ($curr_sagittal) at $curr_time\n";
        $curr_sagittal = 0;
        $sagittal_invalid++;
        $any_invalid = 1;
    } else { $sagittal_count++; }
    #Increments count of total number of timepoints with invalid
    #values if any of the axes of motion contain an invalid value.
    $total_invalid += $any_invalid;
    
    #Update with motion data from this epoch.
    $vertical_sum += $curr_vertical;
    $lateral_sum += $curr_lateral;
    $sagittal_sum += $curr_sagittal;
    
}
close(INFILE);


#Process and output last epoch

#Calculate mean activity in each axis of motion across
#the current epoch.
my $vertical_mean = $vertical_sum / $vertical_count;
my $lateral_mean = $lateral_sum / $lateral_count;
my $sagittal_mean = $sagittal_sum / $sagittal_count;

#Convert activity data from bits to g
$vertical_mean = $vertical_mean / $bits_to_g;
$lateral_mean = $lateral_mean / $bits_to_g;
$sagittal_mean = $sagittal_mean / $bits_to_g;

#Calculate vector magnitude from axis data
my $vector_magnitude = sqrt(($vertical_mean**2 + $lateral_mean**2 + $sagittal_mean**2));

#Format output values to use two decimal places
$vertical_mean = sprintf "%.2f", $vertical_mean;
$lateral_mean = sprintf "%.2f", $lateral_mean;
$sagittal_mean = sprintf "%.2f", $sagittal_mean;
$vector_magnitude = sprintf "%.2f", $vector_magnitude;

#Output time of epoch along with vector magnitude
print "$curr_epoch:00,$vertical_mean,$lateral_mean,$sagittal_mean,$vector_magnitude\n";


#Print summary info for number of invalid values
if($total_invalid > 0) {
    print STDERR "\n-------------------------------------------\n";
    print STDERR "  Vertical invalid count: $vertical_invalid\n";
    print STDERR "   Lateral invalid count: $lateral_invalid\n";
    print STDERR "  Saggital invalid count: $sagittal_invalid\n\n";
    print STDERR "Total invalid timepoints: $total_invalid\n";
}

