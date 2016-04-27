#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(switch say);
use REST::Client;
use JSON;
use MIME::Base64;
use Data::Dumper;

# files to store previos alarm status and the information of the created ticket
my $status_file = "/home/ubuntu/check_status/.status_file";
my $ticket_info = "/home/ubuntu/check_status/.ticket_info";

# Jira API auth details
my $username = <username>;
my $password = <password>;
my $headers = {Accept => 'application/json', Authorization => 'Basic ' . encode_base64($username . ':' . $password)};
my $client = REST::Client->new();
$client->setHost('<url>');

# command to check apache2 service status
my $check_apache = `service apache2 status \|awk '{print \$4}'`;

# check the recorded status of alarm
sub check_status {
	open my $file, '<', $status_file or die;
	my $status = <$file>; 
	close $file;
	return $status;
}

# change the status of alarm
sub set_status {
    # if $bit = 0 then apache2 status was OK
    # if $bit = 1 then apache2 status was CRITICAL
	my $bit = @_;
	open my $file, '+>', $status_file or die;
	print $file $bit;
	close $file;
}

# opend and resolve the issue
sub jira_issue {
	my $action = @_;
	chomp($action);
	if ($action eq "open") {
		my $issue = {
            fields => {
                summary     => "Created via REST",
                description => "Creating of an issue using the REST API",
                issuetype   => { name => "Bug" },
                project     => { key => "TEST" } } };
        my $json = to_json $issue;
        $client->POST('rest/api/2/issue/', $json, \%$headers);
        my $response = from_json($client->responseContent());
	open my $file, '+>', $ticket_info or die;
        print $file $response;
        close $file;
	}
	if ($action eq "close") {
		# get details from file
		# close ticket
		# reset file
	}
}

given ($check_apache) {
    chomp($check_apache);
    when ($check_apache eq "running") {
    	print "OK - apache2 service is UP.";
    	unless (check_status()) {
    		set_status(0);
    		jira_issue("close");
    	}
        # exit code is 0, apache2 status is OK
    	exit(0);
    }
    when ($check_apache eq "not") {
    	print "CRITICAL - apache2 service is DOWN";
    	if (check_status()) {
    		set_status(1);
    		jira_issue("open");
    	}
        # exit code is 2, apache2 status is CRITICAL
    	exit(2);
    }
    default {
    	print "UNKNOWN - $check_apache";
        # exit code is 3, something went wrong: check manually
    	exit(3);
    }
}
