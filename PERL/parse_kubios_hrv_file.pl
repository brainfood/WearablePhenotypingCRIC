#!/usr/bin/perl
use strict;

#Rows that I need from the hrv file:
# 9: start time
# 50: sample IDs for sampling times
# 51: time spans for each sampling
# 54: Artifacts corrected %
# 59: sample IDs for all the results
# 62-75: Time-domain results (every other column)
# 77: Frequency-Domain labels (alternating between "FFT spectrum" and "AR spectrum")
# 79-81: Peak frequences results
# 83-88: Absolute powers results
# 90-92: Relative powers results
# 94-95: Normalized powers results
# 96-97: Additional frequency domain labels
# 98: EDR (every other column - FFT spectrum only)
# 100-137: Nonlinear Results

#This script will accept a file of Kubios results, extract the
#needed results, and then formats the results for further analysis
#with R.

#Usage: perl parse_kubios_hrv_file.pl kubios_file.txt > formatted_results.txt

my $input_file = $ARGV[0];


#Specific lines from the input file that this script will be collecting
my $measurement_date = "";
my @sampleIDs = ();
#List of all metrics gathered from the file
my @metric_list = ();
#Hash of arrays storing all of the metrics gathered from the file.
#   Key = metric name (corresponds to entries in the @metric_list)
#   Value = array listing the corresponding metric values from each
#           of the samples (corresponding to the samples in @sampleIDs
#           and listed in the same order).
#my %metric_data = ();

#Two-dimensional array. 1st dim is for the different metrics
#(correponding to entries in @metric_list). 2nd dim is for
#each of the samples (corresponding to the samples in @sampleIDs).
my @metric_data = ();

#Current line of input
my $line = "";
#Current input line split by delimiter
my @line_data;
#Measurements from current metric being processed
my @curr_metric;


open(INFILE, $input_file) or die "Cannot find or open $input_file: $!\n\n";

#Step through file to find start of measurement period
do {
    $line = <INFILE>;
} until($line =~ m/^Measurement date/);

#Record when the measurement period starts
chomp($line);
$line =~ m/Measurement date: (\d+\/\d+\/\d+) (\d+:\d+:\d+)/;
$measurement_date = "$1 $2";

#Step through file until sample and sample time listings
do {
    $line = <INFILE>;
} until($line =~ m/RR Interval Samples Selected for Analysis/);

#Extract sample IDs
$line = <INFILE>;
chomp($line);
@line_data = split(",", $line);
for(my $sample = 1; $sample <= $#line_data; $sample++) {
    $sampleIDs[($sample - 1)] = trim($line_data[$sample]);
}

#Extract corresponding measurement times
$line = <INFILE>;
chomp($line);
@line_data = split(",", $line);
push(@metric_list, "Measurement Periods");
my @curr_metric = ();
for(my $sample = 1; $sample <= $#line_data; $sample++) {
    push(@curr_metric, trim($line_data[$sample]));
}
push(@metric_data, \@curr_metric);


#Extract "Artifacts corrected"
$line = <INFILE>;
$line = <INFILE>;
$line = <INFILE>;
chomp($line);
@line_data = split(",", $line);
push(@metric_list, trim($line_data[0]));
my @curr_metric = extract_column_data($line);
push(@metric_data, \@curr_metric);


#Progress to Time-Domain results
do {
    $line = <INFILE>;
} until($line =~ m/Time-Domain Results/);


#Process "Statistical parameters" series of measurements
$line = <INFILE>;
$line = <INFILE>;
do {
    chomp($line);
    @line_data = split(",", $line);
    push(@metric_list, trim($line_data[0]) . "...Time_Domain_Results...Statistical_parameters");
    my @curr_metric = extract_column_data($line);
    push(@metric_data, \@curr_metric);
    
    $line = <INFILE>;
} until($line =~ m/Geometric parameters/);
#Process "Geometric parameters" series of measurements
$line = <INFILE>;
do {
    chomp($line);
    @line_data = split(",", $line);
    push(@metric_list, trim($line_data[0]) . "...Time_Domain_Results...Geometric_parameters");
    my @curr_metric = extract_column_data($line);
    push(@metric_data, \@curr_metric);
    
    $line = <INFILE>;
} until($line =~ m/^\r$/);


