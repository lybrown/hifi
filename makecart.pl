#!/usr/bin/perl
use strict;
use warnings;
use File::Slurp;

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
    # Swizzle
    while ($data) {
        my @data = split //, substr $data, 0, 8192, "";
        my @music;
        for (my $i = 0; $i < 32; ++$i) {
            for (my $j = 0; $j < 256; ++$j) {
                $music[$i*256+$j] = $data[$j*32+$i] // 0;
            }
        }
        $music .= join "", @music;
    }
    return $music;
}

sub main {
    $ARGV[1] or die "Usage: makecart bank0.bin data.bin\n";
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

main();
