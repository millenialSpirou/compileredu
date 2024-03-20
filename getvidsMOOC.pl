# vim: ai:et:sw=4:ts=4

use v5.36;
use strict;
use warnings;
use feature 'say';
use LWP::Simple ();
use HTML::Parser ();
use Data::Dumper;

=for TODO
- build ast like datastructure with info and return it
- fetch return filehandle for iterative parsing
- start using parser with callback fetch
- check how SO blocks LWP::Simple::Get
- interactive recursion, tk?
- termio interface: window size aware printing
- todo reset handlers, memorize coderef?

- perl fold pod

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

package smol {
    sub nonblanktext {
        my ($text,) = @_;
        if ($text !~ /^\s*$/g) { say "$text" }
    }
    sub squeeze { 
        my ($x,) = @_; 
        $x =~ s/\n//g; 
        $x =~ s/^\s+//g; 
        $x =~ tr/ //s; 
        return $x;
    }
}

package net {
    sub fetch($url, $printp=1, $fetch=0) {
        my $fn = 'current.html';
        my $content;
        if ($fetch) {
            my $content = LWP::Simple::get($url) or die 'unable to get page';
            open (my $fh, '>:utf8', $fn) or die "could not open file '$fn' $!";
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
}



package ev {
    sub start {
        my ($self, $tagname, $attr) = @_;
        if ($tagname eq 'article') {
            $self->handler(start => \&ev::article::start, "self,tagname,attr,attrseq,text");
            $self->handler(end => \&ev::article::end, "self,tagname,attr");
        }
    }
}

package ev::article {
    my $acc = "";
    my @vidlinks = ();

    sub start {
        my ($self,$tagname,$attr,$attrseq,$text) = @_;

        my $h1h = sub { $acc .= shift };

        my $clss = $attr->{class};
        if ($tagname eq 'a') {
            if (defined $clss && $clss =~ /video/) {
                my $l = $attr->{href};
                $l =~ s/^\s+//g;
                push @vidlinks, $l;
            }
        }
        if ($tagname eq 'h1') {
            $self->handler(text => $h1h, "dtext");
        }
    }


    sub end {
        my ($self,$tagname,$attr,$attrseq,$text) = @_;
        if ($tagname eq 'h1') {
            $self->handler(text => undef);
        }
        if ($tagname eq 'article') {
            say "* @{[smol::squeeze($acc)]}"; 

            say ":video:";
            say "- $_" for @vidlinks;
            say ":end:";

            say "";
            $acc = "";
            @vidlinks = ();
        }
    }
}


sub main {
    my $mooc = net::fetch('https://www.cs.cornell.edu/courses/cs6120/2023fa/self-guided/',0);
    my $p = HTML::Parser->new(
        api_version => 3,
        start_h => [\&ev::start, "self,tagname,attr,attrseq,text"],
    );
    $p->parse($mooc);
}

main();

