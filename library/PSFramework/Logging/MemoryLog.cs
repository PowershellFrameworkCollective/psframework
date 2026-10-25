using PSFramework.Message;
using PSFramework.Serialization;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Logging
{
    public class MemoryLog
    {
        #region Settings
        public readonly string Name;

        public long MaxCount;

        public TimeSpan MaxAge;

        public bool ShouldArchive;

        public string ArchivePath;

        public Guid RetireWithRunspace;
        #endregion Settings

        public MemoryLog(string Name)
        {
            if (LogHost.InMemoryLogs.ContainsKey(Name))
                LogHost.InMemoryLogs[Name].Retire();

            this.Name = Name;
            ID = Guid.NewGuid();
            Started = DateTime.Now;
            LogHost.InMemoryLogs[Name] = this;
        }

        #region Runtime Data
        public readonly DateTime Started;

        public DateTime Stopped { get; private set; }

        public bool Archived;

        public readonly Guid ID;

        private Queue<LogEntry> _Messages = new Queue<LogEntry>();
        #endregion Runtime Data

        #region Logic / Methods
        public void Add(LogEntry Entry)
        {
            lock (this)
            {
                _Messages.Enqueue(Entry);
                PurgeNoLock();
            }
        }

        private void PurgeNoLock()
        {
            if (MaxCount > 0)
                while (_Messages.Count > MaxCount)
                    _Messages.Dequeue();
            
            if (MaxAge != null)
            {
                DateTime limit = DateTime.Now.Add(MaxAge.Negate());
                while (_Messages.Peek().Timestamp < limit)
                    _Messages.Dequeue();
            }

        }

        public void Purge()
        {
            lock (this)
            {
                PurgeNoLock();
            }
        }

        public LogEntry[] Get()
        {
            lock (this)
            {
                return _Messages.ToArray();
            }
        }

        public void Clear()
        {
            lock (this)
            {
                _Messages.Clear();
            }
        }

        public void Retire()
        {
            lock (this)
            {
                Stopped = DateTime.Now;
                if (ShouldArchive)
                    LogHost.InMemoryLogsArchive[ID.ToString()] = this;
                if (!String.IsNullOrEmpty(ArchivePath))
                    System.IO.File.WriteAllBytes(ArchivePath, ClixmlSerializer.ToByteCompressed(Get()));

                Archived = true;
                MemoryLog temp;
                LogHost.InMemoryLogs.TryRemove(Name, out temp);
            }
        }
        #endregion Logic / Methods
    }
}
