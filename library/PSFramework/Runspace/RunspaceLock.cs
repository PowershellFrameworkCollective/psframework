using System;
using System.Threading;
using PSFramework.Parameter;

namespace PSFramework.Runspace
{
    /// <summary>
    /// Offers a cross-runspace locking mechanism to PowerShell
    /// </summary>
    public class RunspaceLock
    {
        /// <summary>
        /// The name of the lock.
        /// Mostly academic, used to keep track of locks across the process.
        /// </summary>
        public string Name = "<unspecified>";

        /// <summary>
        /// Who the current owner is.
        /// </summary>
        private Guid _Owner;

        /// <summary>
        /// When the lock was last taken.
        /// </summary>
        private DateTime _LockedTime;

        /// <summary>
        /// The current effective owning runspace.
        /// </summary>
        public Guid Owner
        {
            get
            {
                if (MaxLockTime > 0 && _LockedTime.AddMilliseconds(MaxLockTime) < DateTime.Now)
                    return Guid.Empty;
                return _Owner;
            }
            private set
            {
                _LockedTime = DateTime.Now;
                _Owner = value;
            }
        }

        /// <summary>
        /// The current runspace from the perspective of the caller.
        /// </summary>
        public Guid CurrentID { get => System.Management.Automation.Runspaces.Runspace.DefaultRunspace.InstanceId; }

        /// <summary>
        /// The maximum time the lock can be held. Infinite if 0 or less.
        /// </summary>
        public int MaxLockTime = 30000;

        /// <summary>
        /// The actual lock used to marshal access.
        /// </summary>
        private object Lock = 42;

        /// <summary>
        /// Creates an empty runspace lock.
        /// </summary>
        public RunspaceLock()
        {

        }

        /// <summary>
        /// Creates a named runspace lock.
        /// Names are used for multiple runspaces to access the same lock, if retrieved through the system.
        /// </summary>
        /// <param name="Name">The name to assign to the lock.</param>
        public RunspaceLock(string Name)
        {
            this.Name = Name;
        }
        /// <summary>
        /// Creates a named runspace lock with a maximum lock time.
        /// </summary>
        /// <param name="Name">The name for the runspace lock.</param>
        /// <param name="MaxLockTime">The maximum time (in ms) that the lock can be held.</param>
        public RunspaceLock(string Name, int MaxLockTime)
        {
            this.Name = Name;
            this.MaxLockTime = MaxLockTime;
        }

        /// <summary>
        /// Attempt to reserve the lock with a 30 seconds timeout.
        /// If the timeout expires, an error will be thrown.
        /// </summary>
        public void Open()
        {
            Open(new TimeSpan(0, 0, 30));
        }

        /// <summary>
        /// Attempte to reserve the lock with a specified timeout.
        /// If the timeout expires, an error will be thrown.
        /// </summary>
        /// <param name="Timeout">The timeout until we give up achieving the lock</param>
        /// <exception cref="TimeoutException">If we have to wait longer than we are willing to wait. Might happen, if some other runspace takes too long to release the lock.</exception>
        public void Open(TimeSpanParameter Timeout)
        {
            if (Owner == CurrentID)
                return;

            DateTime limit = DateTime.Now.Add(Timeout);
            bool owned = false;

            do
            {
                lock (Lock)
                {
                    if (Owner == Guid.Empty)
                    {
                        Owner = CurrentID;
                        owned = true;
                    }
                }
                if (owned)
                    break;
                if (DateTime.Now > limit)
                    throw new TimeoutException($"Failed to obtain lock '{Name}' within time limit!");
                Thread.Sleep(50);
            }
            while (!owned);
        }

        /// <summary>
        /// Release the current runspace's control over this lock.
        /// No action, if the current runspace does not control the lock.
        /// </summary>
        public void Close()
        {
            if (Owner != CurrentID)
                return;

            lock (Lock)
            {
                Owner = Guid.Empty;
            }
        }
    }
}
