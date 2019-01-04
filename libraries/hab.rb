#
# Chef Documentation
# https://docs.chef.io/libraries.html
#

module Builder
  module HabHelpers
    def hab_pkg_path(pkg)
      shell_out!("hab pkg path #{pkg}").stdout.chomp
    end
    def builder_populated?
      false
    end
    # TODO:
    # not sure how this will react if the svc is
    # reported in the output but in the down state
    # I guess it would return true and thats probably
    # fine - also we are loading with --force so this 
    # is not really needed
    def hab_svc_running?(svc)
      begin
        shell_out!("hab svc status #{svc}").stdout
      rescue
        puts "svc #{svc} not running"
        return false
      end
      puts "svc #{svc} is running"
      true
    end
  end
end
