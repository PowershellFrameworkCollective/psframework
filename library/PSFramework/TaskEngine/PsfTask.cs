using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.TaskEngine
{
    /// <summary>
    /// An individual task assigned to the maintenance engine
    /// </summary>
    public class PsfTask
    {
        /// <summary>
        /// The name of the task to execute. No duplciates are possible.
        /// </summary>
        public string Name;

        /// <summary>
        /// A description of what the task is/should be doing
        /// </summary>
        public string Description;

        /// <summary>
        /// Whether the task should be done once only
        /// </summary>
        public bool Once;

        /// <summary>
        /// Whether the task is enabled. Only enabled tasks will be executed
        /// </summary>
        public bool Enabled = true;

        /// <summary>
        /// The interval at which the task should be performed
        /// </summary>
        public TimeSpan Interval = new TimeSpan(0);

        /// <summary>
        /// If the task need not be performed right away, it can be delayed, in order to prioritize more important initialization tasks
        /// </summary>
        public TimeSpan Delay = new TimeSpan(0);

        /// <summary>
        /// When was the task first registered. Duplicate registration calls will not increment this value.
        /// </summary>
        public DateTime Registered;

        /// <summary>
        /// When was the task last executed.
        /// </summary>
        public DateTime LastExecution;

        /// <summary>
        /// When is the task due next.
        /// </summary>
        public DateTime NextExecution
        {
            get
            {
                if (!Pending)
                    return DateTime.MaxValue;
                if (Registered > LastExecution)
                    return Registered.Add(Delay);
                return LastExecution.Add(Interval);
            }
        }

        /// <summary>
        /// The time the last execution took
        /// </summary>
        public TimeSpan LastDuration;

        /// <summary>
        /// How important is this task?
        /// </summary>
        public Priority Priority;

        /// <summary>
        /// The task code to execute
        /// </summary>
        public ScriptBlock ScriptBlock;

        /// <summary>
        /// Arguments to provide to the task code
        /// </summary>
        public object ArgumentList;

        /// <summary>
        /// Whether the task is due and should be executed
        /// </summary>
        public bool IsDue
        {
            get
            {
                if (Once && (LastExecution > Registered))
                    return false;

                if ((Delay.Ticks > 0) && ((Registered.Add(Delay)) > DateTime.Now))
                    return false;

                if ((LastExecution.Add(Interval)) > DateTime.Now)
                    return false;

                return true;
            }
        }

        /// <summary>
        /// Returns, whether there are any actions still pending. The Task Engine runspace will terminate if there are no pending tasks left.
        /// </summary>
        public bool Pending
        {
            get
            {
                if (!Once)
                    return true;

                if (Once && (LastExecution > Registered))
                    return false;

                return true;
            }
        }

        /// <summary>
        /// The last error the task had.
        /// </summary>
        public ErrorRecord LastError;

        /// <summary>
        /// The current state of the task.
        /// </summary>
        public TaskState State = TaskState.New;
    }
}
