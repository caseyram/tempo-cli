require "test_helper"

describe Tempo do

  before do
    # See Rakefile for directory prep and cleanup
    @dir = File.join( Dir.home,"tempo" )
    Dir.mkdir(@dir, 0700) unless File.exists?(@dir)
  end

  after do
    FileUtils.rm_r(@dir) if File.exists?(@dir)
  end

  describe "Model::TimeRecord" do

    it "has project as an accessible attribute" do
      time_record_factory
      has_attr_accessor?( @record_1, :description ).must_equal true
    end

    it "defaults to the current project" do
      project_factory
      Tempo::Model::TimeRecord.clear_all
      @record_1 = Tempo::Model::TimeRecord.new({ description: "day 1 pet the sheep",
                                                 start_time: Time.new(2014, 1, 1, 7 ) })
      @record_1.project.must_equal Tempo::Model::Project.current.id
    end

    it "has an accessible description" do
      time_record_factory
      has_attr_accessor?( @record_1, :description ).must_equal true
    end

    it "has a readable end time" do
      time_record_factory
      has_attr_reader?( @record_1, :end_time ).must_equal true
    end

    it "has readable tags" do
      time_record_factory
      has_attr_read_only?( @record_1, :tags ).must_equal true
    end

    it "is taggable with an array of tags" do
      time_record_factory
      @record_2.tag(["fungi", "breakfast"])
      @record_2.tags.must_equal(["breakfast", "fungi"])
    end

    it "is untaggable with an array of tags" do
      time_record_factory
      @record_3.untag( ["horticulture"] )
      @record_3.tags.must_equal(["trees"])
    end

    it "has a current project getter" do
      time_record_factory
      Tempo::Model::TimeRecord.current.must_equal @record_6
      @record_6.end_time.must_equal :running
    end

    it "closes current when adding an end time to current" do
      time_record_factory
      @record_6.end_time = Time.new(2014, 1, 2, 19, 00 )
      Tempo::Model::TimeRecord.current.must_equal nil
    end

    it "has a running? method" do
      time_record_factory
      @record_1.running?.must_equal false
      @record_6.running?.must_equal true
    end

    it "has a duration method returning seconds" do
      time_record_factory
      @record_1.duration.must_equal 1800
      @record_6.duration.must_be_kind_of Integer
    end

    it "closes out the last current project on new" do
      time_record_factory
      @record_1.end_time.must_equal @record_2.start_time
      @record_2.end_time.must_equal @record_3.start_time

      @record_4.end_time.must_equal @record_5.start_time
      @record_5.end_time.must_equal @record_6.start_time
    end

    it "closes projects on the start day" do
      time_record_factory
      @record_3.end_time.must_equal Time.new(2014,1,1,23,59)
    end

    it "closes out new projects if not the most recent" do
      project_factory
      Tempo::Model::TimeRecord.clear_all
      @record_2 = Tempo::Model::TimeRecord.new({ project: @project_2, description: "day 1 drinking coffee, check on the mushrooms", start_time: Time.new(2014, 1, 1, 7, 30 ) })
      @record_1 = Tempo::Model::TimeRecord.new({ project: @project_1, description: "day 1 pet the sheep", start_time: Time.new(2014, 1, 1, 7 ) })
      Tempo::Model::TimeRecord.current.must_equal @record_2
      @record_1.end_time.must_equal @record_2.start_time
    end

    it "closes out all projects when init with an end time" do
      project_factory
      Tempo::Model::TimeRecord.clear_all
      @record_1 = Tempo::Model::TimeRecord.new({ project: @project_2, description: "day 1 drinking coffee, check on the mushrooms", start_time: Time.new(2014, 1, 1, 7, 30 ) })
      @record_2 = Tempo::Model::TimeRecord.new({ project: @project_1, description: "day 1 pet the sheep", start_time: Time.new(2014, 1, 1, 8 ), end_time: Time.new(2014, 1, 1, 10 ) })
      @record_1.end_time.must_equal @record_2.start_time
      Tempo::Model::TimeRecord.current.must_equal nil
    end

    it "errors when start time inside existing record" do
      time_record_factory
      proc { Tempo::Model::TimeRecord.new({ start_time: Time.new(2014, 1, 1, 12 ) }) }.must_raise ArgumentError
    end

    it "errors when start time same as existing record" do
      time_record_factory
      proc { Tempo::Model::TimeRecord.new({ start_time: @record_1.start_time }) }.must_raise ArgumentError
    end

    it "errors when end time is before start time" do
      Tempo::Model::TimeRecord.clear_all
      proc { Tempo::Model::TimeRecord.new({ start_time: Time.new(2014, 1, 1, 12 ), end_time: Time.new(2014, 1, 1, 10 ) }) }.must_raise ArgumentError
    end

    it "accepts and end time equal to start time" do
      Tempo::Model::TimeRecord.clear_all
      record = Tempo::Model::TimeRecord.new({ start_time: Time.new(2014, 1, 1, 12 ), end_time: Time.new(2014, 1, 1, 12 ) })
      record.end_time.must_equal record.start_time
    end

    it "end time can equal a previous start time" do
      Tempo::Model::TimeRecord.clear_all
      r1 = Tempo::Model::TimeRecord.new({ start_time: Time.new(2014, 1, 1, 10 ), end_time: Time.new(2014, 1, 1, 12 ) })
      r2 = Tempo::Model::TimeRecord.new({ start_time: Time.new(2014, 1, 1, 8 ), end_time: Time.new(2014, 1, 1, 10 ) })
      r1.start_time.must_equal r2.end_time
    end

    it "errors when end time is on a different day" do
      Tempo::Model::TimeRecord.clear_all
      proc { Tempo::Model::TimeRecord.new({ start_time: Time.new(2014, 1, 1, 10 ), end_time: Time.new(2014, 1, 2, 12 ) }) }.must_raise ArgumentError
    end

    it "errors when end time in existing record" do
      Tempo::Model::TimeRecord.clear_all
      r1 = Tempo::Model::TimeRecord.new({ start_time: Time.new(2014, 1, 1, 10 ), end_time: Time.new(2014, 1, 1, 12 ) })
      proc { Tempo::Model::TimeRecord.new({ start_time: Time.new(2014, 1, 1, 8 ), end_time: Time.new(2014, 1, 1, 11 ) }) }.must_raise ArgumentError
    end

    it "errors when record spans an existing record" do
      Tempo::Model::TimeRecord.clear_all
      r1 = Tempo::Model::TimeRecord.new({ start_time: Time.new(2014, 1, 1, 10 ), end_time: Time.new(2014, 1, 1, 11 ) })
      proc { Tempo::Model::TimeRecord.new({ start_time: Time.new(2014, 1, 1, 8 ), end_time: Time.new(2014, 1, 1, 12 ) }) }.must_raise ArgumentError
    end

    it "errors when record spans a running record" do
      Tempo::Model::TimeRecord.clear_all
      r1 = Tempo::Model::TimeRecord.new({ start_time: Time.new(2014, 1, 1, 10 ) })
      proc { Tempo::Model::TimeRecord.new({ start_time: Time.new(2014, 1, 1, 8 ), end_time: Time.new(2014, 1, 1, 12 ) }) }.must_raise ArgumentError
    end

    it "has a valid start time check for existing record" do
      time_record_factory
      @record_2.valid_start_time?(@record_2.start_time).must_equal true
      @record_2.valid_start_time?(@record_1.start_time).must_equal false
    end

    it "has a valid end time check for existing record" do
      time_record_factory
      @record_2.valid_end_time?(@record_2.end_time).must_equal true
      @record_2.valid_end_time?(@record_3.end_time).must_equal false
    end

    it "comes with freeze dry for free" do
      Tempo::Model::TimeRecord.clear_all
      time_record_factory
      @record_3.freeze_dry.must_equal({ :start_time=>Time.new(2014,1,1,17,30), :id=>3, :project=>3,
                                        :end_time=>Time.new(2014,1,1,23,59), :description=>"day 1 water the bonsai",
                                        :tags=>["horticulture", "trees"], :project_title=>"horticulture - backyard bonsai"})
    end

    it "saves to file a collection of projects" do
      time_record_factory
      Tempo::Model::TimeRecord.save_to_file
      test_file_1 = File.join(ENV['HOME'],'tempo/tempo_time_records/20140101.yaml')
      test_file_2 = File.join(ENV['HOME'],'tempo/tempo_time_records/20140102.yaml')
      contents = eval_file_as_array( test_file_1 )
      contents.must_equal [ "---", ":project_title: sheep herding", ":description: day 1 pet the sheep",
                            ":start_time: 2014-01-01 07:00:00.000000000 -05:00", ":end_time: 2014-01-01 07:30:00.000000000 -05:00",
                            ":id: 1", ":project: 1", ":tags: []",
                            "---", ":project_title: horticulture - basement mushrooms", ":description: day 1 drinking coffee, check on the mushrooms",
                            ":start_time: 2014-01-01 07:30:00.000000000 -05:00", ":end_time: 2014-01-01 17:30:00.000000000 -05:00",
                            ":id: 2", ":project: 2", ":tags: []",
                            "---", ":project_title: horticulture - backyard bonsai", ":description: day 1 water the bonsai",
                            ":start_time: 2014-01-01 17:30:00.000000000 -05:00", ":end_time: 2014-01-01 23:59:00.000000000 -05:00",
                            ":id: 3", ":project: 3", ":tags:", "- horticulture", "- trees"]
      contents = eval_file_as_array( test_file_2 )
      # TODO: test this one too when stable
      contents.must_equal ["---", ":project_title: sheep herding", ":description: day 2 pet the sheep",
                           ":start_time: 2014-01-02 07:15:00.000000000 -05:00", ":end_time: 2014-01-02 07:45:00.000000000 -05:00",
                           ":id: 1", ":project: 1", ":tags: []",
                           "---", ":project_title: horticulture - basement mushrooms", ":description: day 2 drinking coffee, check on the mushrooms",
                           ":start_time: 2014-01-02 07:45:00.000000000 -05:00", ":end_time: 2014-01-02 17:00:00.000000000 -05:00",
                           ":id: 2", ":project: 2", ":tags: []",
                           "---", ":project_title: horticulture - backyard bonsai", ":description: day 2 water the bonsai",
                           ":start_time: 2014-01-02 17:00:00.000000000 -05:00", ":end_time: :running",
                           ":id: 3", ":project: 3", ":tags: []"]
    end
  end
end
