#
# Copyright (C) 2010,2011 Red Hat, Inc.
#  Written by Ian Main <imain@redhat.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.  A copy of the GNU General Public License is
# also available at http://www.gnu.org/copyleft/gpl.html.

require 'fileutils'
require 'tempfile'

class Possible
  attr_reader :pool_family, :account, :hwp, :provider_image, :realm

  def initialize(pool_family, account, hwp, provider_image, realm)
    @pool_family = pool_family
    @account = account
    @hwp = hwp
    @provider_image = provider_image
    @realm = realm
  end
end

def pipe_and_log(pipe, instr)
  pipe.puts instr
  Rails.logger.error instr
end

def write_pw_file(job_name, pw)
  # here we write out the password file
  # FIXME: should this be configurable?
  pwdir = '/var/lib/aeolus-conductor/jobs'
  FileUtils.mkdir_p(pwdir, options={:mode => 0700})
  FileUtils.chown('aeolus', 'aeolus', pwdir)

  # Restrict job names to relatively sane characters only
  job_name.gsub!(/[^a-zA-Z0-9\.\-]/, '_')

  pwfilename = File.join(pwdir, job_name)

  tmpfile = Tempfile.new(job_name, pwdir)
  tmpfilename = tmpfile.path
  tmpfile.write(pw)
  tmpfile.close

  File.rename(tmpfilename, pwfilename)

  return pwfilename
end

def condormatic_instance_create(task)
  instance = task.instance
  matches, errors = instance.matches
  found = matches.first

  begin
    if found.nil?
      raise "Could not find a matching backend provider, errors: #{errors.join(', ')}"
    end

    job_name = "job_#{instance.name}_#{instance.id}"

    instance.condor_job_id = job_name

    overrides = HardwareProfile.generate_override_property_values(instance.hardware_profile,
                                                                  found.hwp)
    pwfilename = write_pw_file(job_name,
                               found.account.credentials_hash['password'])

    instance.provider_account = found.account
    instance.create_auth_key unless instance.instance_key
    keyname = instance.instance_key ? instance.instance_key.name : ''

    # I use the 2>&1 to get stderr and stdout together because popen3 does not
    # support the ability to get the exit value of the command in ruby 1.8.
    pipe = IO.popen("condor_submit 2>&1", "w+")
    pipe_and_log(pipe, "universe = grid\n")
    pipe_and_log(pipe, "executable = #{job_name}\n")

    pipe_and_log(pipe,
                 "grid_resource = deltacloud #{found.account.provider.encoded_url_with_driver_and_provider};\n")
    pipe_and_log(pipe, "DeltacloudUsername = #{found.account.credentials_hash['username']}\n")
    pipe_and_log(pipe, "DeltacloudPasswordFile = #{pwfilename}")
    pipe_and_log(pipe, "DeltacloudImageId = #{found.provider_image.target_identifier}\n")
    pipe_and_log(pipe,
                 "DeltacloudHardwareProfile = #{found.hwp.external_key}\n")
    pipe_and_log(pipe,
                 "DeltacloudHardwareProfileMemory = #{overrides[:memory]}\n")
    pipe_and_log(pipe,
                 "DeltacloudHardwareProfileCPU = #{overrides[:cpu]}\n")
    pipe_and_log(pipe,
                 "DeltacloudHardwareProfileStorage = #{overrides[:storage]}\n")
    pipe_and_log(pipe, "DeltacloudKeyname = #{keyname}\n")
    pipe_and_log(pipe, "DeltacloudPoolFamily = #{found.pool_family.id}\n")

    if found.realm != nil
      pipe_and_log(pipe, "DeltacloudRealmId = #{found.realm.external_key}\n")
    end

    pipe_and_log(pipe, "requirements = true\n")
    pipe_and_log(pipe, "notification = never\n")
    pipe_and_log(pipe, "queue\n")

    pipe.close_write
    out = pipe.read
    pipe.close

    Rails.logger.error "$? (return value?) is #{$?}"
    raise ("Error calling condor_submit: #{out}") if $? != 0

    task.state = Task::STATE_PENDING
    instance.state = Instance::STATE_PENDING
  rescue Exception => ex
    Rails.logger.error ex.message
    Rails.logger.error ex.backtrace.join("\n")
    task.state = Task::STATE_FAILED
    instance.state = Instance::STATE_CREATE_FAILED
    # exception is raised after ensure block
    raise ex
  ensure
    instance.save!
    task.save!
  end
end

def condormatic_instance_stop(task)
    instance =  task.instance_of?(InstanceTask) ? task.instance : task

    Rails.logger.info("calling condor_rm -constraint 'Cmd == \"#{instance.condor_job_id}\"' 2>&1")
    pipe = IO.popen("condor_rm -constraint 'Cmd == \"#{instance.condor_job_id}\"' 2>&1")
    out = pipe.read
    pipe.close

    Rails.logger.info("condor_rm return status is #{$?}")
    Rails.logger.error("Error calling condor_rm (exit code #{$?}) on job: #{out}") if $? != 0
end

def condormatic_instance_reset_error(instance)

  condormatic_instance_stop(instance)
    Rails.logger.info("calling condor_rm -forcex -constraint 'Cmd == \"#{instance.condor_job_id}\"' 2>&1")
    pipe = IO.popen("condor_rm -forcex -constraint 'Cmd == \"#{instance.condor_job_id}\"' 2>&1")
    out = pipe.read
    pipe.close

    Rails.logger.info("condor_rm return status is #{$?}")
    Rails.logger.error("Error calling condor_rm (exit code #{$?}) on job: #{out}") if $? != 0
end

def condormatic_instance_destroy(task)
    instance = task.instance

    Rails.logger.info("calling condor_rm -constraint 'Cmd == \"#{instance.condor_job_id}\"' 2>&1")
    pipe = IO.popen("condor_rm -constraint 'Cmd == \"#{instance.condor_job_id}\"' 2>&1")
    out = pipe.read
    pipe.close

    Rails.logger.info("condor_rm return status is #{$?}")
    Rails.logger.error("Error calling condor_rm (exit code #{$?}) on job: #{out}") if $? != 0
end
