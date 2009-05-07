use inc::Module::Install;

name 'gcal-quickadd';
all_from 'gcal-quickadd.pl';
license 'perl';

install_script 'gcal-quickadd.pl';

requires 'Net::Google::Calendar';
requires 'Mouse';
requires 'Any::Moose';
requires 'YAML';
requires 'Term::Prompt';

WriteAll;
