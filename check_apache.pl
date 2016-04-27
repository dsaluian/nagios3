#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(switch say);

my $status_file = "/home/ubuntu/check_status/.status_file";
my $ticket_info = "/home/ubuntu/check_status/.ticket_info";

my $username = 'nagios';
my $password = 'passwd_nagios';
my $headers = {Accept => 'application/json', Authorization => 'Basic ' . encode_base64($username . ':' . $password)};

my $check_apache = `service apache2 status \|awk '{print \$4}'`;

sub check_status {
	open my $file, '<', $status_file or die;
	my $status = <$file>; 
	close $file;
	return $status;
}

sub set_status {
	my $bit = @_;
	open my $file, '+>', $status_file or die;
	print $file $bit;
	close $file;
}

sub jira_issue {
	my $action = @_;
	chomp($action);
	if ($action eq "open") {
		# open issue
		# save details to .ticket_info file
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
    	exit(0);
    }
    when ($check_apache eq "not") {
    	print "CRITICAL - apache2 service is DOWN";
    	if (check_status()) {
    		set_status(1);
    		jira_issue("open");
    	}
    	exit(2);
    }
    default {
    	print "UNKNOWN - $check_apache";
    	exit(3);
    }
}