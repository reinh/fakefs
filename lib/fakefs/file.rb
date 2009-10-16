module FakeFS
  class File
    PATH_SEPARATOR = '/'

    MODES = [
      READ_ONLY           = "r",
      READ_WRITE          = "r+",
      WRITE_ONLY          = "w",
      READ_WRITE_TRUNCATE = "w+",
      APPEND_WRITE_ONLY   = "a",
      APPEND_READ_WRITE   = "a+"
    ]

    FILE_CREATION_MODES = MODES - [READ_ONLY, READ_WRITE]

    READ_ONLY_MODES = [
      READ_ONLY
    ]

    WRITE_ONLY_MODES = [
      WRITE_ONLY,
      APPEND_WRITE_ONLY
    ]

    TRUNCATION_MODES = [
      WRITE_ONLY,
      READ_WRITE_TRUNCATE
    ]

    DEFAULT_UMASK = 022

    S_IRWXU = 00700
    S_IRUSR = 00400
    S_IWUSR = 00200
    S_IXUSR = 00100

    S_IRWXG = 00070
    S_IRGRP = 00040
    S_IWGRP = 00020
    S_IXGRP = 00010

    S_IRWXO = 00007
    S_IROTH = 00004
    S_IWOTH = 00002
    S_IXOTH = 00001

    def self.extname(path)
      RealFile.extname(path)
    end

    def self.join(*parts)
      parts * PATH_SEPARATOR
    end

    def self.exist?(path)
      !!FileSystem.find(path)
    end

    class << self
      alias_method :exists?, :exist?
    end

    def self.mtime(path)
      if exists?(path)
        FileSystem.find(path).mtime
      else
        raise Errno::ENOENT
      end
    end

    def self.size(path)
      read(path).length
    end

    def self.size?(path)
      if exists?(path) && !size(path).zero?
        true
      else
        nil
      end
    end

    def self.const_missing(name)
      RealFile.const_get(name)
    end

    def self.directory?(path)
      if path.respond_to? :entry
        path.entry.is_a? FakeDir
      else
        result = FileSystem.find(path)
        result ? result.entry.is_a?(FakeDir) : false
      end
    end

    def self.symlink?(path)
      if path.respond_to? :entry
        path.is_a? FakeSymlink
      else
        FileSystem.find(path).is_a? FakeSymlink
      end
    end

    def self.file?(path)
      if path.respond_to? :entry
        path.entry.is_a? FakeFile
      else
        result = FileSystem.find(path)
        result ? result.entry.is_a?(FakeFile) : false
      end
    end

    def self.expand_path(*args)
      RealFile.expand_path(*args)
    end

    def self.basename(*args)
      RealFile.basename(*args)
    end

    def self.dirname(path)
      RealFile.dirname(path)
    end

    def self.readlink(path)
      symlink = FileSystem.find(path)
      FileSystem.find(symlink.target).to_s
    end

    def self.open(path, mode=READ_ONLY, perm = 0644)
      if block_given?
        yield new(path, mode, perm)
      else
        new(path, mode, perm)
      end
    end

    def self.read(path)
      file = new(path)
      if file.exists?
        file.read
      else
        raise Errno::ENOENT
      end
    end

    def self.readlines(path)
      read(path).split("\n")
    end

    def self.link(source, dest)
      if directory?(source)
        raise Errno::EPERM, "Operation not permitted - #{source} or #{dest}"
      end

      if !exists?(source)
        raise Errno::ENOENT, "No such file or directory - #{source} or #{dest}"
      end

      if exists?(dest)
        raise Errno::EEXIST, "File exists - #{source} or #{dest}"
      end

      source = FileSystem.find(source)
      dest = FileSystem.add(dest, source.entry.clone)
      source.link(dest)

      0
    end

    def self.unlink(*paths)
      paths.each do |path|
        raise TypeError, "can't convert #{path.class} into String" unless path.respond_to?(:to_str)
        path = path.to_str
        raise Errno::ENOENT, "No such file or directory - #{path}" unless exists?(path)
        FileUtils.rm(path)
      end

      paths.size
    end

    class << self
      alias_method :delete, :unlink
    end

    def self.symlink(source, dest)
      FileUtils.ln_s(source, dest)
    end

    def self.stat(file)
      File::Stat.new(file)
    end

    class Stat
      def initialize(file)
        if !File.exists?(file)
          raise(Errno::ENOENT, "No such file or directory - #{file}")
        end

        @file = file
      end

      def symlink?
        File.symlink?(@file)
      end

      def directory?
        File.directory?(@file)
      end

      def nlink
        FileSystem.find(@file).links.size
      end
    end

    def self.umask(int=nil)
      old_umask = @umask ||= DEFAULT_UMASK
      @umask = int.to_int if int
      return old_umask.to_int
    end

    def self.readable?(file)
      return false unless File.exists?(file)
      File.new(file).readable?
    end

    def self.writable?(file)
      return false unless File.exists?(file)
      File.new(file).writable?
    end

    attr_reader :path

    def initialize(path, mode = READ_ONLY, perm = nil)
      @path = path
      @mode = mode
      @perm = perm
      @file = FileSystem.find(path)
      @open = true
      @stream = StringIO.new(@file.content) if @file

      check_valid_mode
      file_creation_mode? ? create_missing_file : check_file_existence!
      truncate_file if truncation_mode?
    end

    def close
      @open = false
    end

    def read(chunk = nil)
      raise IOError, 'closed stream' unless @open
      raise IOError, 'not opened for reading' if write_only?
      @stream.read(chunk)
    end

    def rewind
      @stream.rewind
    end

    def exists?
      @file
    end

    def readable?
      perm & S_IRUSR != 0 ||
      perm & S_IRGRP != 0 ||
      perm & S_IROTH != 0
    end

    def writable?
      perm & S_IWUSR != 0 ||
      perm & S_IWGRP != 0 ||
      perm & S_IWOTH != 0
    end

    def puts(*content)
      content.flatten.each do |obj|
        write(obj.to_s + "\n")
      end
    end

    def write(content)
      raise IOError, 'closed stream' unless @open
      raise IOError, 'not open for writing' if read_only?

      @file.content += content
    end
    alias_method :print, :write
    alias_method :<<, :write

    def flush; self; end

  private

    def check_file_existence!
      unless @file
        raise Errno::ENOENT, "No such file or directory - #{@file}"
      end
    end

    def check_valid_mode
      if !mode_in?(MODES)
        raise ArgumentError, "illegal access mode #{@mode}"
      end
    end

    def read_only?
      mode_in? READ_ONLY_MODES
    end

    def file_creation_mode?
      mode_in? FILE_CREATION_MODES
    end

    def write_only?
      mode_in? WRITE_ONLY_MODES
    end

    def truncation_mode?
      mode_in? TRUNCATION_MODES
    end

    def mode_in?(list)
      list.include?(@mode)
    end

    def create_missing_file
      if !File.exists?(@path)
        @file = FileSystem.add(path, FakeFile.new(nil, nil, :perm => @perm))
      end
    end

    def truncate_file
      @file.content = ""
    end

    def perm
      @perm ||= @file.perm
    end
  end
end
