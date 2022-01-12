---
title: User-Mode Threading with Fibers
layout: default
order: 2
---


### "The fibers of all things have their tension and are strained like the strings of an instrument."
##### - Henry David Thoreau

---

# The problem
At the turn of the century, a new paradigm in CPU architecture started showing up: multiple cores on a single chip. Various limitations prevented existing designs from getting faster. The simple solution was to include more of them on a single chip!  

Application developers now find themselves with a problem: how to take advantage of the additional computing power without a large overhaul of their code bases. Threaded applications were nothing new and adding additional threads would certainly take advantage of the additional cores. The problem with simply using threads, however, is that not all thread workloads are created equally. 

Take for example a multi-threaded game engine:

- Thread 0: Main application thread
- Thread 1: User I/O from devices
- Thread 2: Rendering
- Thread 3: Network I/O
- Thread 4: Physics simulation

In this simple example, it's fair to say that threads 2 and 4 are going to be *quite* busy, while thread 1 & 3 will be a light CPU load (albeit large polling times). Another problem with this design is that we're stuck with a large granularity of job scheduling: entire systems. If the host system is capable of running more threads than your application is designed for, cores sit around doing something else than servicing your application. We need a finer grained level of job execution: _function calls_. 



**"But wait!"**, you exclaim.

 **"Why not just have a global queue of function pointers (the job queue)? Spin up a thread for each CPU core and have them rip through the job queue?"**

