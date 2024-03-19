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

=for toread
https://www.perl.com/article/untangling-subroutine-attributes/
https://metacpan.org/release/DCONWAY/Smart-Comments-1.000005/view/lib/Smart/Comments.pm
=cut

sub fetch($url, $printp=1, $fetch=0) {
    # =for optimization
    # return filehandle 
    # =cut
    my $fn = 'current.html';
    my $content;
    if ($fetch) {
        my $content = LWP::Simple::get($url) or die 'unable to get page';
        #todo specify utf8
        open (my $fh, '>', $fn) or die "could not open file '$fn' $!";
        print $fh $content;
        close $fh;
    }
    else {
        open (my $fh, '<:utf8', $fn) or die "could not open file '$fn' $!";
        {
            local $/;
            $content = <$fh>;
        }
        close $fh;
    }
    if ($printp) { 
        map { say } (split /\n/, $content)[0..10] 
    }
    return $content;

}



package ev {
    sub text {
        my ($text,) = @_;
        if ($text !~ /^\s*$/g) { say "$text" }
    }

    package article {
        # todo reset handlers, memorize coderef?
        sub start {
            my ($self,$tagname,$attr) = @_;
            my $clss = $attr->{class};
            if ($tagname eq 'a') {
                if (defined $clss && $clss =~ /video/) {
                    say "video: $attr->{href}";
                }
            }
            $self->handler(text => \&text, "text");
        }
    }

    sub start {
        my ($self, $tagname, $attr) = @_;
        if ($tagname eq 'article') {
            $self->handler(start => \&article::start, "self,tagname,attr");
        }
    }

}

sub main {
    my $mooc = fetch('https://www.cs.cornell.edu/courses/cs6120/2023fa/self-guided/');
    # my $p = HTML::Parser->new(
    #     api_version => 3,
    #     start_h => [\&ev::article::start, "self,tagname,attr,attrseq,text"],
    # );
    # $p->parse($mooc);
}

main();

