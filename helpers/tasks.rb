helpers do
  def assignTasksToJob(tasks, job_id)
  custom_job_id=0
    tasks.each do |task_id|
      taskname = Tasks.first(id: task_id)[:name]
      if taskname.start_with?('ANP MASK')
        custom_job_id = task_id
        customtasks = Tasks.all(:name.like => "%#{taskname[8..-1]}%")
        customtasks.each do |custom_id|
          puts "ANP CUSTOM TASK test - #{custom_id.id} #{custom_job_id}"
          next if custom_id.id.to_i == custom_job_id.to_i 
          puts "ANP CUSTOM TASK test2 - #{custom_id.id} #{custom_job_id}"
          jobtask = Jobtasks.new
          jobtask.job_id = job_id
          jobtask.task_id = custom_id.id
          jobtask.save
        end
      else
        jobtask = Jobtasks.new
        jobtask.job_id = job_id
        jobtask.task_id = task_id
        jobtask.save
      end
    end
  end
end
