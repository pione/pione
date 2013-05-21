module EM::FTPD
  class Server
    COMMANDS << "mdtm"

    # get the file's mtime
    def cmd_mdtm(param)
      send_unauthorised and return unless logged_in?
      send_param_required and return if param.nil?

      path = build_path(param)

      @driver.mtime(path) do |result|
        if result.kind_of?(Time)
          send_response result.strftime("213 %Y%m%d%H%M%S%L")
        else
          send_response "550 file not available"
        end
      end
    end
  end
end

module EM::FTPD::Files
  def puts(*args)
    # ignored
  end
end

