# Copy html5jp JavaScript codes to public/javascripts.

Dir.chdir(File.join(::Rails.root.to_s, 'vendor', 'plugins', 'html5jp_graphs')) do
  dest_dir = File.join(::Rails.root.to_s, 'public', 'javascripts')
  FileUtils.mkdirs(dest_dir) unless File.exist?(dest_dir)

  Dir.glob("html5jp/html5jp/**/*.js").each do |path|
    FileUtils.cp(path, dest_dir) unless File.exist?(File.join(dest_dir, File.basename(path)))
  end
end
