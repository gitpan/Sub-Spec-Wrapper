
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Module::Build' => '0.3601'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Wrap subroutine to its implement Sub::Spec clauses',
  'dist_author' => [
    'Steven Haryanto <stevenharyanto@gmail.com>'
  ],
  'dist_name' => 'Sub-Spec-Wrapper',
  'dist_version' => '0.03',
  'license' => 'perl',
  'module_name' => 'Sub::Spec::Wrapper',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Data::Dump::OneLine' => '0',
    'Log::Any' => '0',
    'Sub::Spec' => '1.0.1',
    'Test::More' => '0.96',
    'perl' => '5.010000'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
