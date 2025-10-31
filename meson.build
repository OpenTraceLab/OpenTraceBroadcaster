project('obs-measurement-overlay', ['c', 'cpp'],
  version: '0.1.0',
  default_options: ['c_std=c11', 'cpp_std=c++17', 'warning_level=2'])

# Import filesystem module
fs = import('fs')

# Get version from buildspec.json
if fs.exists('buildspec.json')
  buildspec_content = run_command('cat', 'buildspec.json', check: true)
  # Use project version as fallback
  project_version = meson.project_version()
else
  project_version = meson.project_version()
endif

# Platform detection
host_system = host_machine.system()
is_windows = host_system == 'windows'
is_macos = host_system == 'darwin'
is_linux = host_system == 'linux'

# Compiler setup
cc = meson.get_compiler('c')
cpp = meson.get_compiler('cpp')

# Dependencies
deps = []

# Find OBS Studio
if is_linux
  # Override libobs to avoid conflicting compiler flags
  deps += declare_dependency(
    compile_args: ['-DHAVE_OBSCONFIG_H'],
    link_args: ['-lobs'],
    include_directories: include_directories('/usr/include/obs')
  )
else
  # Use OBS build system on Windows/macOS
  libobs_dep = dependency('libobs', required: true)
  deps += libobs_dep
endif

# Find OpenTraceCapture - use direct linking if pkg-config fails
opentracecapture_dep = dependency('opentracecapture', required: false)
if not opentracecapture_dep.found()
  opentracecapture_lib = cc.find_library('opentracecapture', dirs: ['/usr/local/lib', '/usr/local/lib/x86_64-linux-gnu'])
  opentracecapture_inc = include_directories('/usr/local/include')
  opentracecapture_dep = declare_dependency(dependencies: opentracecapture_lib, include_directories: opentracecapture_inc)
endif
deps += opentracecapture_dep

# Platform-specific dependencies
if is_windows
  deps += cc.find_library('ws2_32', required: true)
  deps += cc.find_library('setupapi', required: true)
  deps += cc.find_library('advapi32', required: true)
  deps += cc.find_library('user32', required: true)
  deps += cc.find_library('kernel32', required: true)
endif

# Compiler flags
compile_args = []
link_args = []

if is_windows and cc.get_id() == 'msvc'
  compile_args += [
    '/DWIN32_LEAN_AND_MEAN',
    '/DNOMINMAX',
    '/D_CRT_SECURE_NO_WARNINGS',
    '/D_WIN32_WINNT=0x0601',
    '/DWINVER=0x0601',
    '/MP'  # Parallel compilation
  ]
elif is_macos
  compile_args += [
    '-Wno-quoted-include-in-framework-header',
    '-Wno-comma'
  ]
endif

# Source files
sources = files(
  'src/plugin-main.cpp',
  'src/measurement-reader.cpp',
  'src/measurement-overlay.cpp'
)

# Create shared library (OBS plugin)
plugin = shared_library('obs-measurement-overlay',
  sources,
  dependencies: deps,
  c_args: compile_args,
  cpp_args: compile_args,
  link_args: link_args,
  name_prefix: '',
  install: true,
  install_dir: get_option('libdir') / 'obs-plugins'
)

# Install data files
if fs.is_dir('data')
  install_subdir('data', 
    install_dir: get_option('datadir') / 'obs' / 'obs-plugins' / 'obs-measurement-overlay')
endif

# Summary
summary({
  'Version': project_version,
  'Platform': host_system,
  'Compiler': cc.get_id(),
  'Install prefix': get_option('prefix'),
  'Plugin dir': get_option('libdir') / 'obs-plugins',
  'Data dir': get_option('datadir') / 'obs' / 'obs-plugins' / 'obs-measurement-overlay'
}, section: 'Configuration')
