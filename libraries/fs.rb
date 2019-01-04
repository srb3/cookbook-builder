module Builder
  module FsHelpers
    def wait_get_file_content(file)
      sleep 2 until ::File.file?(file)
      ::File.open(file, &:readline).chomp
    end
  end
end
