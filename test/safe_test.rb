$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'fakefs/safe'
require 'test/unit'

class FakeFSSafeTest < Test::Unit::TestCase
  def setup
    FakeFS.deactivate!
  end

  def test_FakeFS_method_does_not_intrude_on_global_namespace
    path = '/path/to/file.txt'

    FakeFS do
      File.open(path, 'w') { |f| f.write "Yatta!" }
      assert File.exists?(path)
    end

    assert ! File.exists?(path)
  end

  def test_FakeFS_method_returns_value_of_yield
    result = FakeFS do
      File.open('myfile.txt', 'w') { |f| f.write "Yatta!" }
      File.read('myfile.txt')
    end

    assert_equal result, "Yatta!"
  end
end
