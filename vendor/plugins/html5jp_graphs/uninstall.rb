# Delete html5jp JavaScript codes from public/javascripts.
files = ["circle.js", "excanvas.js", "excanvas-compressed.js", "line.js", "radar.js", "vbar.js"]

Dir.chdir(File.join(::Rails.root.to_s, 'public', 'javascripts')) do
  files.each do |f|
    File.delete(f) if File.exist?(f)
  end
end