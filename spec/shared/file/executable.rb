shared_examples_for 'file_executable' do
  before :each do
    @file1 = 'temp1.txt'
    @file2 = 'temp2.txt'

    File.new(@file1, "w", 0755) # touch
    File.new(@file2, "w") # touch
  end

  after :each do
    @file1 = nil
    @file2 = nil
  end

  it "raises an ArgumentError if not passed one argument" do
    lambda { @object.send(@method) }.should raise_error(ArgumentError)
  end

  it "raises a TypeError if not passed a String type" do
    lambda { @object.send(@method, 1)     }.should raise_error(TypeError)
    lambda { @object.send(@method, nil)   }.should raise_error(TypeError)
    lambda { @object.send(@method, false) }.should raise_error(TypeError)
  end
end

shared_examples_for 'file_executable_missing' do
  it "returns false if the file does not exist" do
    @object.send(@method, 'fake_file').should == false
  end
end