As long as your job system never allows for *sub-jobs*, then this simple queuing mechanism would technically work. What happens when you have a top level job that spawns, *and needs to wait for*, child jobs? With sub-jobs, the system needs to perform a [context switch](https://en.wikipedia.org/wiki/Context_switch) in order to stop execution of the current job, and start another one. 

## Context Switching
Traditionally, a context switch is discussed in terms of threading. The OS kernel has a scheduler that determines which threads run on what cores, and for how long. When the scheduler decides it's time for a thread to get swapped out, CPU registers, stack pointers, program counters, and other structures must be persisted. Additionally, the incoming thread needs to have all of its serialized state pushed into the appropriate memory location and CPU registers. Needless to say, performing this type of overhead on a job system that with a function-level granularity is prohibitive. 

# Solution: Fibers
What if we could (at the user-space level) swap out the current context *without* incurring the heavy penalty of a kernel level context switch? We can! The [fiber](https://en.wikipedia.org/wiki/Fiber_(computer_science)) programming construct provides a mechanism by which multi-execution paths can co-exist within a single thread of execution. 

**Don't be fooled into thinking this is a simple fix!**

While fibers allow us to avoid the penalty of kernel context switching, we also lose the task scheduler. The OS task scheduler performs a valuable service that we need. Looks like we're writing our own task scheduler!

Enabling fibers on a thread (done with `ConvertThreadToFiber()` on Windows) is a contract with the OS that we're about to take over all scheduling duties for code that will run on the thread. The OS could, and likely will, swap out the thread to do other things than run our application. After all, our application isn't the only thing running on the system. However, when our worker thread is running, we have control over which "virtual thread" (aka fiber) is running. 

If/when the currently executing fiber completes, the OS will terminate the thread/fiber. Fibers should NEVER return unless you want your scheduler to halt. Fibers should always yield to other fibers (`SwitchToFiber()` on Windows). 

---
***NOTE***

It's important to remember that execution of a fiber is determined by the application. The application can arbitrarily start/stop/swap-out fibers whenever it sees fit. Thinking of fibers as units of execution, rather than executors, helps when you're working with them. Fibers take over the role of threads, but fibers are certainly *NOT* threads. 

---

Each fiber contains a stack memory allocation, an entry point, and some user data that is passed into the entry point. Fibers can be run on any thread that has been converted to run fibers. That doesn't mean they HAVE to, but they can. This is an important detail that we'll cover later. 

## Fibers as Jobs
By using fibers, the application will have function-level granularity for job execution. Conceptually, fibers *are* jobs. Since our application can swap out fibers arbitrarily, that means jobs can now pend on other jobs without requiring a thread-level context switch. 


# Our Job System
With our newfound knowledge of fibers, the next ***task*** (pun intended) is to design a job scheduling system. Let's start by identifying some requirements from the **application**: 


- Single application interface to the scheduler via a globally accessible singleton
- Interface for an application to arbitrarily schedule jobs without needing to know details of the system
- Interface to wait for a previously executed job to complete before continuing with the current job


From those application requirements, we can derive some requirements for the **system**:
- Utilize all logical CPU cores - *except core 0* (we'll get into that later)
- Manage a globally accessible job queue
    - Use concurrent-safe data structures such as spinlocks, a locked queue, and locked resource pool
- Provide a top-level fiber scheduler (itself a fiber) that runs on each thread
    - Manage a pending fiber queue for jobs that are waiting (local to the scheduling fiber)


## System Components
At a high level, the system will be built using the following objects:

- Concurrent programming primitives (spin-locks, queues, pools)
- Worker Threads
- Fibers
- The Dispatcher 

## System Data Flow
Let's take a look at the job workflow through the system. The top of the diagram denotes the job and fiber pools. In the center of the diagram, the pending job queue is shown. Both of the pools as well as the pending job queue, are globally accessible and protected with spin locks. 

<hr/>
<div class="row">
    <div class="col">
        <h1 class="display-1">Step 1</h1>
        The application (running on thread 0) queues a new job using the Dispatcher. The Dispatcher will pull a free job from the pool, populate the job details (function entrypoint & user data pointer), and insert the job into the pending queue. 
    </div>

    <div class="col">
        <img src="{{"/assets/images/CPlusPlus/fibers/Hustle_Step1.svg" | relative_url }}">
    </div>
</div>
<hr/>

<div class="row">

    <div class="col">
    <h1 class="display-1">Step 2</h1>    

        Meanwhile, over on the `Worker Thread` (now running the main scheduler fiber), is sitting in a loop, waiting for a job to appear on the pending job queue. With a new job to run, the scheduler obtains a free fiber from the pool. The job is assigned to the fiber and then execution of the scheduler is yielded TO the newly obtained fiber. 

    </div>

    <div class="col">
        <img src="{{"/assets/images/CPlusPlus/fibers/Hustle_Step2.svg" | relative_url }}">
    </div>
</div>

<hr/>
<div class="row">

    <div class="col">
    <h1 class="display-1">Step 3</h1>
        The Scheduler fiber is switched out and now the Job Runner Fiber is executing on the Worker Thread. The execution loop for a Job Runner Fiber is quite simple: it runs the job entry point! OK, it's a little more complicated than that but the point is that it doesn't do much. <br/>
        <br/>
        At this point, the Scheduler Fiber is not running anywhere and is effectively suspended. It will not resume running until after the current Runner Fiber yields BACK to it. 
        
    </div>

    <div class="col">
        <img src="{{"/assets/images/CPlusPlus/fibers/Hustle_Step3.svg" | relative_url }}">
    </div>
</div>

<hr/>
<div class="row">

    <div class="col">
    <h1 class="display-1">Step 4</h1>
    Now this is where the party really gets started! <br/>
    <br/>
    What makes this system flexible is the ability for jobs to queue other jobs - and pend on their completion. In this example, the Job "J" has queued an additional job "J2". Remember that queuing a job is actually a two step process. First, a free job is pulled from the global pool of jobs. After filling in the details about the job entrypoint and user data, the job is placed onto the pending job queue. The code that is running in the Job entrypoint calls the Dispatcher in order to perform job queuing. After the job is queued, it can be waited for by asking the Dispatcher via a special function. 
    </div>

    <div class="col">
        <img src="{{"/assets/images/CPlusPlus/fibers/Hustle_Step4.svg" | relative_url }}">
    </div>
</div>

<hr/>
<div class="row">

    <div class="col">
    <h1 class="display-1">Step 5</h1>
    In this step, Job "J" has called the Dispatcher "WaitFor()" function. This enters a loop that checks the status of Job "J2"s state (looking for done). If "J2" is NOT in a finished state, the fiber yields back to the scheduler. The scheduler, as shown in the diagram, is now the fiber that is being run. It checks the status of the Job Fiber and sees that it's in a waiting state. All Job Fibers that are in a waiting state are placed onto a fiber-local queue for fibers that need to be resumed later. 
    <br/>
    <br/>
    The next loop of the scheduler is run, and the next job (J2) is executed as the current fiber.
    </div>

    <div class="col">  
        <img src="{{"/assets/images/CPlusPlus/fibers/Hustle_Step5.svg" | relative_url }}">
    </div>
</div>

<hr/>
<div class="row">

    <div class="col">
    <h1 class="display-1">Step 6</h1>
    In this step, a new Fiber Job Runner is running the entry point for job J2. Since J2 does not create or wait on any additional jobs, when the job entry point finishes, the Fiber Job Runner yields back to the Job Scheduler Fiber. <i>Remember:</i> Jobs are run inside of a Job Runner Fiber, which itself has its own run loop. This is how, and where, the scheduler fiber is yielded back to. <br/>
    <br/>
    It's important to note here that J2 <i>could</i> have been picked up by any Worker Thread/Job Scheduler. This would have been perfectly fine because the job locking mechanism is protected with an atomic spin lock. 
    </div>

    <div class="col">
        <img src="{{"/assets/images/CPlusPlus/fibers/Hustle_Step6.svg" | relative_url }}">
    </div>
</div>

<hr/>
<div class="row">

    <div class="col">
    <h1 class="display-1">Step 7</h1>
    With J2 complete, and the Job Scheduler now running again. The Job and Fiber resources are released back to their respective pools. The execution loop for the Job Scheduler is complete and will start a new loop on the next step. <br/>
    <br/>
    Spoiler alert: that Pending Fiber queue is going to get a little love on the next pass! 
    </div>

    <div class="col">
        <img src="{{"/assets/images/CPlusPlus/fibers/Hustle_Step7.svg" | relative_url }}">
    </div>
</div>

<hr/>
<div class="row">

    <div class="col">
    <h1 class="display-1">Step 8</h1>
    The scheduler starts its next processing loop in this step. It starts by walking the pending fibers queue, yielding to each one to give it a chance to check any possible job locks that they may be waiting on. The diagram illustrates Job "J" being set to the current fiber and its wait lock resuming. Since J2 has completed, and its job lock released, J will complete its entrypoint function, thus causing the job runner fiber to yield back to the scheduling fiber. 
    </div>

    <div class="col">
        <img src="{{"/assets/images/CPlusPlus/fibers/Hustle_Step8.svg" | relative_url }}">
    </div>
</div>

<hr/>
<div class="row">

    <div class="col">
    <h1 class="display-1">Step 9</h1>
    With the scheduler fiber now executing again, the fiber and job resources for J2 are released back to their respective pools. At this point, the system is back to a state of waiting for jobs to work on. <br/>
    <br/>
    Success! 
    </div>

    <div class="col">
        <img src="{{"/assets/images/CPlusPlus/fibers/Hustle_Step9.svg" | relative_url }}">
    </div>
</div>

## What's So Special About Core 0? 
As noted earlier, the job system will spin up worker threads on all available cores *except* core 0. There will undoubtedly be tasks that need to be run which will perform blocking I/O. It would be sub-optimal to have tasks like this end up in the job system. 

Why? 

Let's say there is a Scheduling Fiber that picks up a new job. Unbeknownst to the scheduler, the job is going to poll on a network socket that does not receive any data for *seconds*. If the fiber wait queue has a bunch of jobs in it - they won't get a chance to run. By not scheduling any workers (and thus jobs) on core 0, the application is free to line up threads on that core for whatever I/O bound tasks are required for the application.  The expectation is that long-running polling jobs will run on core 0, and then queue jobs into the system for data that needs processing. 

## Pending Fiber Queue
Fibers can run on any thread that has been converted to run them. That means a fiber could be started on core 1, swapped out, and then resumed on core 2. In the preceding example, the fiber's stack space should be completely restored on the new core. 

For this design, I've opted to have a fiber wait queue per scheduler instead of allowing queued fibers roam around to whatever core picks them up. Why? 

Quite simply, it was an experiment to see if it would work! The pending fiber queue is a simple `std::queue` of `Fiber` pointers. If a fiber's job is pending (waiting for another job) the job fiber yields back to the scheduling fiber, who then places the job fiber onto the wait queue. *No queue locking is required* because the queue is not accessed by any other cores! 

# Client Interface
As mentioned in the requirements section earlier, an easy-to-use API for interacting with the system is a must-have. A single class, the `Dispatcher`, will be used for all interactions with the system by application code. 

## Dispatcher Setup/Teardown
The `Dispatcher` is a singleton class, meaning there can only ever be one in existence. The sole instance of the class is accessible via the `Dispatcher::GetInstance()` method. From here on, we'll omit the `GetInstance()` reference when referring to `Dispatcher` methods, for simplicity. 

 At the start of the application, the `Dispatcher::Init()` method must be called in order to setup the system. During the call to `Init()`, resource pools will be allocated and worker threads will be started. If `Init()` returns `false`, a call `Dispatcher::GetLastError()` to find out why initialization failed. 

 At the conclusion of the application, a call to `Dispatcher::Shutdown()` will halt all threads and free previously allocated resources. 

## Job Execution

 Queuing a job is as simple as calling `Dispatcher::AddJob()`. 
 The method takes two arguments:
 - `JobEntryPoint` - The function to execute for the job.* 
 - `void *pUserData` - A pointer to data that will be passed into the `JobEntryPoint`

*`JobEntryPoint` is defined as `typedef std::function<void(void* pArg)> JobEntryPoint;`

The method returns a `JobHandle` object which can be passed into a future call to `Dispatcher::WaitForJob()`. 

## Job Polling
After a job has been queued via `Dispatcher::AddJob()`, there will be cases when the current job must wait for that "child job" to complete before it continues. For these cases, invoking `Dispatcher::WaitForJob()` with the `JobHandle` to wait on, will cause the current job to be paused until the child job completes.  

# Conclusion
Fibers provide a very interesting paradigm to build a flexible job execution system on top of. Some time and effort will be required to tune the system for particular workloads, but that is a small price to pay when compared to tuning a purely thread-based system. 

I'm excited to port over my current game engine to use this new system and take maximum advantage of the host CPU resources. 

##### A Full Demo
In case you're interested in seeing a full blown demo of this system, stop by and check out the [Hustle project](https://github.com/zimventures/Hustle). It's very much a proof-of-concept (POC) of what is discussed here. As noted above, I'll be actively working on it visa-vis the integration with my game engine. Improvements and bug fixes will be made as they're found during development.  