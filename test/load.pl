#!/usr/bin/perl

use File::Basename;
use LWP::UserAgent;
use File::Slurp;

my $gzipFile = shift;

my $extractInto = dirname($gzipFile);

print "Extracting files...";
`tar -zxvf $gzipFile -C $extractInto`;
print "finished\n";

opendir(my $extractDH, $extractInto);

my $ua = LWP::UserAgent->new;
$ua->agent("mljson test loader");

my $i = 1;
while(my $file = readdir $extractDH) {
    if($i % 100 == 0) {
        print "Loaded $i documents\n";
    }

    if($file =~ /\.json$/) {
        my $req = HTTP::Request->new(PUT => "http://localhost:8100/json/store/$file");
        my $content = read_file($extractInto . "/" . $file);
        $req->content($content);

        my $res = $ua->request($req);
        if($res->is_success) {
            unlink $extractInto . "/" . $file;
        }
        else {
            print "Error: ", $res->status_line, "\n";
        }
        $i++;
    }
    if($file =~ /\.xml$/) {
        my $req = HTTP::Request->new(PUT => "http://localhost:8100/xml/store/$file");
        my $content = read_file($extractInto . "/" . $file);
        $req->content($content);

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
