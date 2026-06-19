# rails generate run_once NAME
#
# Generates a timestamped run_once rake task, just like a db migration:
#
# rails generate run_once upgrade_to_effective_cpd_seven
#   => db/run_once/20260227230301_upgrade_to_effective_cpd_seven.rake

class RunOnceGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  desc 'Creates a timestamped run_once rake task in db/run_once/'

  def create_run_once_task
    timestamp = Time.now.utc.strftime('%Y%m%d%H%M%S')
    template 'run_once_task.rake.tt', File.join('db', 'run_once', "#{timestamp}_#{file_name}.rake")
  end
end
