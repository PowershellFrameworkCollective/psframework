using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;

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
        public static ConcurrentDictionary<string, PsfTask> Tasks = new ConcurrentDictionary<string, PsfTask>(StringComparer.InvariantCultureIgnoreCase);

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
        /// <param name="Exclusions">List of tasks not to return, even if they are ready to execute again. This is used to avoid one misconfigured task starving all lower priority tasks, by including all tasks that have already run in a given cycle.</param>
        /// <returns>The next task to perform.</returns>
        public static PsfTask GetNextTask(string[] Exclusions)
        {
            PsfTask tempTask = null;

            foreach (PsfTask task in Tasks.Values)
                if (task.Enabled && task.IsDue && (!Exclusions.Contains(task.Name)) && ((tempTask == null) || (task.Priority > tempTask.Priority)))
                    tempTask = task;

            return tempTask;
        }

        /// <summary>
        /// Cache where modules can store cached data provided by tasks
        /// </summary>
        private static ConcurrentDictionary<string, ConcurrentDictionary<string, CacheItem>> Cache = new ConcurrentDictionary<string, ConcurrentDictionary<string, CacheItem>>(StringComparer.InvariantCultureIgnoreCase);
        
        /// <summary>
        /// Return a cache item
        /// </summary>
        /// <param name="Module">The module the cached data belongs to</param>
        /// <param name="Name">The cache entry the setting</param>
        /// <returns>The cache item storing data and potentially data gathering script.</returns>
        public static CacheItem GetCacheItem(string Module, string Name)
        {
            ConcurrentDictionary<string, CacheItem> module;
            CacheItem value;
            if (Cache.TryGetValue(Module, out module) && module.TryGetValue(Name, out value))
                return value;

            return null;
        }

        /// <summary>
        /// Creates a new cache item
        /// </summary>
        /// <param name="Module"></param>
        /// <param name="Name"></param>
        /// <returns></returns>
        public static CacheItem NewCacheItem(string Module, string Name)
        {
            lock (newCacheLock)
            {
                ConcurrentDictionary<string, CacheItem> module;
                CacheItem value;
                if (!Cache.TryGetValue(Module, out module))
                    module = Cache.GetOrAdd(Module, new ConcurrentDictionary<string, CacheItem>(StringComparer.InvariantCultureIgnoreCase));
                if (!module.TryGetValue(Name, out value))
                    value = module.GetOrAdd(Name, new CacheItem(Module, Name));

                return value;
            }
        }
        private static object newCacheLock = 24;

        /// <summary>
        /// Return whether a given cache item has been created already.
        /// </summary>
        /// <param name="Module"></param>
        /// <param name="Name"></param>
        /// <returns></returns>
        public static bool TestCacheItem(string Module, string Name)
        {
            lock (newCacheLock)
            {
                ConcurrentDictionary<string, CacheItem> module;
                CacheItem value;
                return (Cache.TryGetValue(Module, out module) && module.TryGetValue(Name, out value));
            }
        }

        /// <summary>
        /// Clears expired data in order to vacate memory.
        /// </summary>
        public static void ClearExpiredCacheData()
        {
            foreach (KeyValuePair<string, ConcurrentDictionary<string, CacheItem>> module in Cache)
                foreach (CacheItem value in module.Value.Values)
                    if (value.Expired)
                        value.Value = null;
        }
    }
}
