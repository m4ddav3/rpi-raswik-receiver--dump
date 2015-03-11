#!env perl
use strict; use warnings;

our $|++;

use Device::SerialPort;

our $LLAP_MESSAGE_SIZE = 12;

#my $port = '/dev/ttyAMA0';
my $port = '/dev/ttyS0';
my $baud = 9600;

my $identifier = '--';

my $com = Device::SerialPort->new($port);
$com->baudrate($baud);

my $timeout = 10;
my $chars   = 0;
my $buffer  = '';

my ($pin, $value) = @ARGV;

my $command = sprintf('a%s%s%s', $identifier, $pin, $value);
$command .= '-' x ($LLAP_MESSAGE_SIZE - length($command));

$com->lookclear();
#$com->write($command);

#if (!$com->can_write_done) {
#    sleep 2;
#}
#else {
#    $com->write_done(0);
#    select undef, undef, undef, 0.2;
#}

while ($timeout > 0) {
    my ($count, $saw) = $com->read(12);

    if ($count) {
        $chars += $count;
        $buffer .= $saw;

        if ($chars >= $LLAP_MESSAGE_SIZE) {
            print sprintf("Received: %s\n", $saw);

            #print STDERR sprintf("Buffer: %s\n", $buffer);
            ## Get the message
            #my ($match) = $buffer =~ s!(.*?)?(a$identifier.{9})!!;

            #if ($match) {
            #    my ($waste, $message) = ($1, $2);

            #    if ($waste) {
            #        print STDERR sprintf("Dropped this data: %s\n", $waste);
            #    }

            #    print sprintf("Message is: %s\n", $message);
            #    if ($message eq $command) {
            #        print sprintf("Command succeeded: %s\n", $command);
            #    }
            #    else {
            #        print sprintf("Command failed: %s\n", $command);
            #    }
            #    #last;
            #}
            #else {
            #    print sprintf("Discarding: %s\n", $buffer);
            #}
        }
    }
    else {
        #$timeout--;
        #print STDERR sprintf("Chars: %03d, Buffer: %s\n", $chars, $buffer);
        #if ($timeout > 0) {
            #select undef, undef, undef, 0.1;
            select undef, undef, undef, 0.3;
        #}
    }
}

if ($timeout == 0) {
    print STDERR "Link timed out\n";
}
