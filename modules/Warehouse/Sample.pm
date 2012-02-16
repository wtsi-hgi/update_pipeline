=head1 NAME

Sample.pm   - Take in a sample name or ssid and fill in the missing data in the file metadata object

=head1 SYNOPSIS

use Warehouse::Sample;
my $file = Warehouse::Sample->new(
  file_meta_data => $filemetadata,
  _dbh => $warehouse_dbh
  );

$file->populate();

=cut

package Warehouse::Sample;
use Moose;
use Sfind::Sfind;

has 'file_meta_data'   => ( is => 'rw', isa => 'UpdatePipeline::FileMetaData', required => 1 );
has '_dbh'             => ( is => 'rw',                                        required => 1 );

sub populate
{
  my($self) = @_;
  $self->_populate_ssid_from_name;
  $self->_populate_name_from_ssid;
}

sub _populate_ssid_from_name
{
  my($self) = @_;
  if(defined($self->file_meta_data->sample_name) && ! defined($self->file_meta_data->sample_ssid)  )
  {
    my $sample_name = $self->file_meta_data->sample_name;
    my $sql = qq[select internal_id, common_name from current_samples where name = "$sample_name" limit 1;];
    my $sth = $self->_dbh->prepare($sql);
    $sth->execute;
    my @sample_warehouse_details  = $sth->fetchrow_array;
    if(@sample_warehouse_details > 0)
    {
      $self->file_meta_data->sample_ssid($sample_warehouse_details[0]);
      $self->file_meta_data->sample_common_name($sample_warehouse_details[1]) if(! defined($self->file_meta_data->sample_common_name));
    }
  }
}

sub _populate_name_from_ssid
{
  my($self) = @_;
  if(!defined($self->file_meta_data->sample_name) && defined($self->file_meta_data->sample_ssid)  )
  {
    my $sample_ssid = $self->file_meta_data->sample_ssid;
    my $sql = qq[select name, common_name from current_samples where internal_id = "$sample_ssid" limit 1;];
    my $sth = $self->_dbh->prepare($sql);
    $sth->execute;
    my @sample_warehouse_details  = $sth->fetchrow_array;
    if(@sample_warehouse_details > 0)
    {
      $self->file_meta_data->sample_name($sample_warehouse_details[0]);
      $self->file_meta_data->sample_common_name($sample_warehouse_details[1]) if(! defined($self->file_meta_data->sample_common_name));
    }
  }
}


1;