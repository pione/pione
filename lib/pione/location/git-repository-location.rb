module Pione
  module Location
    # GitRepositoryLocation represents locations of git repository.
    class GitRepositoryLocation < BasicLocation
      location_type :git_repository

      attr_reader :tag

      def initialize(address)
        @address = address[:git].to_s
        @tag = address[:tag].to_s
        @branch = address[:branch].to_s
        @hash_id = address[:hash_id].to_s
        @address_digest = Digest::SHA1.hexdigest(@address)
      end

      # Return a new location with the option.
      def +(option)
        self.class.new({git: @address, tag: @tag, branch: @branch, hash_id: @hash_id}.merge(option))
      end

      # Return the local location of repository.
      def local
        Global.git_repository_directory + @address_digest
      end

      # Return true if the local location exists.
      def has_local?
        local.exist?
      end

      # Return a hash id string of the referrence name.
      def ref(query)
        clone_to_local unless has_local?

        # parse query
        type = query.keys.first
        name = query[type]

        # execute "git show-ref"
        out = Temppath.create.open("w+")
        process = ChildProcess.build("git", "show-ref")
        process.cwd = local.path.to_s
        process.io.stdout = out
        process.start
        process.wait

        if process.crashed?
          raise GitError.new("The command 'git clone' failed.", @address)
        end

        # find hash id
        out.rewind
        out.readlines.each do |line|
          hash_id, refname = line.split(" ")

          cond_tag = (type == :tag and "refs/tags/%s" % name == refname)
          cond_branch = (type == :branch and "refs/remotes/origin/%s" % name == refname)

          return hash_id if cond_tag or cond_branch
        end

        # the name not found
        return nil
      end

      # Return compact version hash id string.
      def compact_hash_id
        id = @hash_id if @hash_id
        id = ref(tag: @tag) if @tag
        id = ref(branch: @branch) if @branch
        id = ref(branch: "HEAD") unless id
        return short_hash_id(id)
      end

      # Export git repository by hash id.
      def export(location)
        clone_to_local unless has_local?

        hash_id = compact_hash_id

        # git archive
        path = Temppath.mkdir + "archive.zip"
        ChildProcess.build("git", "archive", "-o", path.to_s, hash_id).tap do |process|
          process.cwd = local.path
          process.start
          process.wait
          if process.crashed?
            raise GitError.new(@location, message: "'git archive' failed")
          end
        end

        # unzip
        local = Location[Temppath.mkdir]
        Util::Zip.uncompress(Location[path], local)

        # update package.yml
        info = YAML.load((local + "package.yml").read)
        info["HashID"] = hash_id
        (local + "package.yml").update(YAML.dump(info))

        # upload
        local.entries.each {|entry| entry.move(location)}
      end

      private

      # Call "git clone" from the repository into local location.
      #
      # @param path [Pathname]
      #   the path of cloned repository
      def clone_to_local
        out = Temppath.create.open("w+")

        # call git clone
        process = ChildProcess.build("git", "clone", @address, local.path.to_s)
        process.io.stdout = out
        process.start
        process.wait

        # show debug message
        out.rewind
        ErrorReport.debug("git clone: %s" % out.read, self, __FILE__, __LINE__)

        # check the process result
        if process.crashed?
          raise GitError.new(self, message: "'git clone' failed")
        end
      end

      # Return short hash id.
      def short_hash_id(hash_id)
        out = Temppath.create.open("w+")

        # git rev-parse
        process = ChildProcess.build("git", "rev-parse", "--short", hash_id)
        process.cwd = local.path.to_s
        process.io.stdout = out
        process.start
        process.wait

        # check the process result
        if process.crashed?
          raise GitError.new(self, message: "Hash ID '%s' is unknown or too short" % hash_id)
        end

        # show debug message
        out.rewind
        return out.read.chomp
      end
    end
  end
end
