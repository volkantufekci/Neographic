require './tez_tester'

class TezTesterRunner
  attr_accessor :result_h

  def initialize(thread_count)
    @logger ||= Logger.new(STDOUT)
    @logger.level=Logger::DEBUG

    @thread_count = thread_count - 1
  end

  def test_threaded_partitioning
    t = TezTesterRunner.new 5
    gid = rand(1..1000)
    t.threaded_partitioning(gid, "partitioned") { |ht, gid, out_count| ht.analyze(gid, out_count) }
    t.threaded_partitioning(gid, "NONpartitioned") { |ht, gid, out_count| ht.execute_on_valid_partition(gid, out_count) }
  end

  def threaded_partitioning(gid, title_for_log)
    start = Time.now
    @result_h = {}

    0.upto(@thread_count) { |i|
      Thread.new do
        ht = TezTester.new
        out_count = 5
        @logger.debug "#{title_for_log} random gid: #{gid}"

        result = ht.filter_intermediate_paths(out_count, yield(ht, gid, out_count))
        @logger.debug "#{title_for_log} results_from_partitioned.size = #{result.size}"

        @result_h[Thread.current.inspect] = result
      end

      @logger.debug "#{title_for_log} #{i} started"
    }

    @logger.info "#{title_for_log} Waiting all threads to finish"

    #Does not come to end while debuggin becuase of the debug thread. join(seconds_to_wait) could be used.
    Thread.list.each { |t| t.join unless t == Thread.main or t == Thread.current }
    @logger.info "#{title_for_log} All threads should have been finished"

    @logger.debug "#{title_for_log} thread count: #{@result_h.size}"
    @logger.info Time.now - start
  end

end

t = TezTesterRunner.new 5
t.test_threaded_partitioning




