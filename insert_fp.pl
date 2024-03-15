#!/usr/bin/perl -w

use strict;
use Getopt::Std;

use vars qw( $opt_d $opt_f $opt_m $opt_v $filename $invoked $fingerprint $m_title $m_artist $m_album $i_title $i_artist $i_album );

getopts("d:f:m:v") or die "Usage: $0 -d database -f filename -m media -v\n";
( $opt_d && $opt_f ) or die "Usage: $0 -d database -f filename -m media -v\n";

(-e "$opt_f") or die "$0 : file \"$opt_f\" not found.\n";
(-e "$opt_d") or die "$0 : database \"$opt_d\" not found.\n";
($opt_m) or die "$0 : no media designation used.\n";

print STDERR "$0 : $opt_f\n";

# which sqlite3
# which fpcalc
# which mp3info
# which id3v2

my $fp = `fpcalc -length 120 -chunk 120 -rate 32767 -channels 2 -raw -signed -algorithm 3 "$opt_f"`;
chomp $fp;
my @f = split(/\n/,$fp);
(! $opt_v) || print STDERR "parts : ",scalar(@f), "\n";
(! $opt_v) || print STDERR substr($fp, 0, 75) , "\n";

my $mpi = `mp3info -p "%a\t%l\t%t\n" "$opt_f"`;
chomp $mpi;
my @m = split(/\t/,$mpi);
if ($#m == 2) { (! $opt_v) || print "m_artist : $m[0]\nm_album : $m[1]\nm_title : $m[2]\n"; }
# else { print STDERR "too few mp3info fields\n"; }
if ($mpi =~ /^$/) { @m = ('','',''); }

my $idi = `mid3v2 -l "$opt_f" | grep -e '^TALB' -e '^TIT' -e '^TPE1' | sort`;
chomp $idi;
my @i = split(/\n/,$idi);
if ($#i == 2) { (! $opt_v) || print "i_album : ", substr($i[0],5), "\ni_title : ", substr($i[1],5), "\ni_artist : ", substr($i[2],5), "\n"; $i[0] = substr($i[0],5); $i[1] = substr($i[1],5); $i[2] = substr($i[2],5) ; }
# else { print STDERR "too few mid3v2 fields\n"; }
if ($idi =~ /^$/) { @i = ('','',''); }

my @fn=split(/\//,$opt_f);
$filename = $fn[$#fn] ; 
$filename =~ s/\'/\'\'/g ;
$invoked = 'fpcalc -length 120 -chunk 120 -rate 32767 -channels 2 -raw -signed -algorithm 3';
$fingerprint = $fp ; 
if (defined $m[0]) { $m_artist =$m[0]; } else {$m_artist = '';} 
if (defined $m[1]) { $m_album =$m[1]; } else  {$m_album = '';} 
if (defined $m[2]) { $m_title =$m[2]; } else  {$m_title = '';} 
if (defined $i[0]) { $i_album =$i[0]; } else {$i_album = '';} 
if (defined $i[1]) { $i_title =$i[1]; } else  {$i_title = '';} 
if (defined $i[2]) { $i_artist =$i[2]; } else  {$i_artist = '';} 
$m_artist =~ s/\'/\'\'/g ;
$i_artist =~ s/\'/\'\'/g ;
$m_album =~ s/\'/\'\'/g ;
$i_album =~ s/\'/\'\'/g ;
$m_title =~ s/\'/\'\'/g ;
$i_title =~ s/\'/\'\'/g ;

my $fullpath = $opt_f;
my $media = $opt_m;
my $bytes = -s "$opt_f" ;
my $sha = `shasum "$opt_f"`;
$sha = lc(substr($sha,0,40));
$fullpath =~ s/\'/\'\'/g ;
$media =~ s/\'/\'\'/g ;

# print STDERR "sqlite3 \"$opt_d\" \"INSERT INTO metadata (filename ,invoked ,fingerprint ,m_title ,m_artist ,m_album ,i_title ,i_artist ,i_album) VALUES ('$filename','$invoked','$fingerprint','$m_title','$m_artist','$m_album','$i_title','$i_artist','$i_album');\" \n";
my $ret;
$ret = `sqlite3 "$opt_d" "INSERT INTO storage (fullpath ,bytes ,sha, media ) VALUES ('$fullpath',$bytes,'$sha','$media');"`; 
my $sid = `sqlite3 "$opt_d" "SELECT storage_id from storage WHERE fullpath = '$fullpath' and sha = '$sha' and media = '$media';"`;
# print STDERR "sid $sid\n";
chomp $sid;
$ret = `sqlite3 "$opt_d" "INSERT INTO metadata (storage_id ,invoked ,fingerprint ,m_title ,m_artist ,m_album ,i_title ,i_artist ,i_album) VALUES ($sid,'$invoked','$fingerprint','$m_title','$m_artist','$m_album','$i_title','$i_artist','$i_album');"`; 
(! $opt_v) || print STDERR "database call returned : $ret";


exit;
__END__

which fpcalc
/usr/local/bin/fpcalc

fpcalc -version
fpcalc version 1.5.1 (FFmpeg Lavc58.134.100 Lavf58.76.100 SwR3.9.100)

fpcalc -length 120 -chunk 120 -rate 32767 -channels 2 -raw -signed -algorithm 3 FILENAME
DURATION=319
FINGERPRINT=3666666,-46666666,5666666,...

mp3info -p "%a\t%l\t%t\n" FILENAME

mid3v2 -l Nice\ To\ Be\ Out\ \[NbitkjHw0qM\].mp3
TALB=Just Enough Education to Perform
TIT2=Nice to Be Out
TPE1=Stereophonics

mid3v2 -l Nice\ To\ Be\ Out\ \[NbitkjHw0qM\].mp3 | grep -e '^TALB' -e '^TIT' -e '^TPE1' | sort
TALB=Just Enough Education to Perform
TIT2=Nice to Be Out
TPE1=Stereophonics


