#!env perl
use strict; use warnings;

use DBI;
use Device::SerialPort;

our $db = DBI->connect("dbi:SQLite:dbname=LLAPDB");#,"","");

my $insert = $db->prepare("INSERT INTO samples (time, message) values (?, ?)");

our $LLAP_MESSAGE_SIZE = 12;

my $port = '/dev/ttyAMA0';
my $baud = 9600;

my $identifier = '--';

my $com = Device::SerialPort->new($port);
$com->baudrate($baud);

my $timeout = 10;

my $chars  = 0;
my $buffer = '';

my ($pin, $value) = @ARGV;
$value //= '';

my $command = sprintf('a%s%s%s', $identifier, $pin, $value);
$command .= '-' x ($LLAP_MESSAGE_SIZE - length($command));

$com->lookclear();
$com->write($command);
print sprintf(">> %s\n", $command);

if (!$com->can_write_done) {
    sleep 2;
}
else {
    $com->write_done(0);
    select undef, undef, undef, 0.2;
}

sub check_valid_message($) {
    my ($buffer) = @_;

}

while ($timeout > 0) {
    print sprintf("-- timeout = %d\n", $timeout);
    my ($count, $saw) = $com->read(255);

    if ($count) {
        $chars  += $count;
        $buffer .= $saw;

        if ($buffer !~ m/^a/) {
            $buffer =~ s/^(.+?)a//s;
        }

        if ($buffer !~ m/^a.{12}/) {
            $timeout -= 0.01;
            select(undef, undef, undef, 0.1);
            next;
        }

        if ($chars >= $LLAP_MESSAGE_SIZE) {
            # Get the message
            my ($message) = $buffer =~ s!^(a$identifier.{9})!!;
            $count = length($buffer);
            print sprintf("<< %s\n", $message);
            $insert->execute(time(), $message);
        }
    }
    else {
        $timeout--;

        if ($timeout) {
            select(undef, undef, undef, 0.1);
        }
    }
}

if ($timeout == 0) {
    print STDERR "Link timed out\n";
}
