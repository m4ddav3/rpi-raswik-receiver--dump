#!env perl
use strict; use warnings;

our $|++;

use Device::SerialPort;

our $LLAP_MESSAGE_SIZE = 12;

#my $port = '/dev/ttyAMA0';
my $port = '/dev/ttyS0';
my $baud = 9600;

my $identifier = 'BB';

my $com = Device::SerialPort->new($port);
$com->baudrate($baud);

my $timeout = 10;
my $chars   = 0;
my $buffer  = '';

my $command = sprintf("a%s%s", $identifier, 'HELLO');
$command .= '-' x ($LLAP_MESSAGE_SIZE - length($command));

$com->lookclear();

my ($count, $saw);

while ($timeout > 0) {
    ($count, $saw) = $com->read(255);

    if ($count) {
        print STDERR sprintf("Read %d chars\n", $count);

        $chars  += $count;
        $buffer .= $saw;

        $count = 0;
        $saw   = '';
    }

    if ($chars) {
        if ($buffer !~ m/^a/) {
            $buffer =~ s/^(.+?a)/a/s;
            #print "discarded: $1\n";
            $chars = length($buffer);
        }

        if (length($buffer) < $LLAP_MESSAGE_SIZE) {
            print "Not enough buffer ($chars)\n";
            $timeout -= 0.01;
            select(undef, undef, undef, 0.1);
            next;
        }

        print "buffer = $buffer\n";

        #if ($chars >= $LLAP_MESSAGE_SIZE) {
            #print sprintf("Received: %s\n", $saw);

            ## Get the message
            #$buffer =~ s!^(a$identifier.{9})!!;
            #my $message = $1;
            my ($message) = $buffer =~ m/^(a$identifier.{9})/;

            if (!$message) {
                $timeout -= 0.01;
                select(undef, undef, undef, 0.1);
                next;
            }
            substr($buffer, 0, length($message), '');
            $chars = length($buffer);

            print sprintf("<< %s\n", $message);

            if ($message =~ m/^a$identifier(HELLO----)/) {
                print sprintf("Command succeeded: %s\n", $command);
                $message =~ s/HELLO----/YESHELLO-/;
                $com->write(sprintf("a%s%s", $identifier, $message));
            }
        #}
    }
    else {
        #$timeout--;
        #print STDERR sprintf("Chars: %03d, Buffer: %s\n", $chars, $buffer);
        #if ($timeout > 0) {
            #select undef, undef, undef, 0.1;
            select undef, undef, undef, 0.1;
        #}
    }
}

if ($timeout == 0) {
    print STDERR "Link timed out\n";
}
