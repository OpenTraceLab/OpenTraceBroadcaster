project('obs-measurement-overlay', 'cpp',
  version : '0.1.0',
  default_options : ['cpp_std=c++17'])

# Dependencies
if host_machine.system() == 'linux'
  # Linux: Use system OBS from PPA
  libobs_found = run_command('pkg-config', '--exists', 'libobs', check: false).returncode() == 0
  if libobs_found
    libobs_dep = declare_dependency(
      include_directories: include_directories('/usr/include/obs'),
      link_args: ['-lobs']
    )
  else
    error('libobs not found. Install obs-studio from PPA.')
  endif
elif host_machine.system() == 'darwin'
  # macOS: Use Homebrew OBS
  brew_prefix = run_command('brew', '--prefix', check: false).stdout().strip()
  if brew_prefix != ''
    libobs_dep = declare_dependency(
      include_directories: include_directories(brew_prefix / 'include' / 'obs'),
      link_args: ['-L' + brew_prefix / 'lib', '-lobs']
    )
  else
    error('Homebrew not found. Install OBS via: brew install obs')
  endif
elif host_machine.system() == 'windows'
  # Windows: Use environment variable or error
  obs_include = run_command('cmd', '/c', 'echo', '%OBS_INCLUDE_DIR%', check: false).stdout().strip()
  if obs_include != '' and obs_include != '%OBS_INCLUDE_DIR%'
    libobs_dep = declare_dependency(
      include_directories: include_directories(obs_include),
      link_args: ['-lobs']
    )
  else
    error('OBS_INCLUDE_DIR not set. Set environment variable to OBS include directory.')
  endif
else
  error('Unsupported platform: ' + host_machine.system())
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
