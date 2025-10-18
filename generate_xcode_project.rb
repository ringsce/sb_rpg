#!/usr/bin/env ruby
# Valkyrie Xcode Project Generator using xcodeproj gem
# Install: gem install xcodeproj
# Usage: ruby generate_xcode_project.rb

require 'xcodeproj'

PROJECT_NAME = 'Valkyrie'
BUNDLE_ID = 'com.valkyrie.game'

# Source files
SOURCE_FILES = [
  'game_utils.cpp',
  'src/ai.cpp',
  'src/api.cpp',
  'src/camera.cpp',
  'src/commands.cpp',
  'src/credits.cpp',
  'src/gamepad.cpp',
  'main.cpp',
  'srv/serverRegistration.cpp'
]

# Header files
HEADER_FILES = [
  'game_utils.h',
  'src/ai.h',
  'src/api.h',
  'src/commands.h',
  'src/gamepad.h'
]

# Resource files
RESOURCE_FILES = [
  'sys/posix/res/Valkyrie.icns'
]

def create_info_plist
  info_plist = {
    'CFBundleDevelopmentRegion' => 'en',
    'CFBundleExecutable' => '$(EXECUTABLE_NAME)',
    'CFBundleIconFile' => 'Valkyrie.icns',
    'CFBundleIdentifier' => '$(PRODUCT_BUNDLE_IDENTIFIER)',
    'CFBundleInfoDictionaryVersion' => '6.0',
    'CFBundleName' => '$(PRODUCT_NAME)',
    'CFBundlePackageType' => 'APPL',
    'CFBundleShortVersionString' => '1.0.0',
    'CFBundleVersion' => '1',
    'LSMinimumSystemVersion' => '15.0',
    'NSHighResolutionCapable' => true,
    'NSPrincipalClass' => 'NSApplication',
    'NSSupportsAutomaticGraphicsSwitching' => true
  }

  File.open('Info.plist', 'w') do |file|
    file.puts '<?xml version="1.0" encoding="UTF-8"?>'
    file.puts '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
    file.puts '<plist version="1.0">'
    file.puts '<dict>'
    info_plist.each do |key, value|
      file.puts "    <key>#{key}</key>"
      case value
      when String
        file.puts "    <string>#{value}</string>"
      when TrueClass
        file.puts "    <true/>"
      when FalseClass
        file.puts "    <false/>"
      end
    end
    file.puts '</dict>'
    file.puts '</plist>'
  end
  
  puts "✅ Created Info.plist"
end

