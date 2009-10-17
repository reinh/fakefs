require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../shared/file/executable'

describe "File.executable?" do
  before do
    @method = :executable?
    @object = File
  end
  it_should_behave_like "file_executable"
  it_should_behave_like "file_executable_missing"
end
