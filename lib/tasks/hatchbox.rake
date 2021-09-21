# bundle exec rake hb:ssh
# bundle exec rake hb:staging
namespace :hb do
  task :ssh do
    system("ssh -t deploy@#{ENV.fetch('HATCHBOX_IP')} \"cd ~/arta/current ; bash --login\"")
  end

  task :staging do
    system("ssh -t deploy@#{ENV.fetch('HATCHBOX_IP')} \"cd ~/arta-staging/current ; bash --login\"")
  end
end
