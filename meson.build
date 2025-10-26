project('obs-measurement-overlay', 'cpp',
  version : '0.1.0',
  default_options : ['cpp_std=c++17'])

# Auto-detect version from git tags (latest by date)
git_version_cmd = run_command('git', 'describe', '--tags', '--abbrev=0', check: false)
git_version_from_tag = git_version_cmd.returncode() == 0 ? git_version_cmd.stdout().strip() : ''

# Version handling - priority: git tag > project version
if git_version_from_tag != ''
  # Remove 'v' prefix if present
  obs_version_raw = git_version_from_tag.startswith('v') ? git_version_from_tag.substring(1) : git_version_from_tag
  # Strip pre-release suffix (e.g., "0.1.0-alpha.3" -> "0.1.0")
  obs_version = obs_version_raw.contains('-') ? obs_version_raw.split('-')[0] : obs_version_raw
else
  obs_version = meson.project_version()
endif

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
# libobs pkg-config adds C-only flags (-std=gnu17), so we manually construct the dependency
libobs_found = run_command('pkg-config', '--exists', 'libobs', check: false).returncode() == 0
if libobs_found
  libobs_dep = declare_dependency(
    include_directories: include_directories('/usr/include/obs'),
    link_args: ['-lobs']
  )
else
  obs_include_dir = get_option('obs_include_dir')
  if obs_include_dir == ''
    obs_include_dir = run_command('printenv', 'OBS_INCLUDE_DIR', check: false).stdout().strip()
  endif
  if obs_include_dir != ''
    libobs_dep = declare_dependency(
      include_directories: include_directories(obs_include_dir),
      link_args: ['-lobs']
    )
  else
    error('libobs not found. Install obs-studio or set obs_include_dir option.')
  endif
endif

libopentracecapture_dep = dependency('opentracecapture')

# Plugin sources
plugin_sources = [
  'src/measurement-overlay.cpp',
  'src/measurement-reader.cpp'
]

# Build plugin
obs_measurement_overlay = shared_module('obs-measurement-overlay',
  plugin_sources,
  dependencies : [libobs_dep, libopentracecapture_dep],
  name_suffix : plugin_suffix.substring(1),
  install : true,
  install_dir : get_option('libdir') / obs_plugin_dir
)
