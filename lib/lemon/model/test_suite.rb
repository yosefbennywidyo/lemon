require 'lemon/model/test_case'
require 'lemon/model/snapshot'

module Lemon

  # Test Suites encapsulate a set of test cases.
  #
  class TestSuite

    # Files from which the suite is loaded.
    attr :files

    # Test cases in this suite.
    attr :testcases

    # List of concern procedures that apply suite-wide.
    #attr :when_clauses

    # List of pre-test procedures that apply suite-wide.
    attr :before

    # List of post-test procedures that apply suite-wide.
    attr :after

    # A snapshot of the system before the suite is loaded.
    # Only set if +cover+ option is true.
    #attr :canonical

    # List of files to be covered. This primarily serves
    # as a means for allowing one test to load another
    # and ensuring converage remains accurate.
    #attr :subtest

    #attr :current_file

    #def coverage
    #  @final_coveage ||= @coverage - @canonical
    #end

    #
    #attr :options

    #
    def initialize(files, options={})
      @files   = files.flatten
      @options = options

      #@subtest  = []
      @testcases = []
      @before    = {}
      @after     = {}
      #@when     = {}

      #load_helpers

      #if cover? or cover_all?
      #  @coverage  = Snapshot.new
      #  @canonical = Snapshot.capture
      #end

      #load_subtest_helpers

      # TODO: maybe use a scope to evaluate all tests?
      #@scope = Scope.new

      @dsl = DSL.new(self) #, files)

      load_files
    end

    #
    #class Scope < Module
    #  def initialize
    #    extend self
    #  end
    #end

    # Iterate through this suite's test cases.
    def each(&block)
      @testcases.each(&block)
    end

    #
    def cover?
      @options[:cover]
    end

    #
    def cover_all?
      @options[:cover_all]
    end

    # TODO: automatic helper loading ?
    #def load_helpers(*files)
    #  helpers = []
    #  filelist.each do |file|
    #    dir = File.dirname(file)
    #    hlp = Dir[File.join(dir, '{test_,}helper.rb')]
    #    helpers.concat(hlp)
    #  end
    #
    #  helpers.each do |hlp|
    #    require hlp
    #  end
    #end

    #def load_subtest_helpers
    #  helpers = []
    #  @subtest.each do |file|
    #    dir = File.dirname(file)
    #    hlp = Dir[File.join(dir, '{test_,}helper.rb')]
    #    helpers.concat(hlp)
    #  end
    #
    #  #s = Snapshot.capture
    #  helpers.each do |hlp|
    #    require hlp
    #  end
    #  #z = Snapshot.capture
    #  #d = z - s
    #  #@canonical << d
    #end

    #
    def load_files #(*files)
      #$stdout << "Load: " if cover?
      #Lemon.suite = self

      filelist.each do |file|
        load_file(file)
      end

      #if cover?
      #  $stdout << "\n"
      #  $stdout.flush
      #end

      self #return Lemon.suite
    end

    #
    def load_file(file)
      #@current_file = file
      #if cover_all?
      #  Covers(file)
      #else
        file = File.expand_path(file)
        @dsl.module_eval(File.read(file), file)
        #require(file) #load(file)
      #end
    end

    # Directories glob *.rb files.
    def filelist
      @filelist ||= (
        @files.flatten.map do |file|
          if File.directory?(file)
            Dir[File.join(file, '**', '*.rb')]
          else
            file
          end
        end.flatten.uniq
      )
    end

    # Load a helper. This method must be used when loading local
    # test support. The usual #require or #load can only be used
    # for external support libraries (such as a test mock framework).
    # This is so because suite code is not evaluated at the toplevel.
    def helper(file)
      instance_eval(File.read(file), file)
    end

    #
    #def load(file)
    #  instance_eval(File.read(file), file)
    #end

    class DSL < Module
      #
      def initialize(test_suite)
        @test_suite = test_suite
        #module_eval(&code)
      end

      # Includes at the suite level are routed to the toplevel.
      def include(*mods)
        TOPLEVEL_BINDING.eval('self').instance_eval do
          include(*mods)
        end
      end

      # Define a test case belonging to this suite.
      def Case(target_class, &block)
        raise "lemon: case target must be a class or module" unless Module === target_class
        @test_suite.testcases << TestCase.new(@test_suite, target_class, &block)
      end

      #
      alias_method :TestCase, :Case
      alias_method :testcase, :Case

      # Define a pre-test procedure to apply suite-wide.
      def Before(match=nil, &block)
        @test_suite.before[match] = block #<< Advice.new(match, &block)
      end
      alias_method :before, :Before

      # Define a post-test procedure to apply suite-wide.
      def After(match=nil, &block)
        @test_suite.after[match] = block #<< Advice.new(match, &block)
      end
      alias_method :after, :After

      # Define a concern procedure to apply suite-wide.
      #def When(match=nil, &block)
      #  @when_clauses[match] = block #<< Advice.new(match, &block)
      #end

      # TODO: need require_find() to avoid first snapshot ?
      def Covers(file)
        #if @test_suite.cover?
        #  #return if $".include?(file)
        #  s = Snapshot.capture
        #  if require(file)
        #    z = Snapshot.capture
        #    @test_suite.coverage << (z - s)
        #  end
        #else
          require file
        #end
      end

      #
      def Helper(file)
        local = File.join(File.dirname(caller[1]), file.to_str + '.rb')
        if File.exist?(local)
          @test_suite.load_file(local) #require local
        else
          require file
        end
      end

    end

  end

end