#Process Frequency-Domain Results
#Peak frequencies
$line = <INFILE>;
$line = <INFILE>;
$line = <INFILE>;
do {
    chomp($line);
    @line_data = split(",", $line);
    push(@metric_list, trim($line_data[0]) . "...Frequency_Domain_Results...Peak_frequencies...FFT_spectrum");
    push(@metric_list, trim($line_data[0]) . "...Frequency_Domain_Results...Peak_frequencies...AR_spectrum");
    my @curr_metric = extract_column_data($line);
    my @fft_data = get_even_elements(@curr_metric);
    my @ar_data = get_odd_elements(@curr_metric);
    push(@metric_data, \@fft_data);
    push(@metric_data, \@ar_data);
    
    $line = <INFILE>;
} until($line =~ m/Absolute powers/);
#Absolute powers
$line = <INFILE>;
do {
    chomp($line);
    @line_data = split(",", $line);
    push(@metric_list, trim($line_data[0]) . "...Frequency_Domain_Results...Absolute_powers...FFT_spectrum");
    push(@metric_list, trim($line_data[0]) . "...Frequency_Domain_Results...Absolute_powers...AR_spectrum");
    my @curr_metric = extract_column_data($line);
    my @fft_data = get_even_elements(@curr_metric);
    my @ar_data = get_odd_elements(@curr_metric);
    push(@metric_data, \@fft_data);
    push(@metric_data, \@ar_data);
    
    $line = <INFILE>;
} until($line =~ m/Relative powers/);
#Relative powers
$line = <INFILE>;
do {
    chomp($line);
    @line_data = split(",", $line);
    push(@metric_list, trim($line_data[0]) . "...Frequency_Domain_Results...Relative_powers...FFT_spectrum");
    push(@metric_list, trim($line_data[0]) . "...Frequency_Domain_Results...Relative_powers...AR_spectrum");
    my @curr_metric = extract_column_data($line);
    my @fft_data = get_even_elements(@curr_metric);
    my @ar_data = get_odd_elements(@curr_metric);
    push(@metric_data, \@fft_data);
    push(@metric_data, \@ar_data);
    
    $line = <INFILE>;
} until($line =~ m/Normalized powers/);
#Normalized powers
$line = <INFILE>;
do {
    chomp($line);
    @line_data = split(",", $line);
    push(@metric_list, trim($line_data[0]) . "...Frequency_Domain_Results...Normalized_powers...FFT_spectrum");
    push(@metric_list, trim($line_data[0]) . "...Frequency_Domain_Results...Normalized_powers...AR_spectrum");
    my @curr_metric = extract_column_data($line);
    my @fft_data = get_even_elements(@curr_metric);
    my @ar_data = get_odd_elements(@curr_metric);
    push(@metric_data, \@fft_data);
    push(@metric_data, \@ar_data);
    
    $line = <INFILE>;
} until($line =~ m/Total power/);
#Remaining fields
do {
    chomp($line);
    @line_data = split(",", $line);
    push(@metric_list, trim($line_data[0]) . "...Frequency_Domain_Results...FFT_spectrum");
    push(@metric_list, trim($line_data[0]) . "...Frequency_Domain_Results...AR_spectrum");
    my @curr_metric = extract_column_data($line);
    my @fft_data = get_even_elements(@curr_metric);
    my @ar_data = get_odd_elements(@curr_metric);
    push(@metric_data, \@fft_data);
    push(@metric_data, \@ar_data);
    
    $line = <INFILE>;
} until($line =~ m/EDR \(Hz\)/);
#EDR (Hz) - only present for FFT data
chomp($line);
@line_data = split(",", $line);
push(@metric_list, trim($line_data[0]) . "...Frequency_Domain_Results...FFT_spectrum");
my @curr_metric = extract_column_data($line);
push(@metric_data, \@curr_metric);

