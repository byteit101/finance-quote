#!/usr/bin/perl -w
#
#    Copyright (C) 1998, Dj Padzensky <djpadz@padz.net>
#    Copyright (C) 1998, 1999 Linas Vepstas <linas@linas.org>
#    Copyright (C) 2000, Yannick LE NY <y-le-ny@ifrance.com>
#    Copyright (C) 2000, Paul Fenwick <pjf@Acpan.org>
#    Copyright (C) 2000, Brent Neal <brentn@users.sourceforge.net>
#    Copyright (C) 2000, Volker Stuerzl <volker.stuerzl@gmx.de>
#    Copyright (C) 2002, Rainer Dorsch <rainer.dorsch@informatik.uni-stuttgart.de>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
#    02111-1307, USA
#
#
# This code derived from Padzensky's work on package Finance::YahooQuote,
# but extends its capabilites to encompas a greater number of data sources.
#
# This code was developed as part of GnuCash <http://www.gnucash.org/>
#
# Known problems:
# - Date is not yet working. It is definied as first entry in the last line.
#
# $Id: Union.pm,v 1.1 2002/06/25 03:12:59 pjf Exp $

package Finance::Quote::Union;
require 5.005;

use strict;
use LWP::UserAgent;
use HTTP::Request::Common;

use vars qw/$VERSION/;

$VERSION = '1.00';

sub methods { return (unionfunds => \&unionfunds); }
sub labels { return (unionfunds => [qw/exchange name date price method/]); }

# =======================================================================
# The unionfunds routine gets quotes of UNION funds (Union Invest)
# On their website UNION provides a csv file in the format
#    label1,label2,...
#    name1,symbol1,buy1,bid1,...
#    name2,symbol2,buy2,bid2,...
#    ...
#
# This subroutine was written by Volker Stuerzl <volker.stuerzl@gmx.de>

sub unionfunds
{
  my $quoter = shift;
  my @funds = @_;
  return unless @funds;
  my $ua = $quoter->user_agent;
  my (%fundhash, @q, @date, %info,$tempdate);

  # create hash of all funds requested
  foreach my $fund (@funds)
  {
    $fundhash{$fund} = 0;
  }

  # get csv data
  my $response = $ua->request(GET &unionurl);
  if ($response->is_success)
  {
    # retrive date
    foreach (split('\015?\012',$response->content))
    {
      @q = split(/,/) or next;
      $tempdate=$q[0];
    }
    # convert date from german (dd.mm.yyyy) to US format (mm/dd/yyyy)
    @date = split /\./, $tempdate;
    $tempdate = $date[1]."/".$date[0]."/".$date[2];

    # process csv data
    foreach (split('\015?\012',$response->content))
    {
#      @q = $quoter->parse_csv($_) or next;
      @q = split(/,/) or next;
      if (exists $fundhash{$q[1]})
      {
        $fundhash{$q[1]} = 1;


        $info{$q[1], "exchange"} = "UNION";
        $info{$q[1], "name"}     = $q[1];
        $info{$q[1], "symbol"}   = $q[1];
        $info{$q[1], "price"}    = $q[3];
        $info{$q[1], "last"}     = $q[3];
        $info{$q[1], "date"}     = $tempdate;
        $info{$q[1], "method"}   = "unionfunds";
        $info{$q[1], "currency"} = "EUR";
        $info{$q[1], "success"}  = 1;
      }
    }

    # check to make sure a value was returned for every fund requested
    foreach my $fund (keys %fundhash)
    {
      if ($fundhash{$fund} == 0)
      {
        $info{$fund, "success"}  = 0;
        $info{$fund, "errormsg"} = "No data returned";
      }
    }
  }
  else
  {
    foreach my $fund (@funds)
    {
      $info{$fund, "success"}  = 0;
      $info{$fund, "errormsg"} = "HTTP error";
    }
  }

  return wantarray() ? %info : \%info;
}

# UNION provides a csv file named preise.csv containing the prices of all
# their funds for the most recent business day.

sub unionurl
{
  return "http://www.union-invest.de/preise.csv";
}

1;

=head1 NAME

Finance::Quote::UNION	- Obtain quotes from UNION (Zurich Financial Services Group).

=head1 SYNOPSIS

    use Finance::Quote;

    $q = Finance::Quote->new;

    %stockinfo = $q->fetch("unionfunds","847402");

=head1 DESCRIPTION

This module obtains information about UNION managed funds.

Information returned by this module is governed by UNION's terms
and conditions.

=head1 LABELS RETURNED

The following labels may be returned by Finance::Quote::UNION:
exchange, name, date, price, last.

=head1 SEE ALSO

UNION (Union Invest), http://www.union-invest.de/

=cut



