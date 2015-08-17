require 'facter'
Facter.add(:temp_dir) do
  setcode do
    Pathname.new(File.expand_path(Dir::tmpdir)).cleanpath.to_s
  end
end