#Process Nonlinear Results
#Poincare plot
$line = <INFILE>;
$line = <INFILE>;
$line = <INFILE>;
$line = <INFILE>;
do {
    chomp($line);
    @line_data = split(",", $line);
    push(@metric_list, trim($line_data[0]) . "...Nonlinear_Results...Poincare_plot");
    my @curr_metric = extract_column_data($line);
    push(@metric_data, \@curr_metric);
    
    $line = <INFILE>;
} until($line =~ m/Approximate entropy \(ApEn\)/);
#Process remaining Nonlinear Results
do {
    chomp($line);
    @line_data = split(",", $line);
    push(@metric_list, trim($line_data[0]) . "...Nonlinear_Results");
    my @curr_metric = extract_column_data($line);
    push(@metric_data, \@curr_metric);
    
    $line = <INFILE>;
} until($line =~ m/Detrended fluctuation analysis \(DFA\)/);
$line = <INFILE>;
do {
    chomp($line);
    @line_data = split(",", $line);
    push(@metric_list, trim($line_data[0]) . "...Nonlinear_Results...Detrended_fluctuation_analysis");
    my @curr_metric = extract_column_data($line);
    push(@metric_data, \@curr_metric);
    
    $line = <INFILE>;
} until($line =~ m/Correlation dimension \(D2\)/);

chomp($line);
@line_data = split(",", $line);
push(@metric_list, trim($line_data[0]) . "...Nonlinear_Results");
my @curr_metric = extract_column_data($line);
push(@metric_data, \@curr_metric);
$line = <INFILE>;
#Process "Recurrence plot analysis (RPA)"
$line = <INFILE>;
do {
    chomp($line);
    @line_data = split(",", $line);
    push(@metric_list, trim($line_data[0]) . "...Nonlinear_Results...Recurrence_plot_analysis");
    my @curr_metric = extract_column_data($line);
    push(@metric_data, \@curr_metric);
    
    $line = <INFILE>;
} until($line =~ m/Multiscale entropy \(MSE for scales 1-20\)/);
#Process "Multiscale entropy (MSE for scales 1-20)"
$line = <INFILE>;
do {
    chomp($line);
    @line_data = split(",", $line);
    push(@metric_list, trim($line_data[0]) . "...Nonlinear_Results...Multiscale_entropy");
    my @curr_metric = extract_column_data($line);
    push(@metric_data, \@curr_metric);
    
    $line = <INFILE>;
} until($line =~ m/^\r$/);

close(INFILE);


#Now print the collected measurement results. Each row will contain data
#for a different sample, and each column will contain all of the measurements
#from a single metric.

#Print header
print "SampleIDs\tMeasurement_Start";
foreach my $metric (@metric_list) {
    $metric =~ s/://g;
    $metric =~ s/ /_/g;
    print "\t$metric";
}
print "\n";

#Print all measurements
for(my $sample = 0; $sample <= $#sampleIDs; $sample++) {
    
    print "$sampleIDs[$sample]\t$measurement_date";
    
    for(my $metric = 0; $metric <= $#metric_list; $metric++) {
        print "\t" . $metric_data[$metric][$sample];
    }
    
    print "\n";
}


#Helper functions to assist with parsing output

#Extract measurements from current line of input. This function excludes
#any empty columns and returns the results in an array.
sub extract_column_data {
    my ($input_line) = @_;
    
    #Remove missing columns (two commmas just separated by white space)
    $input_line =~ s/,\s+,/,/g;
    
    #Split measurements
    my @split_data = split(",", $input_line);
    
    #Load output array
    my @out_measurement = ();
    for(my $sample = 1; $sample <= $#line_data; $sample++) {
        push(@out_measurement, trim($split_data[$sample]));
    }
    
    return(@out_measurement);
}


#Given an array, return only the odd elements from the input
#array, and return them as a new array
sub get_odd_elements {
    my @input_data = @_;
    
    my @output_subset = ();
    for(my $sample = 0; $sample <= $#input_data; $sample++) {
        if($sample % 2 == 0) {
            push(@output_subset, $input_data[$sample]);
        }
    }
    return(@output_subset);
}

#Given an array, return only the even elements from the input
#array, and return them as a new array
sub get_even_elements {
    my @input_data = @_;
    
    my @output_subset = ();
    for(my $sample = 0; $sample <= $#input_data; $sample++) {
        if($sample % 2 != 0) {
            push(@output_subset, $input_data[$sample]);
        }
    }
    return(@output_subset);
}

#Remove all leading and trailing whitespace
sub trim {
    my ($input_line) = @_;
    chomp($input_line);
    $input_line =~ s/^\s+//;
    $input_line =~ s/\s+$//;
    return($input_line);
}
