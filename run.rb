require 'shellwords'
require 'fileutils'
filename = ARGV[0]

unless File.basename(filename) =~ /.+\./
  filename = filename + '.md'
end

unless File.exists? filename
  dirname = File.dirname filename

  unless File.directory? dirname
    FileUtils.mkpath dirname
  end

  templatefile = File.join(dirname, '.template.md')

  if File.exists? templatefile
    FileUtils.cp templatefile, filename
  else
    FileUtils.touch filename
  end
end

`open #{Shellwords.escape(filename)}`
