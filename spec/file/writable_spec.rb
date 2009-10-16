require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../shared/file/writable'

describe "File.writable?" do
  before do
    @method = :writable?
    @object = File
  end

  it_should_behave_like 'file_writable'
  it_should_behave_like 'file_writable_missing'
end
