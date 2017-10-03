using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.TaskEngine
{
    /// <summary>
    /// Host class providing access to resources needed to schedule and execute tasks in the background
    /// </summary>
    public static class TaskHost
    {
        /// <summary>
        /// The register of available tasks.
        /// </summary>
        public static Dictionary<string, PsfTask> Tasks = new Dictionary<string, PsfTask>();

        /// <summary>
        /// Whether there are any due tasks
        /// </summary>
        public static bool HasDueTasks
        {
            get
            {
                foreach (PsfTask task in Tasks.Values)
                    if (task.Enabled && task.IsDue)
                        return true;

                return false;
            }
        }

        /// <summary>
        /// Whether there are any tasks that still have an action pending
        /// </summary>
        public static bool HasPendingTasks
        {
            get
            {
                foreach (PsfTask task in Tasks.Values)
                    if (task.Enabled && task.Pending)
                        return true;

                return false;
            }
        }

        /// <summary>
        /// Returns the next task to perform. Returns null when there are no more tasks to perform
        /// </summary>
        /// <param name="Exclusions">List of tasks not to return, even if they are ready to execute again. This avoids one misconfigured task starving all lower priority tasks</param>
        /// <returns>The next task to perform.</returns>
        public static PsfTask GetNextTask(string[] Exclusions)
        {
            PsfTask tempTask = null;

            foreach (PsfTask task in Tasks.Values)
                if (task.Enabled && task.IsDue && (!Exclusions.Contains(task.Name)) && ((tempTask == null) || (task.Priority > tempTask.Priority)))
                    tempTask = task;

            return tempTask;
        }
    }
}
