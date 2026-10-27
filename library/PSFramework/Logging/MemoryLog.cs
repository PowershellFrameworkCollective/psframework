using PSFramework.Message;
using PSFramework.Serialization;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Logging
{
    /// <summary>
    /// Contains the log entries retained by an in-memory log provider instance.
    /// </summary>
    public class MemoryLog
    {
        #region Settings
        /// <summary>
        /// The name of the memory log
        /// </summary>
        public readonly string Name;

        /// <summary>
        /// Maximum number of messages before the oldest entries get forgotten.
        /// </summary>
        public long MaxCount;

        /// <summary>
        /// Maximum age of log entries before they get removed.
        /// </summary>
        public TimeSpan MaxAge;

        /// <summary>
        /// Should the memory log be archived when retired?
        /// Otherwise, it will be lost on retirement.
        /// </summary>
        public bool ShouldArchive;

        /// <summary>
        /// Path to where logs should be written when retired.
        /// LogEntries will be written as binary data blob and can be read in with Import-PSFClixml.
        /// </summary>
        public string ArchivePath;

        /// <summary>
        /// When the following runspace no longer exists, automatically retire this log.
        /// </summary>
        public Guid RetireWithRunspace;
        #endregion Settings

        /// <summary>
        /// Create a new in-memory log
        /// </summary>
        /// <param name="Name">Name of the log to create. Retires previous logs with this name.</param>
        public MemoryLog(string Name)
        {
            if (LogHost.InMemoryLogs.ContainsKey(Name))
            {
                // Archiving to path might fail
                try { LogHost.InMemoryLogs[Name].Retire(); }
                catch { }
            }

            this.Name = Name;
            ID = Guid.NewGuid();
            Started = DateTime.Now;
            LogHost.InMemoryLogs[Name] = this;
        }

        #region Runtime Data
        /// <summary>
        /// When the MemoryLog was started.
        /// </summary>
        public readonly DateTime Started;

        /// <summary>
        /// When the MemoryLog was closed.
        /// </summary>
        public DateTime Stopped { get; private set; }

        /// <summary>
        /// Whether the log has been archived
        /// </summary>
        public bool Archived;

        /// <summary>
        /// ID of the MemoryLog, to differentiate multiple archived logs with the same name
        /// </summary>
        public readonly Guid ID;

        /// <summary>
        /// Messages that are logged
        /// </summary>
        private Queue<LogEntry> _Messages = new Queue<LogEntry>();

        /// <summary>
        /// How many messages are in the log
        /// </summary>
        public long Count => _Messages.Count;

        /// <summary>
        /// The messages in the log
        /// </summary>
        public LogEntry[] Messages => Get();
        #endregion Runtime Data

        #region Logic / Methods
        /// <summary>
        /// Add a new log entry to the log
        /// </summary>
        /// <param name="Entry">The data to log</param>
        public void Add(LogEntry Entry)
        {
            lock (this)
            {
                _Messages.Enqueue(Entry);
                PurgeNoLock();
            }
        }

        /// <summary>
        /// Remove all invalid log entries in the Log.
        /// Not threadsafe.
        /// </summary>
        private void PurgeNoLock()
        {
            if (MaxCount > 0)
                while (_Messages.Count > MaxCount)
                    _Messages.Dequeue();
            
            if (MaxAge != null && MaxAge.TotalMilliseconds > 0)
            {
                DateTime limit = DateTime.Now.Add(MaxAge.Negate());
                while (_Messages.Peek().Timestamp < limit)
                    _Messages.Dequeue();
            }

        }

        /// <summary>
        /// Remove all invalid log entries in the Log.
        /// Threadsafe.
        /// </summary>
        public void Purge()
        {
            lock (this)
            {
                PurgeNoLock();
            }
        }

        /// <summary>
        /// Retrieve all log entries.
        /// </summary>
        /// <returns>All logged entries.</returns>
        public LogEntry[] Get()
        {
            lock (this)
            {
                return _Messages.ToArray();
            }
        }

        /// <summary>
        /// Remove all log entries from the Log
        /// </summary>
        public void Clear()
        {
            lock (this)
            {
                _Messages.Clear();
            }
        }

        /// <summary>
        /// Retire the current Log.
        /// This unlists it from the log tracker and executes all "on archive" settings.
        /// </summary>
        public void Retire()
        {
            lock (this)
            {
                Stopped = DateTime.Now;
                if (ShouldArchive)
                    LogHost.InMemoryLogsArchive[ID.ToString()] = this;
                
                Archived = true;
                MemoryLog temp;
                LogHost.InMemoryLogs.TryRemove(Name, out temp);

                if (String.IsNullOrEmpty(ArchivePath))
                    return;

                // Intentionally placed after unlisting it from storage
                // Bloated memory is considered worse than lost data
                System.IO.File.WriteAllBytes(ArchivePath, ClixmlSerializer.ToByteCompressed(Get()));
            }
        }
        #endregion Logic / Methods
    }
}