def create_xcode_project
  puts "=" * 60
  puts "Creating Valkyrie Xcode Project"
  puts "=" * 60
  puts

  # Create new project
  project = Xcodeproj::Project.new("#{PROJECT_NAME}.xcodeproj")
  
  # Create main target
  target = project.new_target(:application, PROJECT_NAME, :osx, '15.0')
  
  # Create groups
  main_group = project.main_group
  source_group = main_group.new_group('Sources')
  src_group = source_group.new_group('src')
  srv_group = source_group.new_group('srv')
  resources_group = main_group.new_group('Resources')
  
  # Add source files
  puts "Adding source files..."
  SOURCE_FILES.each do |file_path|
    if File.exist?(file_path)
      if file_path.start_with?('src/')
        file_ref = src_group.new_file(file_path)
      elsif file_path.start_with?('srv/')
        file_ref = srv_group.new_file(file_path)
      else
        file_ref = source_group.new_file(file_path)
      end
      target.add_file_references([file_ref])
      puts "  ✓ #{file_path}"
    else
      puts "  ⚠️  #{file_path} not found"
    end
  end
  
  # Add header files
  puts "\nAdding header files..."
  HEADER_FILES.each do |file_path|
    if File.exist?(file_path)
      if file_path.start_with?('src/')
        file_ref = src_group.new_file(file_path)
      else
        file_ref = source_group.new_file(file_path)
      end
      puts "  ✓ #{file_path}"
    else
      puts "  ⚠️  #{file_path} not found"
    end
  end
  
  # Add resources
  puts "\nAdding resources..."
  RESOURCE_FILES.each do |file_path|
    if File.exist?(file_path)
      file_ref = resources_group.new_file(file_path)
      target.resources_build_phase.add_file_reference(file_ref)
      puts "  ✓ #{file_path}"
    else
      puts "  ⚠️  #{file_path} not found"
    end
  end
  
  # Add Info.plist
  if File.exist?('Info.plist')
    plist_ref = main_group.new_file('Info.plist')
    puts "  ✓ Info.plist"
  end
  
  # Configure build settings
  puts "\nConfiguring build settings..."
  
  target.build_configurations.each do |config|
    settings = config.build_settings
    
    # Common settings
    settings['PRODUCT_NAME'] = PROJECT_NAME
    settings['PRODUCT_BUNDLE_IDENTIFIER'] = BUNDLE_ID
    settings['INFOPLIST_FILE'] = 'Info.plist'
    settings['MACOSX_DEPLOYMENT_TARGET'] = '15.0'
    settings['CLANG_CXX_LANGUAGE_STANDARD'] = 'c++17'
    settings['CLANG_CXX_LIBRARY'] = 'libc++'
    settings['SDKROOT'] = 'macosx'
    
    # Search paths
    settings['HEADER_SEARCH_PATHS'] = [
      '$(inherited)',
      '/opt/homebrew/include',
      '/opt/homebrew/include/SDL2',
      '/opt/homebrew/include/SDL3',
      '/usr/local/include',
      '/usr/local/include/MoltenVK'
    ]
    
    settings['FRAMEWORK_SEARCH_PATHS'] = [
      '$(inherited)',
      '/opt/homebrew/lib',
      '/usr/local/lib',
      '/Library/Frameworks'
    ]
    
    settings['LIBRARY_SEARCH_PATHS'] = [
      '$(inherited)',
      '/opt/homebrew/lib',
      '/usr/local/lib'
    ]
    
    # Linker flags
    settings['OTHER_LDFLAGS'] = [
      '-framework', 'Metal',
      '-framework', 'MetalKit',
      '-framework', 'Foundation',
      '-framework', 'QuartzCore',
      '-lSDL2',
      '-lSDL2_image',
      '-lcurl',
      '/usr/local/lib/MoltenVK.xcframework/macos-arm64_x86_64/libMoltenVK.a'
    ]
    
    # Code signing
    settings['CODE_SIGN_IDENTITY'] = '-'
    settings['CODE_SIGN_STYLE'] = 'Automatic'
    settings['DEVELOPMENT_TEAM'] = ''
    
    # Enable modules
    settings['CLANG_ENABLE_MODULES'] = 'YES'
    settings['CLANG_ENABLE_OBJC_ARC'] = 'YES'
    
    # Architecture
    settings['ARCHS'] = '$(ARCHS_STANDARD)'
    settings['ONLY_ACTIVE_ARCH'] = config.name == 'Debug' ? 'YES' : 'NO'
    
    # Preprocessor definitions
    if config.name == 'Debug'
      settings['GCC_OPTIMIZATION_LEVEL'] = '0'
      settings['GCC_PREPROCESSOR_DEFINITIONS'] = ['DEBUG=1', 'USE_MOLTENVK=1', '$(inherited)']
      settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
    else
      settings['GCC_OPTIMIZATION_LEVEL'] = '3'
      settings['GCC_PREPROCESSOR_DEFINITIONS'] = ['USE_MOLTENVK=1', '$(inherited)']
      settings['SWIFT_OPTIMIZATION_LEVEL'] = '-O'
    end
    
    # Additional settings
    settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
    settings['COMBINE_HIDPI_IMAGES'] = 'YES'
    settings['INSTALL_PATH'] = '$(LOCAL_APPS_DIR)'
    settings['SKIP_INSTALL'] = 'NO'
    
    puts "  ✓ Configured #{config.name} settings"
  end
  
  # Add build phase for copying frameworks
  copy_frameworks_phase = target.new_copy_files_build_phase('Embed Frameworks')
  copy_frameworks_phase.dst_subfolder_spec = '10' # Frameworks folder
  
  # Add shell script build phase for signing
  shell_script_phase = target.new_shell_script_build_phase('Sign Frameworks')
  shell_script_phase.shell_script = <<~SCRIPT
    # Remove quarantine attributes
    xattr -cr "$TARGET_BUILD_DIR/$PRODUCT_NAME.app/Contents/Frameworks/" 2>/dev/null || true
    
    # Sign each framework/dylib
    for file in "$TARGET_BUILD_DIR/$PRODUCT_NAME.app/Contents/Frameworks"/*.{dylib,framework}; do
        if [ -e "$file" ]; then
            codesign --force --sign - "$file" 2>/dev/null || true
        fi
    done
  SCRIPT
  
  # Save project
  project.save
  
  puts "\n" + "=" * 60
  puts "✅ Xcode project created successfully!"
  puts "=" * 60
  puts "\nProject: #{PROJECT_NAME}.xcodeproj"
  puts "\nTo open in Xcode:"
  puts "  open #{PROJECT_NAME}.xcodeproj"
  puts "\nMake sure you have installed dependencies:"
  puts "  brew install sdl2 sdl2_image curl molten-vk"
  puts "\nBuild with: ⌘B or ⌘R to run"
  puts
end

# Main execution
begin
  unless File.exist?('main.cpp')
    puts "❌ Error: main.cpp not found"
    puts "Please run this script from the Valkyrie project root directory"
    exit 1
  end
  
  # Check if xcodeproj gem is installed
  begin
    require 'xcodeproj'
  rescue LoadError
    puts "❌ Error: xcodeproj gem not installed"
    puts "Install it with: gem install xcodeproj"
    exit 1
  end
  
  create_info_plist unless File.exist?('Info.plist')
  create_xcode_project
  
rescue => e
  puts "\n❌ Error: #{e.message}"
  puts e.backtrace.join("\n")
  exit 1
end
