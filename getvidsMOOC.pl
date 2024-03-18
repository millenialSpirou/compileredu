# vim: ai:et:sw=4:ts=4

use v5.36;
use strict;
use warnings;
use feature 'say';
use LWP::Simple ();
use HTML::Parser ();
use Data::Dumper;

=for TODO
- start using parser with callback fetch
- check how SO blocks LWP::Simple::Get
- interactive recursion, tk?
- termio interface: window size aware printing

pages to parse
- MOOC cornel
- freebsd docs
- http://www.tailrecursive.org/postscript/postscript.html
- https://archive.org/details/postscriptlangua00adobrich
- https://www.w3.org/TR/WD-html40-970917/intro/sgmltut.html#h-3.1.5

=cut

sub fetch($url, $printp=0) {
    my $content = LWP::Simple::get($url) 
        or die 'unable to get page';
    if ($printp) {
        map { say } (split /\n/, $content)[0..10];
    }
    return $content
}

# my $content = fetch('http://www.perlmeme.org/tutorials/lwp.html','true');
my $mooc = fetch('https://www.cs.cornell.edu/courses/cs6120/2023fa/self-guided/',0);

my $p = HTML::Parser->new(
    api_version => 3,
    start_h => [\&estart, "self,tagname,attr,attrseq,text"],
    end_h => [ sub { shift->handler(text => undef) }, "self" ],
);

sub estart {
    my ($self, $tagname) = @_;

    sub etext {
        my ($self, $tagname, $text) = @_;
        if ($text !~ /^\s*$/g){
            say "$text";
        }
    }

    if ($tagname eq 'article') {
        $self->handler(text => \&etext, "self,tagname,dtext");
    }
}

$p->parse($mooc);

