using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace PSFramework.Runspace
{
    /// <summary>
    /// Runspace managing class used by Invoke-PSFRunspace.
    /// </summary>
    public class RunspaceWrapper : IDisposable
    {
        /// <summary>
        /// The code to run in parallel
        /// </summary>
        public ScriptBlock Code;

        /// <summary>
        /// How many runspace tasks to execute in parallel
        /// </summary>
        public int ThrottleLimit = 5;

        /// <summary>
        /// What each runspace task will have available
        /// </summary>
        public InitialSessionState InitialSessionState = InitialSessionState.CreateDefault();

        /// <summary>
        /// List of tasks to execute
        /// </summary>
        public List<RunspaceTask> Tasks = new List<RunspaceTask>();

        /// <summary>
        /// Variables available to all tasks
        /// </summary>
        public Dictionary<string, SessionStateVariableEntry> Variables = new Dictionary<string, SessionStateVariableEntry>(StringComparer.InvariantCultureIgnoreCase);

        /// <summary>
        /// Whether the RunspaceWrapper is currently open for tasks
        /// </summary>
        public bool IsRunning { get; internal set; }

        internal RunspacePool Pool;

        #region Content
        /// <summary>
        /// Add a variable to the initial sessionstate
        /// </summary>
        /// <param name="Name">name of the variable</param>
        /// <param name="Value">Value of the variable</param>
        public void AddVariable(string Name, object Value)
        {
            Variables[Name] = new SessionStateVariableEntry(Name, Value, "");
        }
        /// <summary>
        /// Add multiple variables to the initial sessionstate
        /// </summary>
        /// <param name="VariableHash">Name/value map of variables to inclue</param>
        public void AddVariable(Hashtable VariableHash)
        {
            foreach (object key in VariableHash)
                Variables[key.ToString()] = new SessionStateVariableEntry(key.ToString(), VariableHash[key], "");
        }
        #endregion Content

        #region Execution
        /// <summary>
        /// Start the entire wrapper, creating a runspace pool and preparing for execution
        /// </summary>
        public void Start()
        {
            foreach (SessionStateVariableEntry value in Variables.Values)
                InitialSessionState.Variables.Add(value);
            Pool = RunspaceFactory.CreateRunspacePool(InitialSessionState);
            Pool.SetMinRunspaces(1);
            Pool.SetMaxRunspaces(ThrottleLimit);
            Pool.ApartmentState = System.Threading.ApartmentState.MTA;
            Pool.Open();

            IsRunning = true;

            if (Tasks.Count > 0)
                foreach (RunspaceTask task in Tasks)
                    task.Start();
        }

        /// <summary>
        /// Close the runspace pool, terminate everything and clean up.
        /// </summary>
        public void Stop()
        {
            IsRunning = false;
            Pool.Close();
            Pool.Dispose();
        }

        /// <summary>
        /// Make sure everything is cleaned out after the job is done
        /// </summary>
        public void Dispose()
        {
            Stop();
        }
        #endregion Execution

        #region Tasks
        /// <summary>
        /// Add a task that should be executed
        /// </summary>
        /// <param name="InputObject">The argument for which the task should be executed</param>
        public void AddTask(object InputObject)
        {
            Tasks.Add(new RunspaceTask(this, InputObject));
        }

        /// <summary>
        /// Add a list of tasks that all should be executed
        /// </summary>
        /// <param name="InputObjects">The arugments for each of which the task should be executed</param>
        public void AddTaskBulk(IEnumerable InputObjects)
        {
            if (null == InputObjects)
                return;
            foreach (object item in InputObjects)
                Tasks.Add(new RunspaceTask(this, item));
        }

        /// <summary>
        /// Wait for all task results and receive results directly into the streams of the calling command
        /// </summary>
        /// <param name="Command">The command runtime whose streams to write to</param>
        /// <param name="NoStreams">Whether additional streams should be hidden and only output shown</param>
        public void Collect(Cmdlet Command, bool NoStreams = false)
        {
            while (Tasks.Count > 0)
            {
                // Since we stream data to the calling command's streams - which may be in a pipeline - we don't want to block on a longer running task.
                // Hence we cycle through the tasks, collect what is ready and sleep on our own.
                foreach (RunspaceTask task in Tasks.ToArray().Where(t => t.IsCompleted))
                    task.Collect(Command, NoStreams);
                Thread.Sleep(50);
            }
        }

        /// <summary>
        /// Collect all tasks that already completed, and directly write the results to the streams of the calling command
        /// </summary>
        /// <param name="Command">The command runtime whose streams to write to</param>
        /// <param name="NoStreams">Whether additional streams should be hidden and only output shown</param>
        public void CollectCurrent(Cmdlet Command, bool NoStreams = false)
        {
            foreach (RunspaceTask task in Tasks.ToArray())
                task.TryCollect(Command, NoStreams);
        }

        /// <summary>
        /// Wait for all task results and return result report objects, including information on all streams of the runspace
        /// </summary>
        /// <returns>List of completion reports, including all output, warnings, errors, informational messages, etc.</returns>
        public List<RunspaceResult> CollectResult()
        {
            List<RunspaceResult> results = new List<RunspaceResult>();

            foreach (RunspaceTask task in Tasks.ToArray())
                results.Add(task.CollectResult());

            return results;
        }

        /// <summary>
        /// Retrieve result report objects for each task already completed, including information on all streams of the runspace
        /// </summary>
        /// <returns>List of completion reports, including all output, warnings, errors, informational messages, etc.</returns>
        public List<RunspaceResult> CollectCurrentResult()
        {
            List<RunspaceResult> results = new List<RunspaceResult>();

            foreach (RunspaceTask task in Tasks.ToArray().Where(t => t.IsCompleted))
                results.Add(task.CollectResult());

            return results;
        }

        /// <summary>
        /// Wait for all task results and return the output.
        /// </summary>
        /// <returns>The resulting output of all tasks</returns>
        public List<PSObject> Collect()
        {
            List<PSObject> results = new List<PSObject>();
            foreach (RunspaceTask task in Tasks.ToArray())
                foreach (PSObject item in task.Collect())
                    results.Add(item);

            return results;
        }

        /// <summary>
        /// Receive the output of all currently completed tasks
        /// </summary>
        /// <returns>The output of all currently completed tasks</returns>
        public List<PSObject> CollectCurrent()
        {
            List<PSObject> results = new List<PSObject>();
            foreach (RunspaceTask task in Tasks.ToArray().Where(t => t.IsCompleted))
                foreach (PSObject item in task.Collect())
                    results.Add(item);

            return results;
        }
        #endregion Tasks
    }
}
