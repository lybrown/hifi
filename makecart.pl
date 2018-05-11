#!/usr/bin/perl
use strict;
use warnings;
use File::Slurp;
use Getopt::Long;

my %args = (maxmem => 1<<20);

sub slurp {
    return read_file($_[0], binmode => ':raw');
}

# play:
#   $0000
#   $0100
#   $0200
#   ...
#   $1F00
#   $0001
#   $0101
#   $0201
#   ...
#   $1F01
#   ...
#   $00FF
#   $01FF
#   ...
#   $1FFF
#  

sub music {
    my ($data) = @_;
    my $music = '';
    my $chunksize = $args{ram} ? 16384 : 8192;
    my $bankcount = $args{ram} ? 64 : 32;
    # Swizzle
    while ($data) {
        my @data = split //, substr $data, 0, $chunksize, "";
        my @music;
        for (my $i = 0; $i < $bankcount; ++$i) {
            for (my $j = 0; $j < 256; ++$j) {
                $music[$i*256+$j] = $data[$j*$bankcount+$i] // 0;
            }
        }
        $music .= join "", @music;
    }
    return $music;
}

sub usage {
    die "Usage: makecart [bank0.bin data.bin] [-ram player.obx data.bin]\n";
}

sub cart {
    my $bank0 = slurp $ARGV[0];
    my $data = slurp $ARGV[1];
    $data = music($data);

    length $bank0 eq 8192 or die "ERROR: bank0 must be 8K\n";

    $data = $bank0 . $data;

    $data = substr $data, 0, 128 * (1<<20);
    my $len = length $data;

    my $size =
        $len > 64 * (1<<20) ? 128 :
        $len > 32 * (1<<20) ? 64 :
        32;
    my $type =
        $size == 128 ? 62 :
        $size == 64 ? 66 :
        $size == 32 ? 65 :
        die "ERROR: No type for size $size\n";

    my $checksum = unpack "%32W*", $data;

    # .CAR header
    print "CART";
    print pack "NNN", $type, $checksum, 0;
    print $data;
    # Altirra is OK with short .CAR
    #print "\0" for 0 .. ($size * (1<<20)) - $len;
}

sub ram {
    my $obx = slurp $ARGV[0];
    my $data = slurp $ARGV[1];
    $data = music($data);
    $data = substr $data, 0, $args{maxmem} if length $data > $args{maxmem};
    print $obx;
    while ($data) {
        my $chunk = substr $data, 0, 16384, "";
        print pack "vvv", 0x2E2, 0x2E3, 0x3000;
        print pack "vv", 0x4000, 0x7FFF;
        print $chunk;
    }
}

sub main {
    GetOptions(\%args,
        "ram!",
        "maxmem=i",
    ) or usage();
    $ARGV[1] or usage();
    if ($args{ram}) {
        ram();
    } else {
        cart();
    }
}

main();
