#!/usr/bin/perl

use File::Basename;
use LWP::UserAgent;
use File::Slurp;

my $gzipFile = shift;

my $extractInto = dirname($gzipFile);

print "Extracting json files...";
`tar -zxvf $gzipFile -C $extractInto`;
print "finished\n";

opendir(my $extractDH, $extractInto);

my $i = 1;
while(my $file = readdir $extractDH) {
    if($file =~ /\.json$/) {
        if($i % 100 == 0) {
            print "Loaded $i documents\n";
        }
        my $ua = LWP::UserAgent->new;
        $ua->agent("mljson test loader");

        my $req = HTTP::Request->new(PUT => "http://localhost:8100/data/store/$file");
        $req->content(read_file($extractInto . "/" . $file));

        my $res = $ua->request($req);
        if($res->is_success) {
            unlink $extractInto . "/" . $file;
        }
        else {
            print "Error: ", $res->status_line, "\n";
        }
        $i++;
    }
}

closedir($extractDH);
