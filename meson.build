project('obs-measurement-overlay', 'cpp',
  version : '0.1.0',
  default_options : ['cpp_std=c++17'])

# Dependencies
libobs_found = run_command('pkg-config', '--exists', 'libobs', check: false).returncode() == 0
if libobs_found
  libobs_dep = declare_dependency(
    include_directories: include_directories('/usr/include/obs'),
    link_args: ['-lobs']
  )
else
  error('libobs not found. Install obs-studio from PPA.')
endif

libopentracecapture_dep = dependency('opentracecapture')

# Plugin sources
plugin_sources = [
  'src/plugin-main.cpp',
  'src/measurement-reader.cpp'
]

# Build plugin
obs_measurement_overlay = shared_module('obs-measurement-overlay',
  plugin_sources,
  dependencies : [libobs_dep, libopentracecapture_dep],
  name_suffix : 'so',
  install : true,
  install_dir : get_option('libdir') / 'obs-plugins'
)

# Install locale data
install_subdir('data/locale',
  install_dir : get_option('datadir') / 'obs' / 'obs-plugins' / 'obs-measurement-overlay'
)
