project('obs-measurement-overlay', 'cpp',
  version : '1.0.0',
  default_options : ['cpp_std=c++17'])

# Platform-specific configuration
if host_machine.system() == 'windows'
  plugin_suffix = '.dll'
  obs_plugin_dir = 'obs-plugins/64bit'
elif host_machine.system() == 'darwin'
  plugin_suffix = '.so'
  obs_plugin_dir = 'obs-plugins'
else
  plugin_suffix = '.so'
  obs_plugin_dir = 'obs-plugins'
endif

# Dependencies
libobs_dep = dependency('libobs', required : false)
if not libobs_dep.found()
  # Fallback for systems without pkg-config for OBS (like macOS)
  obs_include_dir = get_option('obs_include_dir')
  if obs_include_dir == ''
    obs_include_dir = run_command('printenv', 'OBS_INCLUDE_DIR', check: false).stdout().strip()
  endif
  if obs_include_dir != ''
    libobs_dep = declare_dependency(
      include_directories: include_directories(obs_include_dir)
    )
  else
    libobs_dep = declare_dependency()
  endif
endif

libopentracecapture_dep = dependency('libopentracecapture')

# Plugin sources
plugin_sources = [
  'src/measurement-overlay.cpp',
  'src/measurement-reader.cpp'
]

# Build plugin
obs_measurement_overlay = shared_module('obs-measurement-overlay',
  plugin_sources,
  dependencies : [libobs_dep, libopentracecapture_dep],
  include_directories : include_directories('../OpenTraceCapture/include'),
  name_suffix : plugin_suffix.substring(1),
  install : true,
  install_dir : get_option('libdir') / obs_plugin_dir
)
