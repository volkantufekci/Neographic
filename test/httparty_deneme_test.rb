require_relative '../httparty_deneme'

class HttpartyDenemeTest
  attr_accessor :result_h

  def initialize(thread_count)
    @logger ||= Logger.new(STDOUT)
    @logger.level=Logger::INFO

    @result_h = {}
    @thread_count = thread_count - 1
  end

  def test_partitioned
    start = Time.now
    @result_h = {}

    0.upto(@thread_count) { |i|
      Thread.new do
        ht = HttpartyDeneme.new
        out_count = 5
        gid = rand(1..1000)
        @logger.debug "#{__method__.to_s} random gid: #{gid}"

        results_from_partitioned = ht.filter_intermediate_paths(out_count, ht.analyze(gid, out_count))
        @logger.debug "#{__method__.to_s} results_from_partitioned.size = #{results_from_partitioned.size}"

        @result_h[Thread.current.inspect] = results_from_partitioned
      end

      @logger.debug "#{__method__.to_s} #{i} started"
    }

    @logger.info "Waiting all threads to finish"
    Thread.list.each { |t| t.join unless t == Thread.main or t == Thread.current }
    @logger.info "All threads should have been finished"

    @logger.debug "#{__method__.to_s} thread count: #{@result_h.size}"
    @logger.info Time.now - start
  end

  def test_nonpartitioned
    start = Time.now
    @result_h = {}

    0.upto(@thread_count) { |i|
      Thread.new do
        ht = HttpartyDeneme.new
        out_count = 5
        gid = rand(1..1000)
        puts "random gid: #{gid}"

        results_from_nonpartitioned = ht.filter_intermediate_paths(out_count, ht.execute_on_valid_partition(gid, out_count))
        puts "results_from_nonpartitioned.size = #{results_from_nonpartitioned.size}"

        @result_h[Thread.current.inspect] = results_from_nonpartitioned
      end

      puts "#{i} started"
    }

    @logger.info "Waiting all threads to finish"
    Thread.list.each { |t| t.join unless t == Thread.main or t == Thread.current }
    @logger.info "All threads should have been finished"

    @logger.debug "#{__method__.to_s} thread count: #{@result_h.size}"
    @logger.info Time.now - start
  end
end

#t = HttpartyDenemeTest.new 0
#t.test_threads

