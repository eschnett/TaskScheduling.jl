module TaskScheduling

using Base.Threads

type Scheduler
    tasks::Vector{Any}
    mutex::Mutex
    nbusy::Atomic{Int}
    terminate::Atomic{Int}
    Scheduler() = new(Any[], Mutex(), Atomic{Int}(), Atomic{Int}())
end
const scheduler = Scheduler()

export submit
function submit(task)
    lock!(scheduler.mutex)
    push!(scheduler.tasks, task)
    unlock!(scheduler.mutex)
end

function gettask()
    # get lock
    lock!(scheduler.mutex)
    # get next task, if any
    task = nothing
    if !isempty(scheduler.tasks)
        # get task
        task = pop!(scheduler.tasks)
        atomic_add!(scheduler.nbusy, 1)
    else
        # check for termination
        if scheduler.nbusy[] == 0
            scheduler.terminate[] = 1
        end
    end
    # release lock
    unlock!(scheduler.mutex)
    task
end

export runtasks
function runtasks()
    scheduler.nbusy[] = 0
    scheduler.terminate[] = 0
    @threads for i in 1:nthreads()
        while scheduler.terminate[] == 0
            # get next task
            task = gettask()
            # run the task
            if task !== nothing
                task()
                atomic_sub!(scheduler.nbusy, 1)
            end
        end
    end
end

end
