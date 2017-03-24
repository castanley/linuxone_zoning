#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
my %report;
my $server;
while (<>) {
        next if 1 .. /VMT/;
        my ($LPAR,$CSSID,$IID,$CHPID,$SSLD,$DEVNUM,$WWPN,$NPIV,$CC,$PCHID,$PWWPN,$SERVER,$GUESTNAME) = split(/\s+/,$_);
        $server = uc($SERVER);
        my $fabric;
        my @WWPNP = $WWPN =~ /(\S{2})/g;
        $WWPN = join(':', @WWPNP);
        unless ($LPAR eq 'VMT1' or $LPAR eq 'VMT2') {
                print "YOU SHOULDN'T SEE THIS!\n";
                next;
        }
        if ($CHPID == 60 or $CHPID == 63) {
                $fabric = 'HA_6';
        } elsif ($CHPID == 61 or $CHPID == 62) {
                $fabric = 'HA_7';
        } else {
                print "YOU SHOULDN'T SEE THIS!\n";
                next;
        }
        push( @{$report{$LPAR}{$fabric}}, [ $LPAR,$CHPID,$DEVNUM,$WWPN,$SERVER ]);
}

print "\nAliases:\n";
my @zones;
foreach my $lpar (sort keys %report) {
        foreach my $fabric (sort keys %{$report{$lpar}} ) {
                foreach my $record ( @{$report{$lpar}{$fabric}} ) {
                        my ($LPAR,$CHPID,$DEVNUM,$WWPN,$SERVER) = @{$record};
                        print "$WWPN\n";
                        my $alias = sprintf "aLO_%s_%s_%s_%s\n", uc($SERVER),uc($LPAR),lc($DEVNUM),$CHPID;
                        print "$alias";
                        printf "LO_%s_%s_%s_%s\n\n", uc($SERVER),uc($LPAR),lc($DEVNUM),$CHPID;
                        push @zones, sprintf "zLO_%s_%s_%s_%s_%s_%s", uc($SERVER),uc($LPAR),lc($DEVNUM),$CHPID,'VPLEX2',$fabric;
                }
        }
}

print "\nZones:\n";
foreach my $z ( @zones)  {
        print "$z\n";
}
print "\nLO_$server\n\n";
print "volume create -vserver AFF-VPLEX-GP -state online -policy default -snapshot-policy none -aggregate aggr_n5_ssd_4t_1 -volume LO_$server -size \n";
print "lun create -vserver AFF-VPLEX-GP -ostype linux -space-reserve disabled -space-allocation disable -path /vol/LO_$server/LO_${server}_ -size \n";
print "lun map -vserver AFF-VPLEX-GP -path /vol/LO_$server/LO_$server -igroup VPLEX2 \n\n";
system 'cat lo';
print "\n";
#print Dumper(%report);
