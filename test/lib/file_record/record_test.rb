require 'test_helper'

describe FileRecord do

  before do
    # See Rakefile for directory prep and cleanup
    @dir = File.join(Dir.home, ".tempo_test_directory")
    Dir.mkdir(@dir, 0700) unless File.exists?(@dir)
  end

  describe "Record" do

      before do
        @file = File.join( @dir, "create-test.txt")
      end

      after do
        File.delete(@file) if File.exists?(@file)
      end

    describe "create" do

      it "should create a new record" do
        FileRecord::Record.create( @file, "" )
        File.exists?( @file ).must_equal true
      end

      it "should raise and error if the file exists" do
        FileRecord::Record.create( @file, "" )
        proc { FileRecord::Record.create( @file, "" ) }.must_raise ArgumentError
      end

      it "should overwrite a file with option :force" do
        File.open( @file,'w' ) do |f|
          f.puts "Now this file already exists"
        end
        FileRecord::Record.create( @file, "overwrite file", force: true )
        contents  = eval_file_as_array( @file )
        contents.must_equal ["overwrite file"]
      end
    end

    describe "recording a string" do
      it "should be able to record a string" do
        FileRecord::Record.create( @file, "a simple string" )
        contents = eval_file_as_array( @file )
        contents.must_equal ["a simple string"]
      end

      it "should be able to record a string as yaml" do
        FileRecord::Record.create( @file, "a simple string", format: 'yaml' )
        contents = eval_file_as_array( @file )
        contents.must_equal ["--- a simple string", "..."]
      end
    end

      describe "recording and array" do

      it "should be able to record a shallow array as string" do
        FileRecord::Record.create( @file, ["a","simple","array"], format: "string" )
        contents = eval_file_as_array( @file )
        contents.must_equal ["a","simple","array"]
      end

      it "should default to recording a shallow array as yaml" do
        FileRecord::Record.create( @file, ["a","simple","array"] )
        contents = eval_file_as_array( @file )
        contents.must_equal ["---", "- a", "- simple", "- array"]
      end

      it "should record a nested array as yaml" do
        FileRecord::Record.create( @file, ["a",["nested",["array"]]])
        contents = eval_file_as_array( @file )
        contents.must_equal ["---", "- a", "- - nested", "  - - array"]
      end
    end

    describe "recording a hash" do

      it "should defualt to and record a hash as yaml" do
        hash = {a: 1, b: true, c: Hash.new, d: "object", with: ['an', 'array']}
        FileRecord::Record.create( @file, hash )
        contents = eval_file_as_array( @file )
        contents.must_equal ["---", ":a: 1", ":b: true", ":c: {}", ":d: object", ":with:", "- an", "- array"]
      end
    end
  end
end