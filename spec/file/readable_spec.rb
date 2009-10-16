require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../shared/file/readable'

describe "File.readable?" do
  before do
    @method = :readable?
    @object = File
  end

  it_should_behave_like 'file_readable'
  it_should_behave_like 'file_readable_missing'
end
