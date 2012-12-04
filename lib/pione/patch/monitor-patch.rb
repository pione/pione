module MonitorMixin
  def mon_exit
    # check thread owner but ignore
    begin
      mon_check_owner
    rescue ThreadError => e
      $stderr.puts "Thread owner check error reported but we ignore it."
      ErrorReport.print(e)
    end
    @mon_count -=1
    if @mon_count == 0
      @mon_owner = nil
      @mon_mutex.unlock
    end
  end
end
